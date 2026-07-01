return {
  { "karb94/neoscroll.nvim", enabled = false },
  {
    "folke/snacks.nvim",
    opts = {
      scroll = { enabled = false },
      picker = {
        formatters = {
          file = {
            min_width = 200,
          },
        },
      },
    },
  },
}
