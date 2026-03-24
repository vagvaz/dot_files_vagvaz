return {
  'folke/sidekick.nvim',
  dependencies = {
    'folke/snacks.nvim',
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
  opts = {
    nes = { enabled = false },
    cli = {
      enabled = true,
      tools = {
        opencode = {
          cmd = { 'opencode' },
          env = { OPENCODE_THEME = 'system' },
        },
      },
      win = {
        layout = 'right',
        keys = {
          hide_n = { 'q', 'hide', mode = 'n' },
          hide_ctrl_dot = { '<C-.>', 'hide', mode = 'nt' },
          prompt = { '<C-p>', 'prompt', mode = 't' },
        },
      },
    },
  },
  keys = {
    { '<leader>ao', function() require('sidekick.cli').toggle({ name = 'opencode' }) end, desc = 'Toggle OpenCode CLI' },
    { '<leader>as', function() require('sidekick.cli').select() end, desc = 'Select CLI Tool' },
    { '<leader>at', function() require('sidekick.cli').send({ msg = '{this}' }) end, mode = { 'n', 'x' }, desc = 'Send This to AI' },
    { '<leader>af', function() require('sidekick.cli').send({ msg = '{file}' }) end, desc = 'Send File to AI' },
    { '<leader>av', function() require('sidekick.cli').send({ msg = '{selection}' }) end, mode = { 'x' }, desc = 'Send Selection to AI' },
    { '<leader>ap', function() require('sidekick.cli').prompt() end, mode = { 'n', 'x' }, desc = 'Select Prompt' },
    { '<leader>ad', function() require('sidekick.cli').close() end, desc = 'Close CLI Session' },
  },
}
