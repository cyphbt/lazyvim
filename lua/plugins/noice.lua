return {
  "folke/noice.nvim",
  opts = {
    lsp = {
      -- 不把 LSP 诊断弹成通知
      diagnostics = { enabled = false },
      -- 进度消息（如 gopls indexing）也不弹
      progress = { enabled = false },
    },
  },
}
