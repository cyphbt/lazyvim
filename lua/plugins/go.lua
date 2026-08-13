return {
  -- 安装 Go treesitter parser（语法高亮精细着色的基础）
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, { "go", "gomod", "gosum", "gotmpl" })
    end,
  },


  -- 确保 mason 自动安装 gopls
  {
    "mason-org/mason-lspconfig.nvim",
    opts = {
      ensure_installed = { "gopls" },
    },
  },

  -- 配置 gopls LSP
  {
    "neovim/nvim-lspconfig",
    opts = {
      -- go.mod 没有有用的类型内联提示；gopls 在内容未输入完整时，
      -- inlayHint 请求会返回解析错误并被 Neovim 弹成通知。
      inlay_hints = {
        exclude = { "vue", "gomod" },
      },
      servers = {
        gopls = {
          settings = {
            gopls = {
              analyses = {
                unusedparams = true,
              },
              staticcheck = true,
              hints = {
                assignVariableTypes = false,
                compositeLiteralFields = false,
                compositeLiteralTypes = false,
                constantValues = false,
                functionTypeParameters = false,
                parameterNames = false,
                rangeVariableTypes = false,
              },
            },
          },
          -- 过滤特定的 staticcheck 诊断
          -- ST1003: 命名约定检查（如 stuId vs stuID）
          -- ST1021: 导出类型注释格式检查
          on_attach = function(client, bufnr)
            -- 使用延迟执行，确保在 LazyVim 的处理器之后设置
            vim.schedule(function()
              -- 拦截 gopls 的诊断发布，过滤掉 ST1003 和 ST1021
              local original_handler = client.handlers["textDocument/publishDiagnostics"]
              client.handlers["textDocument/publishDiagnostics"] = function(err, result, ctx, config)
                if result and result.diagnostics then
                  -- 过滤掉 ST1003 和 ST1021 的诊断
                  local filtered = {}
                  for _, diag in ipairs(result.diagnostics) do
                    local message = diag.message or ""
                    local severity = diag.severity or 0

                    -- 只保留 ERROR (1) 和 WARNING (2)，过滤掉 INFO (3) 和 HINT (4)
                    -- go.mod 中 gopls 会产生大量无用 HINT/INFO，疯狂在行尾刷屏
                    if severity == 3 or severity == 4 then
                      -- 跳过
                    -- 匹配 ST1003（命名约定）和 ST1021（导出注释格式）
                    elseif message:match("ST1003") or message:match("ST1021") then
                      -- 跳过
                    elseif message:match("should be.*ID") or message:match("should be.*URL") then
                      -- 跳过
                    elseif message:match("comment on exported type.*should be of the form") then
                      -- 跳过
                    else
                      table.insert(filtered, diag)
                    end
                  end
                  result.diagnostics = filtered
                end
                -- 调用原始处理器
                if original_handler then
                  original_handler(err, result, ctx, config)
                else
                  vim.lsp.diagnostic.on_publish_diagnostics(err, result, ctx, config)
                end
              end
            end)
          end,
        },
      },
    },
  },

  -- go.mod 仍由 gopls 格式化，但编辑到一半时不弹出格式化失败通知。
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        gomod = {
          lsp_format = "fallback",
          quiet = true,
        },
      },
    },
  },

  -- Go 工具增强
  {
    "ray-x/go.nvim",
    dependencies = { "ray-x/guihua.lua" },
    config = function()
      require("go").setup({
        -- 由 LazyVim 按 filetype 管理；避免 go.nvim 全局重新启用 gomod inlay hints。
        lsp_inlay_hints = {
          enable = false,
        },
        -- LazyVim 已通过 conform.nvim 处理 format on save，避免重复格式化
        format = {
          format_on_save = false,
        },
      })
    end,
    ft = { "go", "gomod" },
    build = ':lua require("go.install").update_all()',
  },
}
