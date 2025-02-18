local feedkey = require('utils').feedkey

local check_back_space = function()
  local col = vim.fn.col '.' - 1
  return col == 0 or vim.fn.getline('.'):sub(col, col):match '%s'
end

local keymap = function(mode, lhs, rhs, opts)
  opts = vim.tbl_extend('keep', opts, { silent = true, buffer = true })
  vim.keymap.set(mode, lhs, rhs, opts)
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

local lsp_on_attach = function(client, bufnr)
  local cmp_ok, cmp = pcall(require, 'cmp')
  local snippy_ok, snippy = pcall(require, 'snippy')

  if cmp_ok and snippy_ok then
    cmp.setup {
      completion = {
        keyword_length = 2,
      },

      snippet = {
        expand = function(args)
          snippy.expand_snippet(args.body)
        end,
      },

      -- sorting defines the priority
      sources = {
        { name = 'nvim_lua' },
        { name = 'nvim_lsp' },
        { name = 'snippy' },
        { name = 'path' },
        { name = 'buffer', keyword_length = 5 },
      },

      formatting = {
        format = require('lsp.icons').cmp_format {
          menu = {
            nvim_lua = '[api]',
            nvim_lsp = '[lsp]',
            snippy = '[snip]',
            path = '[path]',
            buffer = '[buf]',
          },
        },
      },

      experimental = {
        ghost_text = true,
      },

      mapping = {
        ['<Tab>'] = function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif snippy.can_expand_or_advance() then
            snippy.expand_or_advance()
          elseif not check_back_space() then
            cmp.complete()
          else
            fallback()
          end
        end,
        ['<S-Tab>'] = function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif snippy.can_jump(-1) then
            snippy.previous()
          else
            fallback()
          end
        end,
        ['<Down>'] = cmp.mapping(
          cmp.mapping.select_next_item {
            behavior = cmp.SelectBehavior.Select,
          },
          { 'i' }
        ),
        ['<Up>'] = cmp.mapping(
          cmp.mapping.select_prev_item {
            behavior = cmp.SelectBehavior.Select,
          },
          { 'i' }
        ),
        ['<C-n>'] = cmp.mapping {
          c = function()
            if cmp.visible() then
              cmp.select_next_item {
                behavior = cmp.SelectBehavior.Select,
              }
            else
              feedkey 'Down'
            end
          end,
          i = function(fallback)
            if cmp.visible() then
              cmp.select_next_item {
                behavior = cmp.SelectBehavior.Select,
              }
            else
              fallback()
            end
          end,
        },
        ['<C-p>'] = cmp.mapping {
          c = function()
            if cmp.visible() then
              cmp.select_prev_item {
                behavior = cmp.SelectBehavior.Select,
              }
            else
              feedkey '<Up>'
            end
          end,
          i = function(fallback)
            if cmp.visible() then
              cmp.select_prev_item {
                behavior = cmp.SelectBehavior.Select,
              }
            else
              fallback()
            end
          end,
        },
        ['<C-d>'] = cmp.mapping.scroll_docs(-4),
        ['<C-f>'] = cmp.mapping.scroll_docs(4),
        ['<C-Space>'] = cmp.mapping.complete(),
        ['<C-e>'] = cmp.mapping.close(),
        ['<CR>'] = cmp.mapping.confirm {
          behavior = cmp.ConfirmBehavior.Replace,
          select = true,
        },
      },
    }
  end

  vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')

  if client.config.flags then
    client.config.flags.allow_incremental_sync = true
    client.config.flags.debounce_text_changes = 100
  end

  keymap('i', '<a-j>', [[<Plug>(completion_next_source)]], { desc = 'next completion source [LSP]' })
  keymap('s', '<a-j>', [[<Plug>(completion_next_source)]], { desc = 'next completion source [LSP]' })

  keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', { desc = 'goto definition [LSP]' })
  keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', { desc = 'goto declaration [LSP]' })
  keymap('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', { desc = 'goto references [LSP]' })
  keymap('n', 'gm', '<cmd>lua vim.lsp.buf.implementation()<CR>', { desc = 'goto implementation [LSP]' })
  keymap('n', '<leader>lT', '<cmd>lua vim.lsp.buf.type_definition()<CR>', { desc = 'goto type definition [LSP]' })
  keymap('n', '<leader>K', '<cmd>lua vim.lsp.buf.signature_help()<CR>', { desc = 'signature help [LSP]' })
  keymap('n', '<leader>k', '<cmd>lua require("lsp.handlers").peek_definition()<CR>', { desc = 'peek defintion [LSP]' })

  if pcall(require, 'conform') then
    keymap('n', '<leader>=', function()
      require('conform').format {
        bufnr = bufnr,
        lsp_fallback = true,
      }
    end, { desc = 'format buffer [LSP]' })
  else
    keymap('n', '<leader>=', function()
      vim.lsp.buf.format {
        timeout_ms = 2000,
        bufnr = bufnr,
      }
    end, { desc = 'format buffer [LSP]' })
  end

  if pcall(require, 'lspsaga') then
    keymap('n', '<leader>ca', function()
      require('lspsaga.codeaction'):code_action()
    end, { desc = 'code action [LSP]' })
    keymap('v', '<leader>ca', function()
      require('lspsaga.codeaction'):range_code_action()
    end, { desc = 'range code action [LSP]' })
    keymap('n', '<leader>ll', function()
      require('lspsaga.diagnostic.show'):show_diagnostics { line = true }
    end, { desc = 'show line diagnostic [LSP]' })
    keymap('n', '[d', function()
      require('lspsaga.diagnostic'):goto_prev()
    end, { desc = 'goto next diagnostic [LSP]' })
    keymap('n', ']d', function()
      require('lspsaga.diagnostic'):goto_next()
    end, { desc = 'goto next diagnostic [LSP]' })
    keymap('n', '<leader>lr', function()
      require('lspsaga.rename'):lsp_rename()
    end, { desc = 'rename [LSP]' })
    keymap('n', '<leader>lR', function()
      require('lspsaga.rename'):lsp_rename '++project'
    end, { desc = 'rename project [LSP]' })
    keymap('n', '<c-k>', function()
      require('lspsaga.hover'):render_hover_doc()
    end, { desc = 'hover information [LSP]' })
  else
    local winopts = "{ float =  { border = 'rounded' } }"
    keymap('n', '[d', ('<cmd>lua vim.diagnostic.goto_prev(%s)<CR>'):format(winopts), { desc = 'goto previous diagnostic [LSP]' })
    keymap('n', ']d', ('<cmd>lua vim.diagnostic.goto_next(%s)<CR>'):format(winopts), { desc = 'goto next diagnostic [LSP]' })
    keymap('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', { desc = 'code action [LSP]' })
    keymap('v', '<leader>ca', ':<C-U>lua vim.lsp.buf.range_code_action()<CR>', { desc = 'range code action [LSP]' })
    keymap('n', '<leader>ll', function()
      vim.diagnostic.open_float(0, { scope = 'line', border = 'rounded' })
    end, { desc = 'show line diagnostic [LSP]' })
    keymap('n', '<leader>lr', '<cmd>lua vim.lsp.buf.rename()<CR>', { desc = 'rename [LSP]' })
    keymap('n', '<c-k>', '<cmd>lua vim.lsp.buf.hover()<CR>', { desc = 'hover information [LSP]' })
  end

  -- already defined in our telescope mappings
  if not pcall(require, 'telescope') then
    keymap('n', '<leader>ls', '<cmd>lua vim.lsp.buf.document_symbol()<CR>', { desc = 'find symbol [telescope]' })
    keymap('n', '<leader>lS', '<cmd>lua vim.lsp.buf.workspace_symbol()<CR>', { desc = 'find symbol in workspace [telescope]' })
  end

  keymap('n', '<leader>lc', '<cmd>lua vim.diagnostic.reset()<CR>', { desc = 'reset diagnostic [LSP]' })
  keymap('n', '<leader>lq', '<cmd>lua vim.diagnostic.setqflist()<CR>', { desc = 'send diagnostics to quickfix [LSP]' })
  keymap('n', '<leader>lQ', '<cmd>lua vim.diagnostic.setloclist()<CR>', { desc = 'send diagnostics to loclist [LSP]' })
  keymap('n', '<leader>lt', "<cmd>lua require('lsp.diagnostics').toggle()<CR>", { desc = 'toggle virtual text [LSP]"' })

  if client_has_capability(client, 'codeLensProvider') then
    local augroup = vim.api.nvim_create_augroup('LSPCodeLens', { clear = true })
    vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI', 'InsertLeave' }, {
      group = augroup,
      buffer = vim.api.nvim_get_current_buf(),
      callback = function()
        vim.lsp.codelens.refresh()
      end,
      desc = 'Refresh codelens',
    })

    keymap('n', '<leader>lL', '<cmd>lua vim.lsp.codelens.run()<CR>', { desc = '[LSP] code lens' })
  end
end

return { on_attach = lsp_on_attach }
