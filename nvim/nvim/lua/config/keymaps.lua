-- Move lines up and donw in  V
vim.keymap.set('n', '<space><space>x', '<cmd>source %<CR>')
vim.keymap.set('n', '<space>x', ':.lua <CR>')
vim.keymap.set('v', '<space>x', ':lua <CR>')
vim.keymap.set('v', 'J', ":m '>+1<CR>gv=gv")
vim.keymap.set('v', 'K', ":m '<-2<CR>gv=gv")

-- J takes the next line and appends to current this cursor where it is
vim.keymap.set('n', 'J', 'mzJ`z')
-- half a page jump keep cursor in the mid
vim.keymap.set('n', '<C-d>', '<C-d>zz')
vim.keymap.set('n', '<C-u>', '<C-u>zz')
vim.keymap.set('n', 'n', 'nzzzv')
vim.keymap.set('n', 'N', 'Nzzzv')
-- do not overwrite copy
vim.keymap.set('x', '<leader>p', '"_dP')
-- to clipboard
vim.keymap.set('n', '<leader>y', '"+y')
vim.keymap.set('v', '<leader>y', '"+y')
vim.keymap.set('n', '<leader>Y', '"+Y')

-- deleting the void register
vim.keymap.set('n', '<leader>d', '"_d')
vim.keymap.set('v', '<leader>d', '"_d')
-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic keymaps
vim.keymap.set('n', '<leader>q', function()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    vim.cmd('cclose')
  else
    vim.cmd('copen')
  end
end, { desc = 'Toggle [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })
vim.keymap.set('n', '<leader>term',
  function()
    vim.cmd.vnew()
    vim.cmd.term()
    vim.cmd.wincmd("J")
    vim.api.nvim_win_set_height(0, 20)
  end,
  { desc = '[Term] open terminal' }
)
-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.highlight.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function()
    vim.highlight.on_yank()
  end,
})

vim.keymap.set('n', '-', '<cmd>Oil<CR>', { desc = 'Start Navigating' })

-- LSP keybindings
vim.keymap.set('n', 'K', vim.lsp.buf.hover, { desc = 'Hover Documentation' })
vim.keymap.set('n', 'go', vim.lsp.buf.type_definition, { desc = 'Goto Type Definition' })
vim.keymap.set('n', 'gs', vim.lsp.buf.signature_help, { desc = 'Signature Help' })
vim.keymap.set('n', '<leader>rN', vim.lsp.buf.rename, { desc = '[R]e[n]ame symbol' })
vim.keymap.set('n', 'gl', vim.diagnostic.open_float, { desc = 'Open Diagnostic Float' })
vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Previous Diagnostic' })
vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Next Diagnostic' })

-- Folding keymaps
vim.keymap.set('n', 'za', 'za', { desc = 'Toggle fold' })
vim.keymap.set('n', 'zc', 'zc', { desc = 'Close fold' })
vim.keymap.set('n', 'zo', 'zo', { desc = 'Open fold' })
vim.keymap.set('n', 'zR', 'zR', { desc = 'Open all folds' })
vim.keymap.set('n', 'zM', 'zM', { desc = 'Close all folds' })
vim.keymap.set('v', 'zf', 'zf', { desc = 'Create fold' })

-- AI Features Toggle
local ai_state = { enabled = true }

local function set_blink_sources(use_ai)
  local ok, blink = pcall(require, 'blink.cmp')
  if not ok then return end

  local default_sources = { 'lsp', 'path', 'snippets', 'buffer' }
  if use_ai then table.insert(default_sources, 'minuet') end

  if type(blink.config) == 'table'
      and type(blink.config.sources) == 'table'
      and type(blink.config.sources.default) == 'table' then
    blink.config.sources.default = default_sources
    return
  end

  if type(blink.setup) == 'function' then
    pcall(blink.setup, { sources = { default = default_sources } })
  end
end

-- Disable ALL AI features
vim.keymap.set('n', '<leader>off', function()
  pcall(function() require('minuet').disable() end)
  pcall(function() require('sidekick.nes').disable() end)
  pcall(function() require('sidekick.cli').close() end)
  set_blink_sources(false)
  ai_state.enabled = false
  vim.notify('All AI features disabled', vim.log.levels.INFO)
end, { desc = 'Disable all AI features' })

-- Enable ALL AI features
vim.keymap.set('n', '<leader>on', function()
  pcall(function() require('minuet').enable() end)
  set_blink_sources(true)
  ai_state.enabled = true
  vim.notify('All AI features enabled', vim.log.levels.INFO)
end, { desc = 'Enable all AI features' })
