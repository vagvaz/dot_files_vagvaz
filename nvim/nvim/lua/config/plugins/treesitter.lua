return {

  { -- Highlight, edit, and navigate code
    'nvim-treesitter/nvim-treesitter',
    branch = 'main', -- Use the new main branch for Neovim 0.12+
    build = ':TSUpdate',
    -- [[ Configure Treesitter ]] See `:help nvim-treesitter`
    config = function()
      -- Setup must be called first
      require('nvim-treesitter').setup()

      -- List of parsers to ensure are installed
      local ensure_installed = {
        'bash', 'c', 'cpp', 'python', 'yaml', 'diff', 'html', 'json',
        'lua', 'luadoc', 'markdown', 'markdown_inline', 'query',
        'vim', 'vimdoc', 'sql', 'go'
      }

      -- Install parsers that aren't already installed
      -- New API for Neovim 0.12+: use get_installed() instead of installed_parsers()
      local installed = require('nvim-treesitter').get_installed()
      local parsers_to_install = vim.tbl_filter(
        function(parser)
          return not vim.tbl_contains(installed, parser)
        end,
        ensure_installed
      )

      if #parsers_to_install > 0 then
        require('nvim-treesitter').install(parsers_to_install)
      end

      -- Set up treesitter-based highlighting and indentation via autocmd
      vim.api.nvim_create_autocmd('FileType', {
        callback = function()
          -- Enable treesitter highlighting (disable regex syntax)
          pcall(vim.treesitter.start)
          -- Enable treesitter-based indentation
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end,
      })

      -- Set up treesitter-based folding for supported filetypes
      vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'python', 'c', 'cpp', 'lua' },
        callback = function()
          vim.opt_local.foldmethod = 'expr'
          -- Use the new API for fold expression
          vim.opt_local.foldexpr = "v:lua.vim.treesitter.foldexpr()"
          vim.opt_local.foldenable = true
        end,
      })
    end,
    -- There are additional nvim-treesitter modules that you can use to interact
    -- with nvim-treesitter. You should go explore a few and see what interests you:
    --
    --    - Incremental selection: Included, see `:help nvim-treesitter-incremental-selection-mod`
    --    - Show your current context: https://github.com/nvim-treesitter/nvim-treesitter-context
    --    - Treesitter + textobjects: https://github.com/nvim-treesitter/nvim-treesitter-textobjects
  },

  { -- Show current function/class context at top of screen
    -- kiyoon fork compatible with Neovim 0.12 (original repo archived)
    'kiyoon/nvim-treesitter-context',
    config = function()
      require 'treesitter-context'.setup {
        enable = true,            -- Enable this plugin (Can be enabled/disabled later via commands)
        multiwindow = true,       -- Enable multiwindow support.
        max_lines = 0,            -- How many lines the window should span. Values <= 0 mean no limit.
        min_window_height = 0,    -- Minimum editor window height to enable context. Values <= 0 mean no limit.
        line_numbers = true,
        multiline_threshold = 20, -- Maximum number of lines to show for a single context
        trim_scope = 'outer',     -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
        mode = 'cursor',          -- Line used to calculate context. Choices: 'cursor', 'topline'
        -- Separator between context and content. Should be a single character string, like '-'.
        -- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
        separator = nil,
        zindex = 20,     -- The Z-index of the context window
        on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
      }
      vim.keymap.set('n', "[c", function()
        require("treesitter-context").go_to_context(vim.v.counti)
      end, { silent = false })
    end
  },
}
