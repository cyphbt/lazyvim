return {
  {
    -- 本地 dark-dracule 主题（参考 Cursor dark-dracula 配色）
    dir = vim.fn.expand("~/github/dark-dracule"),
    name = "dark-dracule",
    lazy = false,
    priority = 1000,
    opts = {
      transparent = false,     -- 透明背景（可改为 true）
      terminal_colors = true,  -- 设置终端颜色
      italic_comments = true,  -- 注释斜体
      italic_keywords = false, -- 关键字斜体
      bold_functions = false,  -- 函数加粗
    },
    config = function(_, opts)
      require("dark-dracule").setup(opts)
      vim.cmd.colorscheme("dark-dracule")
    end,
  },

  -- 禁用其他主题
  { "sainnhe/gruvbox-material", enabled = false },
  { "cyphbt/papercolor-theme",  enabled = false },

  -- 禁用 bufferline（不需要顶部 buffer 标签栏）
  { "akinsho/bufferline.nvim",  enabled = false },

  -- lualine 使用 dark-dracule 主题
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      local ok, dracule = pcall(require, "dark-dracule")
      if ok then
        opts.options = opts.options or {}
        opts.options.theme = dracule.get_lualine_theme()
      end
      opts.winbar = {}
      opts.inactive_winbar = {}
    end,
  },
}
