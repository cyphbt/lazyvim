-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.swapfile = false -- 禁用 swap 文件，避免多实例同时打开同一文件时的 W325 警告
vim.opt.relativenumber = false -- 关闭相对行号，只显示绝对行号

vim.opt.tabstop = 4 -- 显示时，一个 tab = 4 列
vim.opt.shiftwidth = 4 -- 缩进操作（>>、<<、自动缩进）使用 4 空格
vim.opt.expandtab = true -- 将 tab 转为空格（推荐）
vim.opt.softtabstop = 4 -- 在插入模式下按 Backspace 时，一次删除 4 空格
vim.opt.scrolloff = 0 -- 关闭视口提前跟随，恢复更原生的滚动体感
vim.opt.smoothscroll = false -- 关闭 LazyVim 默认启用的平滑滚动
vim.o.updatetime = 100
vim.opt.autoread = true

-- 外部变更时自动重载，不弹窗确认
vim.api.nvim_create_autocmd("FileChangedShell", {
  pattern = "*",
  callback = function()
    if vim.bo.modified == false then
      vim.cmd("e!")
    end
  end,
})

-- 对所有 buffer 周期性检查外部变更（即使当前不在该 buffer 上也生效）
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

-- 每 200ms 全局扫描一次
vim.defer_fn(function()
  local timer = vim.uv.new_timer()
  if timer then
    timer:start(0, 200, vim.schedule_wrap(check_all_buffers))
  end
end, 0)
