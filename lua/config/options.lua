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
