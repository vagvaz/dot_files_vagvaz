return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      {
        "williamboman/mason.nvim",
        config = true,
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
          --vim.keymap.set('n', '<leader>;', function() vim.lsp.buf.code_action() end, { desc = '[C]ode [A]ction' })
        end,
      }) -- end of LspAttach
      -- Setup LSP servers for specific filetypes
      vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('LspAutoStart', { clear = true }),
        pattern = { 'python', 'c', 'cpp', 'objc', 'objcpp', 'cuda', 'proto', 'lua' },
        callback = function(args)
          local filetype = args.match
          local server_to_start = nil
          
          if filetype == 'python' then
            server_to_start = 'pylsp'
          elseif filetype == 'c' or filetype == 'cpp' or filetype == 'objc' or filetype == 'objcpp' or filetype == 'cuda' or filetype == 'proto' then
            server_to_start = 'clangd'
          elseif filetype == 'lua' then
            server_to_start = 'lua_ls'
          end
          
          if server_to_start then
            local clients = vim.lsp.get_clients({ bufnr = args.buf })
            local server_running = false
            for _, client in ipairs(clients) do
              if client.name == server_to_start then
                server_running = true
                break
              end
            end
            
            if not server_running then
              vim.lsp.start({
                name = server_to_start,
                cmd = vim.lsp.config[server_to_start].cmd,
                filetypes = vim.lsp.config[server_to_start].filetypes,
                root_dir = vim.lsp.config[server_to_start].root_dir or vim.fn.getcwd(),
                capabilities = vim.lsp.config[server_to_start].capabilities,
                settings = vim.lsp.config[server_to_start].settings,
              })
            end
          end
        end,
      })
      
      require('mason').setup {}
      
      local function file_exists(path)
        return vim.uv.fs_stat(path) ~= nil
      end
      
      local function find_root_with_marker(start_path, marker)
        local path = vim.fn.fnamemodify(start_path, ':p:h')
        while path and path ~= '/' do
          if file_exists(path .. '/' .. marker) then
            return path
          end
          local parent = vim.fn.fnamemodify(path, ':h')
          if parent == path then
            break
          end
          path = parent
        end
        return nil
      end
      
      local function is_lsp_running(server_name)
        local clients = vim.lsp.get_clients()
        for _, client in ipairs(clients) do
          if client.name == server_name then
            return true
          end
        end
        return false
      end
      
      local function start_lsp_if_configured(server_name, bufnr)
        if not vim.lsp.config[server_name] then
          return
        end
        
        if is_lsp_running(server_name) then
          return
        end
        
        local config = vim.lsp.config[server_name]
        local root_dir = vim.fn.getcwd()
        
        if config.root_dir then
          root_dir = config.root_dir(vim.fn.expand('%:p'))
        end
        
        vim.lsp.start({
          name = server_name,
          cmd = config.cmd,
          filetypes = config.filetypes,
          root_dir = root_dir,
          capabilities = config.capabilities,
          settings = config.settings,
        })
      end
      
      vim.api.nvim_create_autocmd('BufEnter', {
        group = vim.api.nvim_create_augroup('LspProjectDetection', { clear = true }),
        callback = function(args)
          local bufname = vim.fn.expand('%:p')
          if bufname == '' then
            return
          end
          
          local has_cmake = find_root_with_marker(bufname, 'CMakeLists.txt')
          if has_cmake then
            start_lsp_if_configured('clangd', args.buf)
            start_lsp_if_configured('cmake-language-server', args.buf)
          end
          
          local has_pyproject = find_root_with_marker(bufname, 'pyproject.toml')
          if has_pyproject then
            start_lsp_if_configured('pylsp', args.buf)
          end
        end,
      })
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
