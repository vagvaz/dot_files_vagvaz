return {
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      { 'saghen/blink.cmp' },
        {
          "folke/lazydev.nvim",
          ft = "lua",
          opts = {
            library = {
              { path = vim.fs.joinpath(vim.fn.stdpath("data"), "lazy", "lua-lsp", "library"), words = { "vim%.uv" } },
            },
            enabled = function()
              return vim.g.lazydev_enabled == nil and true or vim.g.lazydev_enabled
            end,
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
          
          if client and client:supports_method(vim.lsp.protocol.Methods.textDocument_signatureHelp) then
            vim.keymap.set('i', '<C-s>', vim.lsp.buf.signature_help, { desc = 'Signature Help' })
            
            vim.api.nvim_create_autocmd("InsertCharPre", {
              buffer = event.buf,
              callback = function()
                local char = vim.v.char
                if char == "(" or char == "," then
                  vim.defer_fn(function()
                    vim.lsp.buf.signature_help()
                  end, 100)
                end
              end,
            })
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
            
            if client and client.server_capabilities.semanticTokensProvider then
              vim.lsp.semantic_tokens.start(event.buf, client.id)
            end
          end,
       })
      
        vim.lsp.config = vim.lsp.config or {}
        vim.hl.priorities.semantic_tokens = 75
        vim.cmd([=[
          hi def link @lsp.type.class         Structure
          hi def link @lsp.type.function      Function
          hi def link @lsp.type.method        Function
          hi def link @lsp.type.parameter     Identifier
          hi def link @lsp.type.variable      Identifier
          hi def link @lsp.type.property      Identifier
          hi def link @lsp.type.enumMember    Number
          hi def link @lsp.type.enum          Enum
          hi def link @lsp.type.interface     Structure
        ]=])
        
        local project_dir = "/home/vagvaz/Projects/dot_files_vagvaz/nvim/nvim"
        package.path = project_dir .. "/lua/?.lua;" .. project_dir .. "/?/init.lua;" .. package.path
        
        local servers = {
          'lua_ls',
          'pylsp', 
          'clangd',
          'basedpyright',
          'ruff',
        }
       
         for _, server in ipairs(servers) do
           local ok, config = pcall(require, 'lsp.' .. server)
           if ok then
             vim.lsp.config[server] = config
           end
         end
       
        local function has_executable(exe)
          local f = io.popen('command -v ' .. exe .. ' >/dev/null 2>&1 && echo 1 || echo 0')
          local result = f:read('*a'):gsub('%s', '')
          f:close()
          return result ~= '0'
        end
       
        local function has_basedpyright()
          if has_executable('basedpyright-langserver') then return true end
          local cfg = vim.lsp.config.basedpyright
          if cfg and cfg.cmd then
            for _, cmd in ipairs(cfg.cmd) do
              if cmd:find('basedpyright') then return true end
            end
          end
          return false
        end
       
       local function has_executable(exe)
         local f = io.popen('command -v ' .. exe .. ' >/dev/null 2>&1 && echo 1 || echo 0')
         local result = f:read('*a'):gsub('%s', '')
         f:close()
         return result ~= '0'
       end
       
       vim.api.nvim_create_autocmd('FileType', {
         pattern = { 'python', 'lua', 'c', 'cpp', 'objc', 'objcpp' },
         callback = function(args)
           local ft = args.match
           local servers_to_start = {}
           
            if ft == 'python' then
              if has_basedpyright() then
                servers_to_start = { 'basedpyright' }
              else
                servers_to_start = { 'pylsp' }
              end
              table.insert(servers_to_start, 'ruff')
           elseif ft == 'lua' then
             servers_to_start = { 'lua_ls' }
           elseif ft == 'c' or ft == 'cpp' or ft == 'objc' or ft == 'objcpp' then
             servers_to_start = { 'clangd' }
           end
           
           for _, server_name in ipairs(servers_to_start) do
             local config = vim.lsp.config[server_name]
             if config then
               local clients = vim.lsp.get_clients({ bufnr = args.buf, name = server_name })
               if #clients == 0 then
                 local root_dir = vim.fn.getcwd()
                 if config.root_markers then
                   local bufname = vim.api.nvim_buf_get_name(args.buf)
                   local util = require('lspconfig.util')
                   for _, marker in ipairs(config.root_markers) do
                     local root = util.root_pattern(marker)(bufname)
                     if root then
                       root_dir = root
                       break
                     end
                   end
                 end
                 
                 vim.lsp.start(vim.tbl_extend('force', config, {
                   root_dir = root_dir,
                 }), { bufnr = args.buf })
               end
             end
           end
         end,
       })
    end,

  },
  {
    "linux-cultist/venv-selector.nvim",
    dependencies = {
      "neovim/nvim-lspconfig",
    },
    ft = "python",
    keys = {
      { ",v", "<cmd>VenvSelect<cr>" },
    },
    opts = {
      search = {},
      options = {},
    },
  }
}
