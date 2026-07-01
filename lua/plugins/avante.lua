return {
  "yetone/avante.nvim",
  event = "VeryLazy",
  version = false,
  build = "make",
  keys = {
    {
      "<leader>aa",
      function()
        require("avante.api").ask()
        vim.defer_fn(function()
          local sidebar = require("avante").get()
          if sidebar and sidebar.focus_input then
            sidebar:focus_input()
            vim.cmd("startinsert")
          end
        end, 80)
      end,
      mode = { "n", "v" },
      desc = "Avante Ask",
    },
    { "<leader>at", "<cmd>AvanteToggle<cr>", desc = "Avante Toggle" },
    { "<leader>ap", "<cmd>AvanteSwitchProvider<cr>", desc = "Avante Switch Provider" },
    {
      "<leader>ac",
      function() require("avante.api").switch_provider("claude-code") end,
      desc = "Avante Claude Code",
    },
    {
      "<leader>ax",
      function() require("avante.api").switch_provider("codex") end,
      desc = "Avante Codex",
    },
    {
      "<leader>ai",
      function()
        local sidebar = require("avante").get()
        if sidebar and sidebar.focus_input then
          sidebar:focus_input()
          vim.cmd("startinsert")
        else
          require("avante.api").ask()
        end
      end,
      desc = "Avante Focus Input",
    },
  },
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "stevearc/dressing.nvim",
    "nvim-lua/plenary.nvim",
    "MunifTanjim/nui.nvim",
    -- 图标支持
    "nvim-tree/nvim-web-devicons",
    -- 文件选择器（可选，提升体验）
    "nvim-telescope/telescope.nvim",
    -- 渲染 markdown
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
  },
  opts = {
    provider = "claude-code",
    acp_providers = {
      ["claude-code"] = {
        command = "claude-agent-acp",
        args = {},
        env = {
          NODE_NO_WARNINGS = "1",
          ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY"),
          ANTHROPIC_BASE_URL = os.getenv("ANTHROPIC_BASE_URL"),
          ACP_PATH_TO_CLAUDE_CODE_EXECUTABLE = vim.fn.exepath("claude"),
          ACP_PERMISSION_MODE = "bypassPermissions",
        },
      },
      codex = {
        command = "codex-acp",
        args = {},
        env = {
          NODE_NO_WARNINGS = "1",
          HOME = os.getenv("HOME"),
          PATH = os.getenv("PATH"),
          OPENAI_API_KEY = os.getenv("OPENAI_API_KEY"),
        },
      },
    },
    behaviour = {
      auto_focus_sidebar = true,
      acp_follow_agent_locations = true,
      auto_focus_on_diff_view = true,
    },
    -- 侧边栏位置
    windows = {
      position = "right",
      wrap = true,
      width = 35,
      sidebar_header = {
        align = "center",
        rounded = true,
      },
    },
    -- diff 配置
    diff = {
      autojump = true,
      list_opener = "copen",
    },
    hints = { enabled = true },
  },
}
