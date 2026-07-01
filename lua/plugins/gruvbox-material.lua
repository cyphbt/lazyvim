return {
  {
    -- refer: https://github.com/sainnhe/gruvbox-material/blob/master/doc/gruvbox-material.txt
    "sainnhe/gruvbox-material",
    enabled = false, -- 已切换为 PaperColor 主题
    lazy = false, -- 立即加载（不要 lazy 加载颜色方案）
    priority = 900, -- 高优先级，确保尽早生效
    config = function()
      vim.g.gruvbox_material_background = "medium"

      -- 可选：设置对比度（dark/light 模式）
      vim.g.gruvbox_material_contrast_dark = "high" -- 可选: "medium", "low"
      vim.g.gruvbox_material_contrast_light = "high"

      -- 可选：启用斜体（推荐）
      vim.g.gruvbox_material_enable_italic = 1
      vim.g.gruvbox_material_enable_bold = 1

      -- 可选：设置终端颜色（让终端 ls、grep 等也用主题色）
      vim.g.gruvbox_material_terminal_colors = true

      -- 应用主题
      vim.cmd("colorscheme gruvbox-material")
    end,
  },
}
