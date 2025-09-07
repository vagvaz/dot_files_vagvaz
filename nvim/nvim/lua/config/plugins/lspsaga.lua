return {
  {
    'nvimdev/lspsaga.nvim',
    event = 'LspAttach',
    config = function()
      require('lspsaga').setup {
        ui = {
          border = 'rounded',
          code_action = '💡',
          winblend = 10,
        },
        preview = {
          lines_above = 3,
          lines_below = 12,
        },
        code_action = {
          show_server_name = true,
          keys = {
            quit = '<Esc>',
            exec = '<C-y>',
          }
        },
        rename = {
          in_select = false,
        },
        symbol_in_winbar = { enable = false },
        diagnoicst = {
          on_insert = false,
          on_insert_follow = false,
        },
        lightbulb = {
          enable = false,
          -- gitsigns has priority 6
          sign_priority = 8,
        },
      }
      vim.keymap.set('n', 'gh', '<cmd>Lspsaga lsp_finder<CR>', { desc = 'Slp finder find sybols C-t to jump back' })
      vim.keymap.set({ 'n', 'v' }, '<leader>;', '<cmd>Lspsaga code_action<CR>', { desc = '[C]ode [A]ction' })
      vim.keymap.set('n', '<leader>srn', '<cmd>Lspsaga rename<CR>', { desc = '[S]ymbol [R]e[N]ame' })
      vim.keymap.set('n', '<leader>sc', "<cmd> Lspsaga show_cursor_diagnostics<CR>", {
        desc =
        '[S]how [C]ursor diagnsotcis'
      })
      vim.keymap.set('n', '<leader>sb', "<cmd> Lspsaga show_buf_diagnostics<CR>",
        { desc = '[S]how [B]ursor diagnsotcis' })
      vim.keymap.set('i', '<C-;>', '<cmd>lua vim.lsp.buf.signature_help()<CR>', { desc = 'Signature help' })
      vim.keymap.set('n', 'gp', '<cmd>Lspsaga peek_definition<CR>', { desc = '[G]o [P]eek definition' })
    end,
    dependencies = { 'nvim-treesitter/nvim-treesitter' },
    after = 'nvim-lspconfig',
  },
}
