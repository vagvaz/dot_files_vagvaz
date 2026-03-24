
local capabilities = require('common_lsp')

return {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
  root_markers = { 'compile_commands.json', 'CMakeLists.txt', '.clangd', '.clang-format', '.clang-tidy', '.git' },
  capabilities = capabilities,
}
