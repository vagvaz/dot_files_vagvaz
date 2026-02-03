local capabilities = require('common_lsp')

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
  cmd = { "pylsp" },
  filetypes = { "python" },
  root_markers = { "pyproject.toml", "setup.py", "setup.cfg", "requirements.txt", "Pipfile", ".git" },
  root_dir = find_python_root,
  capabilities = capabilities,
  settings = {
    pylsp = {
      plugins = {
        -- Enable basic code actions
        mccabe = { enabled = false },
        autopep8 = { enabled = false },
        yapf = { enabled = false },
        -- formatter options
        autopep8 = { enabled = false },
        yapf = { enabled = false },
        -- linter options
        pylint = { enabled = false },
        pyflakes = { enabled = false },
        pycodestyle = { enabled = false },
        flake8 = { enabled = false },
        -- type checker
        mypy = {
          enabled = true,
          live_mode = true,
          mypy = true,
          -- dmypy=true,
        },
        -- auto-completion options
        jedi_completion = {
          enabled = true,
          fuzzy = true,
          include_function_objects = true,
          include_class_objects = true,
          include_params = true,
        },
        jedi_hover = { enabled = true },
        jedi_references = { enabled = true },
        jedi_signature_help = { enabled = true },
        jedi_symbols = { enabled = true },
        rope_autoimport = { enabled = true, completions = { enabled = true }, code_actions = { enabled = true } },
        rope_completion = { enabled = true, fuzzy = true },
        rope_refactor = { enabled = true },
        -- import sorting
        isort = { enabled = true },
        -- Enable code action providers
        --   ruff = {
        --     enabled = true,
        --     formatEnabled = true,
        --     executable = "ruff",
        --     extendSelect = { "I", "F", "E", "W" },
        --     format = { "I" },
        --     severities = { ["D212"] = "I" },
        --     unsafeFixes = true,
        --     lineLength = 100,
        --     select = { "F", "E", "W", "I" },
        --     ignore = { "D210" },
        --     perFileIgnores = { ["__init__.py"] = "CPY001" },
        --     preview = false,
        --     targetVersion = "py37",
        --   },
      },
    },
  },
  flags = {
    debounce_text_changes = 200,
  },
}
