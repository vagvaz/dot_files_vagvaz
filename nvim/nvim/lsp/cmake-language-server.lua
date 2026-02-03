local capabilities = require('common_lsp')

local function find_cmake_root(fname)
  local util = require('lspconfig.util')
  local markers = {
    'CMakeLists.txt',
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
  filetypes = { "cmake" },
  cmd = { "cmake-language-server" },
  root_markers = { "CMakeLists.txt", ".git" },
  root_dir = find_cmake_root,
}
