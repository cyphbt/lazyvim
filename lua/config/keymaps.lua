-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local fn_types = { function_declaration = true, method_declaration = true }

local function get_function_name(func_node)
  local name = func_node:field("name")
  if name and #name > 0 then
    local r, c = name[1]:start()
    return r, c
  end
  return func_node:start()
end

local function collect_function_nodes(bufnr)
  local parser = vim.treesitter.get_parser(bufnr)
  if not parser then
    return nil
  end
  local tree = parser:parse()[1]
  if not tree then
    return nil
  end
  local nodes = {}
  local function walk(node)
    if fn_types[node:type()] then
      table.insert(nodes, node)
    end
    for child in node:iter_children() do
      walk(child)
    end
  end
  walk(tree:root())
  return nodes
end

local function cursor_on_node_name(func_node, row, col)
  local name = func_node:field("name")
  if not name or #name == 0 then
    return false
  end
  local sr, sc = name[1]:start()
  local er, ec = name[1]:end_()
  return row >= sr and row <= er and col >= sc and col <= ec
end

local function goto_prev_function()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]
  local nodes = collect_function_nodes(bufnr)
  if not nodes or #nodes == 0 then
    return
  end
  -- 先看光标是否在某个函数体内（但不在函数名上），是则跳到该函数名
  for _, node in ipairs(nodes) do
    local sr = node:start()
    local er = node:end_()
    if row >= sr and row <= er and not cursor_on_node_name(node, row, col) then
      local r, c = get_function_name(node)
      vim.api.nvim_win_set_cursor(0, { r + 1, c })
      return
    end
  end
  -- 否则找上一个函数（光标在当前函数名上时就走这里）
  local best
  for _, node in ipairs(nodes) do
    local end_row = node:end_()
    if end_row <= row then
      if not best or end_row > best:end_() then
        best = node
      end
    end
  end
  if best then
    local r, c = get_function_name(best)
    vim.api.nvim_win_set_cursor(0, { r + 1, c })
  end
end

local function goto_next_function()
  local bufnr = vim.api.nvim_get_current_buf()
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local nodes = collect_function_nodes(bufnr)
  if not nodes or #nodes == 0 then
    return
  end
  local best
  for _, node in ipairs(nodes) do
    local start_row = node:start()
    if start_row > row then
      if not best or start_row < best:start() then
        best = node
      end
    end
  end
  if best then
    local r, c = get_function_name(best)
    vim.api.nvim_win_set_cursor(0, { r + 1, c })
  end
end

vim.api.nvim_create_autocmd("LspAttach", {
  callback = function(args)
    vim.keymap.set("n", "[f", goto_prev_function, {
      desc = "Go to previous function",
      noremap = true,
      silent = true,
      buffer = args.buf,
    })
    vim.keymap.set("n", "]f", goto_next_function, {
      desc = "Go to next function",
      noremap = true,
      silent = true,
      buffer = args.buf,
    })
  end,
})


-- gx 打开 URL，自动补全 https:// 前缀（go.mod 模块路径没有 scheme）
vim.keymap.set("n", "gx", function()
  local url = vim.fn.expand("<cfile>")
  if not url:match("^https?://") then
    url = "https://" .. url
  end
  vim.ui.open(url)
end, { desc = "Open URL", noremap = true, silent = true })

-- 用剪贴板内容搜索（自动转义 regex 特殊字符）
vim.keymap.set("n", "<leader>sp", function()
  local text = vim.fn.getreg("+")
  if text == "" then
    text = vim.fn.getreg('"')
  end
  -- 转义 ripgrep 的 regex 特殊字符
  text = text:gsub("([%(%)%[%]%{%}%\\%^%$%.%|%?%*%+])", "\\%1")
  -- 去掉换行（多行粘贴只取第一行）
  text = text:gsub("\n.*", "")
  require("telescope.builtin").live_grep({ default_text = text })
end, { desc = "Search clipboard text (escaped)", noremap = true, silent = true })

-- 全局覆盖 gi（谨慎！）
vim.keymap.set("n", "gi", function()
  Snacks.picker.lsp_implementations()
end, {
  desc = "Go to implementation",
  noremap = true,
  silent = true,
})

vim.keymap.set("n", "<leader>sG", function()
  require("telescope.builtin").live_grep({
    additional_args = function()
      return { "--fixed-strings" }
    end,
  })
end, { desc = "Grep literal string" })

vim.keymap.set("n", "<leader>gs", function()
  Snacks.picker.git_status()
end, { desc = "Git changed files", noremap = true, silent = true })

