
capabilities = require('common_lsp')
return {
  filetypes = { 'lua' },
  settings = {
    Lua = { completion = { callSnippet = 'Replace' } },
  },
  capabilities = capabilities,
}
