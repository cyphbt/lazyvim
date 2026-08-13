# Avante 使用指南

## 概述

[Avante](https://github.com/yetone/avante.nvim) 是 Neovim 的 AI 辅助插件，类似 Cursor AI IDE 的体验。当前主要使用 **Claude Code** 作为后端（通过 ACP 协议），同时保留了 Codex（OpenAI）作为备用。

## 键位参考

| 按键 | 功能 |
|------|------|
| `<leader>aa` | 打开 Avante 侧边栏并聚焦输入框（自动进入插入模式） |
| `<leader>at` | 切换（打开/关闭）Avante 侧边栏 |
| `<leader>ai` | 如果侧边栏已打开则聚焦输入框，否则打开侧边栏 |
| `<leader>ap` | 弹出 Provider 选择菜单 |
| `<leader>ac` | 一键切换到 Claude Code |
| `<leader>ax` | 一键切换到 Codex (OpenAI) |

## Provider 配置

### Claude Code（主用）

- **command**: `claude-agent-acp`（通过 Homebrew 安装的独立二进制）
- **协议**: ACP（Agent Communication Protocol）
- **权限模式**: `bypassPermissions`（跳过确认弹窗，全自动执行）
- **API**: 使用 `ANTHROPIC_BASE_URL` 指向中转 API

配置文件：[lua/plugins/avante.lua](../lua/plugins/avante.lua)

### Codex（备用）

- **command**: `codex-acp`
- **API**: 使用 `OPENAI_API_KEY`

## 文件自动刷新

### 问题背景

Avante/Claude Code 通过 ACP 协议写入文件时，已打开的 Neovim 缓冲区不会自动同步。光标在 Avante 侧边栏时，`CursorHold` 事件无法触发文件窗口的 `checktime`，导致文件变更不可见。

### 解决方案

在 [lua/config/options.lua](../lua/config/options.lua) 中配置了三层机制：

1. **`autoread`** — 全局启用外部修改检测
2. **`FileChangedShell` autocmd** — 拦截"文件已变更，是否重载？"弹窗，本地无未保存修改时自动 `:e!`
3. **全局 timer 扫描** — 每 200ms 遍历所有 buffer 执行 `checktime`，不依赖光标位置或窗口焦点

```lua
-- options.lua 相关片段
vim.o.updatetime = 100
vim.opt.autoread = true

vim.api.nvim_create_autocmd("FileChangedShell", {
  pattern = "*",
  callback = function()
    if vim.bo.modified == false then
      vim.cmd("e!")
    end
  end,
})

local function check_all_buffers()
  for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_valid(bufnr)
      and vim.bo[bufnr].buftype == ""
      and not vim.bo[bufnr].modified
    then
      vim.api.nvim_buf_call(bufnr, function() vim.cmd("checktime") end)
    end
  end
end

vim.defer_fn(function()
  local timer = vim.uv.new_timer()
  if timer then
    timer:start(0, 200, vim.schedule_wrap(check_all_buffers))
  end
end, 0)
```

### 安全保护

- 只对 `buftype == ""` 的普通文件 buffer 生效
- 只对 `modified == false`（无本地未保存修改）的 buffer 自动刷新
- `FileChangedShell` 弹窗被自动处理，不会打断工作流

## Diff 审查（采纳/拒绝）

resu.nvim 通过文件监控检测 Claude Code 写入的变更，自动弹出 diffview 让你逐个审查。

配置：[lua/plugins/resu.lua](../lua/plugins/resu.lua)

| 按键 | 功能 |
|------|------|
| `<leader>rt` | 打开/关闭 resu 审查面板 |
| `<leader>ra` | 接受当前文件的改动 |
| `<leader>rd` | 拒绝当前文件的改动（`git checkout` 恢复） |
| `<leader>rA` | 全部接受 |
| `<leader>rD` | 全部拒绝 |
| `<leader>rr` | 刷新面板 |
| `q` | 退出审查面板 |