vim.keymap.set("n", "<leader>gd", function()
  Snacks.picker.git_diff({ group = false })
end, { desc = "Git changed hunks", noremap = true, silent = true })

local function git_root()
  local name = vim.api.nvim_buf_get_name(0)
  local start = name ~= "" and vim.fs.dirname(name) or vim.uv.cwd()
  return vim.fs.root(start, ".git") or vim.uv.cwd()
end

local function split_nonempty(text)
  text = vim.trim(text or "")
  if text == "" then
    return {}
  end
  return vim.split(text, "\n", { plain = true })
end

local function git_changed_files(cb)
  local root = git_root()
  vim.system({ "git", "-C", root, "diff", "--name-only", "HEAD" }, { text = true }, function(diff_res)
    vim.system({ "git", "-C", root, "ls-files", "--others", "--exclude-standard" }, { text = true }, function(untracked_res)
      vim.schedule(function()
        if diff_res.code ~= 0 then
          vim.notify(vim.trim(diff_res.stderr or "git diff failed"), vim.log.levels.ERROR)
          return
        end

        local seen = {}
        local files = {}
        for _, file in ipairs(vim.list_extend(split_nonempty(diff_res.stdout), split_nonempty(untracked_res.stdout))) do
          if not seen[file] then
            seen[file] = true
            table.insert(files, file)
          end
        end
        cb(root, files)
      end)
    end)
  end)
end

local function open_diff_buffer(title, lines)
  vim.cmd("botright split")
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(0, buf)
  vim.bo[buf].bufhidden = "wipe"
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_name(buf, title)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
end

local function open_changed_file()
  git_changed_files(function(root, files)
    if vim.tbl_isempty(files) then
      vim.notify("No changed files", vim.log.levels.INFO)
      return
    end

    vim.ui.select(files, { prompt = "Open changed file" }, function(file)
      if file then
        vim.cmd.edit(vim.fn.fnameescape(root .. "/" .. file))
      end
    end)
  end)
end

local function changed_files_quickfix()
  git_changed_files(function(root, files)
    if vim.tbl_isempty(files) then
      vim.notify("No changed files", vim.log.levels.INFO)
      return
    end

    local items = vim.tbl_map(function(file)
      return { filename = root .. "/" .. file, lnum = 1, text = file }
    end, files)
    vim.fn.setqflist({}, " ", { title = "AI changed files", items = items })
    vim.cmd.copen()
  end)
end

local function current_file_diff()
  local root = git_root()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    vim.notify("Current buffer is not a file", vim.log.levels.WARN)
    return
  end

  vim.system({ "git", "-C", root, "diff", "HEAD", "--", file }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        vim.notify(vim.trim(res.stderr or "git diff failed"), vim.log.levels.ERROR)
        return
      end
      local lines = split_nonempty(res.stdout)
      if vim.tbl_isempty(lines) then
        vim.notify("No diff in current file", vim.log.levels.INFO)
        return
      end
      open_diff_buffer("AI current file diff", lines)
    end)
  end)
end

local function project_diff()
  local root = git_root()
  vim.system({ "git", "-C", root, "diff", "HEAD" }, { text = true }, function(res)
    vim.schedule(function()
      if res.code ~= 0 then
        vim.notify(vim.trim(res.stderr or "git diff failed"), vim.log.levels.ERROR)
        return
      end
      local lines = split_nonempty(res.stdout)
      if vim.tbl_isempty(lines) then
        vim.notify("No project diff", vim.log.levels.INFO)
        return
      end
      open_diff_buffer("AI project diff", lines)
    end)
  end)
end

vim.api.nvim_create_user_command("AiChangedFiles", open_changed_file, {})
vim.api.nvim_create_user_command("AiChangedFilesQf", changed_files_quickfix, {})
vim.api.nvim_create_user_command("AiCurrentDiff", current_file_diff, {})
vim.api.nvim_create_user_command("AiProjectDiff", project_diff, {})

vim.keymap.set("n", "<leader>gcf", open_changed_file, { desc = "Git: open changed file", noremap = true, silent = true })
vim.keymap.set(
  "n",
  "<leader>gcq",
  changed_files_quickfix,
  { desc = "Git: changed files quickfix", noremap = true, silent = true }
)
vim.keymap.set("n", "<leader>gcd", current_file_diff, { desc = "Git: current file diff", noremap = true, silent = true })
vim.keymap.set("n", "<leader>gcD", project_diff, { desc = "Git: project diff", noremap = true, silent = true })
