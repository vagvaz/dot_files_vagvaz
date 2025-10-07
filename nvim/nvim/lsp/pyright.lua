capa = require('common_lsp')
return {
  filetypes = { 'python' },
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "openFilesOnly",
        useLibraryCodeForTypes = true,
        autoImportCompletions = true,
        includeFileSpecs = { "**/*.py" },
      },
    },
  },
  capabilities = capa,
}
