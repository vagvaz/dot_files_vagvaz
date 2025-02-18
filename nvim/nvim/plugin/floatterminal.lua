local state = {
  floating = {
    buf = -1,
    win = -1,
  }
}
local function create_floating_window(opts)
  opts = opts or {}
  local percent = opts.percent or 0.8
  local width = opts.width or math.floor(vim.o.columns * percent)
  local height = opts.height or math.floor(vim.o.lines * percent)

  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height / 2))
  local win = opts.win or vim.api.nvim_win_id
  local buf = nil or opts.buf
  if buf == nil or not vim.api.nvim_buf_is_valid(buf) then
    buf = vim.api.nvim_create_buf(false, true) -- No file, scratch buffer
  end
  local win_config = {
    relative = 'editor',
    width = width,
    height = height,
    col = col,
    row = row,
    style = 'minimal',
    border = 'double',
  }
  print('buffer ', vim.inspect(buf), ' win ', win)
  local res_win = vim.api.nvim_open_win(buf, true, win_config)
  return { buf = buf, win = res_win }
end

local function toggle_floatterm()
  if not vim.api.nvim_win_is_valid(state.floating.win) then
    state.floating = create_floating_window({ buf = state.floating.buf, percent = 0.75 })
    if vim.bo[state.floating.buf].buftype ~= 'terminal' then
      vim.cmd.terminal()
    end
  else
    vim.api.nvim_win_hide(state.floating.win)
  end
end
vim.api.nvim_create_user_command(
  'MyFloatTermToggle',
  function()
    toggle_floatterm()
  end,
  {})
vim.keymap.set({ 'n', 't' }, '<leader>tft', '<cmd>MyFloatTermToggle<CR>', { desc = 'Toggle a floating terminal' })
