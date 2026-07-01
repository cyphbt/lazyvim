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
      servers = {
        gopls = {
          settings = {
            gopls = {
              analyses = {
                unusedparams = true,
              },
              staticcheck = true,
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
                    
                    -- 通过消息内容匹配（最可靠的方法）
                    -- 匹配 ST1003 和 ST1021 的诊断消息
                    if message:match("ST1003") or message:match("ST1021") then
                      -- 跳过这个诊断
                    -- 匹配命名约定相关的提示（如 "should be ...ID" 或 "should be ...URL"）
                    elseif message:match("should be.*ID") or message:match("should be.*URL") then
                      -- 跳过这个诊断
                    -- 匹配注释格式相关的提示
                    elseif message:match("comment on exported type.*should be of the form") then
                      -- 跳过这个诊断
                    else
                      -- 保留其他诊断
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

  -- Go 工具增强
  {
    "ray-x/go.nvim",
    dependencies = { "ray-x/guihua.lua" },
    config = function()
      require("go").setup({
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
