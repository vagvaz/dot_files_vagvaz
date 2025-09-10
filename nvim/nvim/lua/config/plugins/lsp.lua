return
{
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "williamboman/mason.nvim",
        config = true,
      },
      {
        "williamboman/mason-lspconfig.nvim",
      },
      {
        'WhoIsSethDaniel/mason-tool-installer.nvim'
      },
      { 'saghen/blink.cmp' },
      {
        "folke/lazydev.nvim",
        ft = "lua", -- only load on lua files
        opts = {
          library = {
            -- Library paths can be absolute
            -- "~/projects/my-awesome-lib",
            -- Or relative, which means they will be resolved from the plugin dir.
            -- "lazy.nvim",
            -- It can also be a table with trigger words / mods
            -- Only load luvit types when the `vim.uv` word is found
            { path = "${3rd}/luv/library", words = { "vim%.uv" } },
            -- always load the LazyVim library
            -- "LazyVim",
            -- Only load the lazyvim library when the `LazyVim` global is found
            -- { path = "LazyVim", words = { "LazyVim" } },
            -- Load the wezterm types when the `wezterm` module is required
            -- Needs `justinsgithub/wezterm-types` to be installed
            -- { path = "wezterm-types", mods = { "wezterm" } },
            -- Load the xmake types when opening file named `xmake.lua`
            -- Needs `LelouchHe/xmake-luals-addon` to be installed
            -- { path = "xmake-luals-addon/library", files = { "xmake.lua" } },
          },
          -- always enable unless `vim.g.lazydev_enabled = false`
          -- This is the default
          -- enabled = function(root_dir)
          enabled = function()
            return vim.g.lazydev_enabled == nil and true or vim.g.lazydev_enabled
          end,
          -- disable when a .luarc.json file is found
          -- enabled = function(root_dir)
          --   return not vim.uv.fs_stat(root_dir .. "/.luarc.json")
          -- end,
        },
      },
    },
    config = function()
      vim.api.nvim_create_autocmd('LspAttach', {
        group = vim.api.nvim_create_augroup('lsp-attach', { clear = true }),
        callback = function(event)
          local client = vim.lsp.get_client_by_id(event.data.client_id)
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_documentHighlight) then
            local highlight_augroup = vim.api.nvim_create_augroup('lsp-highlight', { clear = false })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.document_highlight,
            })
            vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
              buffer = event.buf,
              group = highlight_augroup,
              callback = vim.lsp.buf.clear_references,
            })
            vim.api.nvim_create_autocmd('LspDetach', {
              group = vim.api.nvim_create_augroup('lsp-detach', { clear = true }),
              callback = function(inner_event)
                vim.lsp.buf.clear_references()
                vim.api.nvim_clear_autocmds { group = 'lsp-highlight', buffer = inner_event.buf }
              end,
            })
          end
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_inlayHint) then
            vim.keymap.set('n', '<leader>tih', function()
              vim.lsp.inlay_hint.enable(
                not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf })
            end, { desc = '[T]oggle [I]nlay [H]ints' })
          end
          if client and client:supports_method('textDocument/formatting') then
            if not client or client == 'clangd' then return end
            vim.api.nvim_create_autocmd('BufWritePre', {
              buffer = event.buf,
              callback = function()
                vim.lsp.buf.format({ bufnr = event.buf, id = client.id })
              end,
            })
          end
          local client_has_capability = function(client, capability)
            local resolved_capabilities = {
              codeLensProvider = 'code_len',
              documentFormattingProvider = 'document_formatting',
              documentRangeFormattingProvider = 'document_range_formatting',
            }
            if vim.fn.has 'nvim-0.8' == 1 then
              return client.server_capabilities[capability]
            else
              assert(resolved_capabilities[capability])
              capability = resolved_capabilities[capability]
              return client.resolved_capabilities[capability]
            end
          end

          if client and client_has_capability(client, 'codeLensProvider') then
            local augroup = vim.api.nvim_create_augroup('LSPCodeLens', { clear = true })
            vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI', 'InsertLeave' }, {
              group = augroup,
              buffer = vim.api.nvim_get_current_buf(),
              callback = function()
                vim.lsp.codelens.refresh()
              end,
              desc = 'Refresh codelens',
            })

            vim.keymap.set('n', '<leader>lL', '<cmd>lua vim.lsp.codelens.run()<CR>', { desc = '[LSP] code lens' })
          end

          vim.keymap.set('n', '<leader>cf', function() vim.lsp.buf.format() end, { desc = '[F]ormat file' })
          vim.keymap.set('n', '<leader>;', function() vim.lsp.buf.code_action() end, { desc = '[C]ode [A]ction' })
        end,
      }) -- end of LspAttach
      -- vim.api.nvim_create_autocmd('LspAttach', {
      --   callback = function(args)
      --     local client = vim.lsp.get_client_by_id(args.data.client_id):
      -- setup servers
      -- local capabilities =
      require('mason').setup {}
      require('mason-lspconfig').setup {
        automatic_installation = false,
        automatic_enable = false,
      }
    end,

  },
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
      -- { "nvim-telescope/telescope.nvim", branch = "0.1.x", dependencies = { "nvim-lua/plenary.nvim" } }, -- optional: you can also use fzf-lua, snacks, mini-pick instead.
    },
    ft = "python",                     -- Load when opening Python files
    keys = {
      { ",v", "<cmd>VenvSelect<cr>" }, -- Open picker on keymap
    },
    opts = {                           -- this can be an empty lua table - just showing below for clarity.
      search = {},                     -- if you add your own searches, they go here.
      options = {}                     -- if you add plugin options, they go here.
    },
  }
}
