return {
  'saghen/blink.cmp',
  dependencies = {
    'rafamadriz/friendly-snippets',
    'milanglacier/minuet-ai.nvim',
  },

  version = '*',
  ---@module 'blink.cmp'
  ---@type blink.cmp.Config
  opts = {
    keymap = { preset = 'default' },

    appearance = {
      use_nvim_cmp_as_default = true,
      nerd_font_variant = 'mono'
    },
    signature = { enabled = true },
    completion = { documentation = { auto_show = true, auto_show_delay_ms = 300 } },
    sources = {
      default = { 'lsp', 'path', 'snippets', 'buffer', 'minuet' },
      providers = {
        minuet = {
          name = 'minuet',
          module = 'minuet.blink',
          score_offset = 50,
        },
      },
    },
  },
  snippets = { preset = 'default' },

  signature = { enabled = true },
  opts_extend = { "sources.default" }
}
