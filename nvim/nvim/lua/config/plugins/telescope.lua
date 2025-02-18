-- return {}

return {
  {
    'nvim-telescope/telescope.nvim',
    tag = '0.1.8',
    dependencies = {
      'nvim-lua/plenary.nvim',
      { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make' }
    },
    config = function()
      require('telescope').setup {
        extensions = {
          fzf = {}
        },
        defaults = {
          -- use grep insttead of rg
          vimgrep_arguments = {
            "grepe",
            "--extended-regexp",
            "--color=never",
            "--with-filename",
            "--line-number",
            "-b", -- grep doesn't support a `--column` option :(
            "--ignore-case",
            "--recursive",
            "--no-messages",
            "--exclude-dir=\\*cache\\*",
            "--exclude-dir=\\*.git",
            "--exclude=.\\*",
            "--binary-files=without-match"
          },
        }
      }
      require('telescope').load_extension('fzf')
      local tb = require('telescope.builtin')
      local th = require('telescope.themes')
      -- vim.keymap.set('n', '<leader>ff', tb.find_files, { desc = '[F]ind [F]iles' })
      vim.keymap.set('n', '<leader>fth', function()
          local opts = th.get_ivy {}
          tb.help_tags(opts)
        end,
        { desc = '[Find] [T]ele [H]elp' }
      )
      -- vim.keymap.set('n', '<leader>fN',
      --   function() th.find_files({ cwd = vim.fn.stdpath('config') }) end,
      --   { desc = '[F]ind [N]eovim files' }
      -- )
      -- vim.keymap.set('n', '<leader>ftp',
      -- 	function()
      -- 		local opts = th.get_ivy({ cwd = vim.fs.joinpath(vim.fn.stdpath('data'), 'lazy') })
      -- 		tb.find_files(opts)
      -- 	end,
      -- 	{ desc = '[F]ind in plugins' }
      -- )
      -- require('config.custom.telescope.livegrep').setup {}
      -- vim.keymap.set('n', '<leader>fg', function()
      -- 	require('config.custom.telescope.livegrep').livegrep {}
      -- end, { desc = '[F] live [Grep]' })
    end
  },
}
