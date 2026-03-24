local capabilities = require('common_lsp')

return {
  cmd = { '/home/vagvaz/Projects/tomoroai_vagvaz/.venv/bin/basedpyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', 'requirements.txt', 'Pipfile', '.git' },
  settings = {
    basedpyright = {
      analysis = {
        autoSearchPaths = true,
        useLibraryCodeForTypes = true,
        diagnosticMode = 'workspace',
      },
    },
  },
  capabilities = capabilities,
}
