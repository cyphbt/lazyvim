return {
  -- 已经内置，只改配置
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      -- 1. 行尾虚拟文字 blame
      current_line_blame = true, -- 默认就显示
      current_line_blame_opts = {
        virt_text = true,
        virt_text_pos = "eol", -- 行尾
        delay = 1500, -- 1500 ms 后弹出，减少光标移动时的渲染频率
      },
      current_line_blame_formatter = "  <author>, <author_time:%Y-%m-%d>  <summary>",
    },
    keys = {
      -- 弹窗显示当前行完整 blame
      {
        "<leader>gB",
        function()
          require("gitsigns").blame_line({ full = true })
        end,
        desc = "Git Blame 当前行",
      },
      {
        "]h",
        function()
          require("gitsigns").nav_hunk("next")
        end,
        desc = "Next Git Hunk",
      },
      {
        "[h",
        function()
          require("gitsigns").nav_hunk("prev")
        end,
        desc = "Previous Git Hunk",
      },
      {
        "<leader>ghp",
        function()
          local gs = require("gitsigns")
          if gs.preview_hunk_inline then
            gs.preview_hunk_inline()
          else
            gs.preview_hunk()
          end
        end,
        desc = "Preview Git Hunk Inline",
      },
      {
        "<leader>gq",
        function()
          require("gitsigns").setqflist()
        end,
        desc = "Git Hunks Quickfix",
      },
      {
        "<leader>ghd",
        function()
          require("gitsigns").diffthis()
        end,
        desc = "Diff This",
      },
      {
        "<leader>ghn",
        function()
          require("gitsigns").nav_hunk("next")
        end,
        desc = "Next Git Hunk",
      },
      {
        "<leader>ghN",
        function()
          require("gitsigns").nav_hunk("prev")
        end,
        desc = "Previous Git Hunk",
      },
    },
  },

  -- GoLand 风格：左侧 blame 列，每行显示 commit/日期/作者
  {
    "tpope/vim-fugitive",
    keys = {
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git Blame 左侧列" },
    },
  },
}
