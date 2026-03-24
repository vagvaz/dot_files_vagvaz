local capabilities = require('common_lsp')

return {
  cmd = { 'ruff', 'server' },
  filetypes = { 'python' },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
  capabilities = capabilities,
  settings = {},
  init_options = {
    settings = {
      logLevel = 'info',
      configurationPreference = "filesystemFirst",
      lint = {
        enable = true,
        preview = false,
        select = { "E", "F", "I" },
        ignore = {},
      },
      format = {
        preview = false,
      },
    },
  },
  on_attach = function(client, bufnr)
    -- Disable hover capability to avoid conflicts with pylsp
    client.server_capabilities.hoverProvider = false
  end,
}
