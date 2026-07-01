# 输入法自动切换（Insert Mode Auto-Switch）

## 概述

在 Neovim 中进入 Insert 模式时自动切换到上次使用的输入法（如中文拼音），退出 Insert 模式时自动切回英文输入法。这样在 Vim 中写 Go 代码和写注释时不再需要手动切换输入法。

## 依赖

一个 CLI 工具 `im-select`，可从机器上的实际安装位置引用：

- **macOS**：`brew install im-select`
- 或从 GitHub 下载：[daipeihust/im-select](https://github.com/daipeihust/im-select)

`im-select` 没有参数时返回当前输入法的 ID（如 `com.apple.keylayout.ABC` 表示英文，`com.apple.inputmethod.SCIM.ITABC` 表示拼音）。

## 实现

### 核心状态机

```
                    InsertEnter
  (英文输入法) ──────────────────→ (上次的输入法)
       ↑                              │
       │                              │ 用户打字（可能是中文）
       │                              │
       │          InsertLeave         │
       └──────────────────────────────┘
             切回英文 + 记录当前输入法
```

### 三个 Autocmd 的职责

| 事件 | 行为 |
|------|------|
| `InsertEnter` | 切换到 `last_input`（上次离开 Insert 时的输入法） |
| `InsertLeave` | 记录当前输入法到 `last_input`，然后切到英文 |
| `VimLeave` | 退出 Neovim 时恢复 `last_input`，避免输入法残留在英文状态 |

### 代码

```lua
local english_input = "com.apple.keylayout.ABC"
local last_input = english_input

local function get_current_input()
  local result = vim.fn.system("im-select")
  return vim.trim(result)
end

local function switch_input(input)
  if input and input ~= "" then
    vim.fn.system({ "im-select", input })
  end
end

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    switch_input(last_input)
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    last_input = get_current_input()
    switch_input(english_input)
  end,
})

vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    switch_input(last_input)
  end,
})
```

## 设计决策

### 为什么用 `last_input` 记忆而非写死中文

不同用户可能用不同输入法（拼音、五笔、双拼、日文输入法等），甚至同一用户在不同场景可能切换。记忆用户最后一次离开 Insert 时的输入法，比写死一个中文输入法 ID 更灵活。

初始值设为 `english_input` 是为了安全——如果用户启动 Neovim 后第一次进入 Insert 时还没切过输入法，至少不会切到一个无效状态。

### 为什么 InsertLeave 先记录再切换

`system("im-select")` 获取的是切换前那一刻的输入法——即用户在 Insert 模式中实际使用的输入法。如果先切英文再获取，拿到的永远是 `ABC`，`last_input` 就失去了意义。

必须 **先获取 → 再切换**，保证记录的是用户真实使用的输入法。

### 为什么用 VimLeave 恢复

Neovim 退出后，用户回到终端或其他应用。如果此时输入法还是英文，用户可能需要手动切回去。`VimLeave` 把状态恢复到进入 Neovim 之前的样子，用户体验更连贯。

### 为什么用表格式调用 `system({ "im-select", input })`

`vim.fn.system` 有两种形式：

- `system("im-select ABC")` — 字符串拼接，如果 `input` 包含空格或特殊字符会有注入风险
- `system({ "im-select", input })` — 表格式，直接传递参数，不经过 shell 解析

表格式更安全，也是推荐的用法。

### 时间复杂度

每次模式切换调用一次 `im-select`，这是一个极轻量的 C 程序调用，获取或切换输入法在微秒级完成。三个 autocmd 的 callback 都是同步完成，对 Neovim 的响应延迟可忽略。

## 与 LazyVim 的关系

LazyVim 默认没有输入法自动切换功能，这是独立添加的自定义配置。

`require("config.im-select")` 在 `autocmds.lua` 中被调用，而 `autocmds.lua` 由 LazyVim 的 `VeryLazy` 事件加载——即在插件和配置基本就绪后才执行，不会影响启动时间。

## 局限

- 仅 macOS。Linux/Windows 用户需要使用不同的输入法 CLI 工具（如 `fcitx5-remote` 或 `ibus`），并调整 `english_input` 的值为目标平台的英文输入法 ID
- 依赖于 `im-select` 在 PATH 中可用
- `system()` 调用是同步的，在极少数情况下如果 `im-select` 卡住（如 macOS 输入法进程异常），会短暂阻塞 Neovim 界面
