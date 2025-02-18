vim.g.have_nerd_font = true

--  Line numbers default
vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.mouse = 'a'
vim.opt.showmode = false


vim.opt.breakindent = true
vim.opt.undofile = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.updatetime = 250
-- Decrease mapped sequence wait time
-- Displays which-key popup sooner
vim.opt.timeoutlen = 300
-- configure how new splits should be opened
vim.opt.splitright = true
vim.opt.splitbelow = true

--vim.opt.list = true
--vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live
vim.opt.inccommand = 'split'
-- Show which line your cursor is on highlight
vim.opt.cursorline = true
-- Minimum number of screen lines to keep above and below the cursro.
vim.opt.scrolloff = 10


-- Space
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true

vim.opt.undodir = os.getenv 'HOME' .. '/.vim/undorir'
vim.opt.hlsearch = true -- highlight searches
vim.opt.incsearch = true

vim.opt.scrolloff = 4
vim.opt.colorcolumn = '100'
vim.opt.updatetime = 50

