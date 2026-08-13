return {
  "koushikxd/resu.nvim",
  event = "VeryLazy",
  dependencies = {
    "sindrets/diffview.nvim",
  },
  opts = {
    use_diffview = true,
    hot_reload = true,
    debounce_ms = 100,
    ignored_files = {
      "%.git/",
      "node_modules/",
      "dist/",
      "build/",
      "%.lock",
      "%.DS_Store",
      "%.swp",
    },
    keymaps = {
      toggle = "<leader>rt",
      accept = "<leader>ra",
      decline = "<leader>rd",
      accept_all = "<leader>rA",
      decline_all = "<leader>rD",
      refresh = "<leader>rr",
      quit = "q",
    },
  },
}
