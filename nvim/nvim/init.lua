vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Prepend mason bin to PATH
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
vim.env.PATH = mason_bin .. ":" .. vim.env.PATH

require("config.lazy")

require("config.options")
require("config.keymaps")
