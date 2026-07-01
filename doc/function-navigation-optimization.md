# 函数跳转优化方案

## 当前实现

### 整体架构

`[f` 跳上一个函数（或在函数体内时回到当前函数签名），`]f` 跳下一个函数。光标精确落在**函数名**上而非 `func` 关键字。

三个核心函数：

**`collect_function_nodes(bufnr)`** — 递归遍历 treesitter 语法树，收集所有 `function_declaration` 和 `method_declaration` 节点，返回按源码顺序排列的列表。

**`get_function_name(func_node)`** — 通过 treesitter 的 `field("name")` 获取函数名子节点，返回其 (row, col)。若节点没有 name field 则回退到 func_node 自身 start。

**`cursor_on_node_name(func_node, row, col)`** — 判断光标是否落在函数名的字符范围内，用于区分"在函数体内"和"已在函数名上"。

### `[f` 决策流程

```
光标在函数体内 && 不在函数名上 → 跳到当前函数名（回到签名）
         ↓ 否
找 end_row ≤ 当前行中 end_row 最大的 → 跳到上一个函数名
```

`]f` 流程对称：找 start_row > 当前行中 start_row 最小的。

### 为什么用递归遍历而不用 query

初版使用了 `vim.treesitter.query`:

```lua
vim.treesitter.query.parse("go", "((function_declaration) @fn) ((method_declaration) @fn)")
```

在实际运行中遇到两个问题：

1. **节点类型兼容性**：尝试加入 `function_definition` 时在 Go parser 直接报 `Invalid node type`，不同语言的节点类型不能混用。
2. **`iter_matches` 多 pattern 返回值不稳定**：当 query 包含多个 pattern 时，`iter_matches` 的 match 结构变得复杂，部分迭代器返回的对象上 `end_()` 为 nil。

换成递归遍历语法树后，完全绕开了 query parser 的兼容性问题，且对几百行的 Go 文件耗时在 0.1~0.5ms，完全无感。

### `LspAttach` 时机选择

键位映射必须用 `LspAttach` autocmd + buffer-local keymap，不能在顶层用 `vim.keymap.set`:

1. LazyVim 的 treesitter-textobjects 在 treesitter attach 时注册 buffer-local `[f`，优先级高于全局 keymap（`verbose nmap [f` 中带 `@` 标记即为 buffer-local）
2. FileType autocmd 触发也早于 treesitter attach，同样被覆盖
3. `LspAttach` 在 LSP + treesitter 都就绪后触发，此时再设 buffer-local keymap 即可覆盖 textobjects 的绑定

## 开发过程踩过的坑

### 坑一：`vim.tbl_flatten({opts})` 与 `vim.keymap.set` 不兼容

早期想复用 opts 变量这样写：

```lua
local opts = { noremap = true, silent = true, buffer = args.buf }
vim.keymap.set("n", "[f", fn, { desc = "...", unpack = vim.tbl_flatten({ opts }) })
```

报错 `invalid key: unpack`。`vim.keymap.set` 的 opts 不接受 `unpack` 字段，必须将 key-value 逐一内联传入。

### 坑二：Go treesitter 没有 `function_definition` 节点

Go parser 的函数节点类型是 `function_declaration` 和 `method_declaration`，`function_definition` 是 JS/Python 等语言的概念。query 中包含不存在的节点类型会导致 `_ts_parse_query` 直接抛异常。

### 坑三：`node:end_()` 返回 nil

`iter_matches` 多 pattern 模式下，部分 match 项的 node 缺少 `end_()` 方法。根本原因是 match 结构中嵌套了一层，需要 `match[id]` 取到的才是真正的 TSNode。跳过 query 改用递归遍历彻底规避了这个问题。

### 坑四：`field("name")` vs `iter_children()` 获取函数名

最早用 `iter_children()` 找第一个 named + type == "identifier" 的子节点，这在 Go 中不可靠——`func` 关键字后的第一个 identifier 不一定是函数名（可能有 receiver `(r *Repo)`）。改用 `field("name")` 直接取 name field 才精确。

### 坑五：buffer-local keymap 的覆盖顺序

```
全局 keymap  →  被 buffer-local 覆盖
FileType autocmd buffer-local  →  被 treesitter attach 覆盖
LspAttach autocmd buffer-local  →  覆盖以上所有（最终生效）
```

关键：Neovim 中后设置的 buffer-local mapping 覆盖先设置的，`LspAttach` 触发最晚，所以能稳定生效。

## 优化方案

### 方案一：兄弟节点导航

Go 的 `function_declaration` / `method_declaration` 是 `source_file` 的直接子节点，互为兄弟。

思路：

1. 从光标处获取当前 treesitter 节点
2. 向上走到 `source_file` 的下一层（兄弟层）
3. 用 `node:prev_named_sibling()` / `node:next_named_sibling()` 向前/向后遍历
4. 跳过非函数类型的兄弟节点，命中即停止

复杂度：O(depth + sibling_scan)，远小于 O(all_nodes)。

优点：无需遍历整棵树，命中即停，实现简洁。
缺点：仅适用函数是顶层兄弟的语言（Go、Rust），对 JS/TS/Python 等函数可任意嵌套的语言无效。

```lua
-- 伪代码
local node = vim.treesitter.get_node()
while node and node:type() ~= "source_file" do
  node = node:parent()
end
-- 在 source_file 的子节点中找兄弟函数节点
local sibling = vim.treesitter.get_node():prev_named_sibling()
while sibling do
  if fn_types[sibling:type()] then return sibling end
  sibling = sibling:prev_named_sibling()
end
```

### 方案二：缓存

思路：

1. 首次 `collect_function_nodes` 后把结果存入 `vim.b[bufnr]._fn_nodes`
2. 后续按键直接读缓存，O(1)
3. 监听 `BufModifiedSet` / `on_changedtree` 事件，变更后清除缓存

优点：最通用，所有语言适用，改造成本低。
缺点：引入缓存失效逻辑，增加状态管理复杂度。

```lua
-- 伪代码
vim.api.nvim_create_autocmd("BufModifiedSet", {
  pattern = "*",
  callback = function(args)
    vim.b[args.buf]._fn_nodes = nil
  end,
})
```

### 方案三：向上收敛搜索

思路：从光标处获取 treesitter 节点，一路 `parent()` 向上查找函数节点。

优点：实现最简单，无需遍历。
缺点：只能找到"当前/包围函数"，无法找到"上一个不相关的函数"（treesitter 没有提供跨兄弟节点的前驱查询 API），因此只能解决"跳到函数签名"的需求，不足以替代 `collect_function_nodes` 的全部用途。

类似早期 `goto_enclosing_function_start` 的实现。

## 选型建议

| 场景 | 推荐方案 |
|------|---------|
| 当前使用场景（Go，文件 < 2000 行） | 保持现状，遍历即可 |
| 单文件数万行 | 方案二（缓存），普适且低成本 |
| 仅 Go/Rust 项目 | 方案一（兄弟导航），最优雅 |
| 只需"跳到当前函数签名" | 方案三，一行 `parent()` 循环 |

## 性能验证

在 `[f` 前后插桩可验证当前方案的实际耗时：

```lua
local start = vim.loop.hrtime()
-- ... collect_function_nodes ...
local elapsed = (vim.loop.hrtime() - start) / 1e6 -- ms
vim.notify(string.format("collect took %.3fms", elapsed))
```
