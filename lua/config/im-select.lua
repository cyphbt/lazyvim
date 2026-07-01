local english_input = "com.apple.keylayout.ABC"
local last_input = english_input

local function get_current_input()
  local result = vim.fn.system("im-select")
  return vim.trim(result)
end

local function switch_input(input)
  if input and input ~= "" then
    vim.fn.system({ "im-select", input })
  end
end

vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    switch_input(last_input)
  end,
})

vim.api.nvim_create_autocmd("InsertLeave", {
  callback = function()
    last_input = get_current_input()
    switch_input(english_input)
  end,
})

vim.api.nvim_create_autocmd("VimLeave", {
  callback = function()
    switch_input(last_input)
  end,
})
