return {
  {
    "cyphbt/papercolor-theme",
    enabled = false, -- 已切换为 dark-dracule 主题
    lazy = false,
    priority = 1000,
    opts = {
      theme = {
        ["default.dark"] = {
          allow_bold = 1,
          allow_italic = 0,
          -- 参考 Tokyo Night 风格，增强 dark 主题的语法高亮
          override = {
            -- 背景色：RGB(0.024, 0.024, 0.024) = #060606
            color00         = { "#060606", "232" }, -- 主背景
            cursor_fg       = { "#060606", "232" }, -- 光标前景
            cursorline      = { "#111111", "233" }, -- 当前行背景
            cursorcolumn    = { "#111111", "233" }, -- 当前列背景
            linenumber_bg   = { "#060606", "232" }, -- 行号背景
            cursorlinenr_bg = { "#060606", "232" }, -- 当前行号背景
            vertsplit_bg    = { "#060606", "232" }, -- 竖分割背景
            todo_bg         = { "#060606", "232" }, -- TODO 背景

            -- 语法高亮（参考 Tokyo Night）
            color03  = { "#9ece6a", "107" }, -- 字符串 → 清爽绿色
            color05  = { "#565f89", "60"  }, -- 注释   → 蓝灰色（更易区分）
            color06  = { "#7aa2f7", "111" }, -- 存储类关键字 (var/const/type) → 蓝色
            color09  = { "#73daca", "80"  }, -- import/try 等关键字 → 青绿色
            color10  = { "#2ac3de", "38"  }, -- 类型/强调关键字 → 亮青色
            color11  = { "#bb9af7", "141" }, -- 控制流 (if/for/range) → 紫色
            color12  = { "#ff9e64", "215" }, -- 重音色 → 橙色
            color13  = { "#ff9e64", "215" }, -- 数字字面量 → 橙色
            color14  = { "#7aa2f7", "111" }, -- 普通关键字 → 蓝色
            color16  = { "#7dcfff", "117" }, -- 其他关键字 → 浅蓝色
            color17  = { "#e0af68", "179" }, -- 布尔值/标签 → 暖黄色
          },
        },
      },
    },
    config = function(_, opts)
      require("papercolor-theme").setup(opts)
      vim.o.background = "dark"
      vim.cmd.colorscheme("PaperColor")
    end,
  },
}
