local capa = require('common_lsp')

local function find_python_root(fname)
  local util = require('lspconfig.util')
  local markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  }
  
  for _, marker in ipairs(markers) do
    local root = util.root_pattern(marker)(fname)
    if root then
      return root
    end
  end
  
  return vim.fn.getcwd()
end

return {
  filetypes = { 'python' },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
  root_dir = find_python_root,
  settings = {
    python = {
      analysis = {
        autoSearchPaths = true,
        diagnosticMode = "workspace",
        useLibraryCodeForTypes = true,
        autoImportCompletions = true,
        reportMissingImports = true,
        includeFileSpecs = { "**/*.py" },
      },
    },
  },
  capabilities = capa,
}
