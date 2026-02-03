
local capabilities = require('common_lsp')

local function find_clangd_root(fname)
  local util = require('lspconfig.util')
  local markers = {
    'compile_commands.json',
    'CMakeLists.txt',
    '.clangd',
    '.clang-format',
    '.clang-tidy',
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
  filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto' },
  root_markers = { 'compile_commands.json', 'CMakeLists.txt', '.clangd', '.clang-format', '.clang-tidy', '.git' },
  root_dir = find_clangd_root,
  capabilities = capabilities,
}
