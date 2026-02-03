vim.g.mapleader = " "
vim.g.maplocalleader = " "

require("config.lazy")

require("config.options")
require("config.keymaps")

vim.lsp.enable({
  'lua_ls',
  'pylsp',
  'clangd',
 --  'pyright',
})
