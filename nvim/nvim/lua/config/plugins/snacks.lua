return {
  'folke/snacks.nvim',
  priority = 1000,
  lazy = false,
  opts = {
    bigfile = {
      enabled = true,
      size = 4 * 1024 * 1024,
    },
    dim = {
      enabled = true,
      config = function()
        Snacks.dim.disable()
      end
    },
    git = { enabled = true, },
    -- indent = { enabled = true },
    explorer = { enabled = true, replace_netrw = true },
    picker = { enabled = true },
    quickfile = { enabled = true },
    notifier = {
      enabled = true,
      timeout = 5000,
      top_down = true,
      config = function()
        vim.api.nvim_create_autocmd("LspProgress", {
          ---@param ev {data: {client_id: integer, params: lsp.ProgressParams}}
          callback = function(ev)
            local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
            vim.notify(vim.lsp.status(), "info", {
              id = "lsp_progress",
              title = "LSP Progress",
              opts = function(notif)
                notif.icon = ev.data.params.value.kind == "end" and " "
                    or spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
              end,
            })
          end,
        })
      end
    },
    rename = {
      vim.api.nvim_create_autocmd("User", {
        pattern = 'OilActionsPost',
        callback = function(event)
          if event.data.actions.type == 'move' then
            Snacks.rename.on_rename_file(event.data.actions.src_url, event.data.actions.dest_url)
          end
        end,
      })
    },
    statuscolumn = {},
    toggle = {},
    scratch = {
      win_by_ft = {
        py = {
          keys = {
            ['source'] = {
              '<cr>',
              function(self)
                local name = 'scratch.' .. vim.fn.fnamemodify(vim.api.nvim_buf_get_name(self.buf), ':e')
                local cmd = 'python3 ' .. name
              end,
              desc = 'Source buffer',
              mode = { 'n', 'x' },
            },
          },
        },
      },
    },
    input = { enabled = true },
    scope = { enabled = true },

  },

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
  keys = {
    { '<leader>ff',    function() Snacks.picker.files() end,                                  desc = 'Find Fines' },
    { '<leader>fg',    function() Snacks.picker.grep() end,                                   desc = 'Grep' },
    { '<leader>fnvim', function() Snacks.picker.grep({ cwd = vim.fn.stdpath('config') }) end, desc = 'Grep in neovim' },
    { '<leader>fb',    function() Snacks.picker.buffers() end,                                desc = 'Buffers' },
    { '<leader>fs',    function() Snacks.picker.smart() end,                                  desc = 'Smart Find Files' },
    { '<leader>fn',    function() Snacks.picker.notifications() end,                          desc = 'Notifications' },
    { '<leader>fh',    function() Snacks.picker.command_history() end,                        desc = 'Command History' },
    { '<leader>gg',    function() Snacks.picker.git_files() end,                              desc = "Find Git Files" },
    { '<leader>gbr',   function() Snacks.picker.git_branches() end,                           desc = 'Git branches' },
    { '<leader>gl',    function() Snacks.picker.git_log() end,                                desc = 'Git log' },
    { '<leader>gL',    function() Snacks.picker.git_log_line() end,                           desc = 'Git log line' },
    { '<leader>gs',    function() Snacks.picker.git_status() end,                             desc = 'Git Status' },
    { '<leader>gd',    function() Snacks.picker.git_diff() end,                               desc = 'Git Diff' },
    { '<leader>gbl',   function() Snacks.git.blame_line() end,                                desc = 'gib blame' },
    { '<leader>sl',    function() Snacks.picker.lines() end,                                  desc = 'buffer lines' },
    { '<leader>fB',    function() Snacks.picker.grep_buffers() end,                           desc = 'Grep Open Buffer' },
    { '<leader>fw',    function() Snacks.picker.grep_word() end,                              desc = 'Visual selection or wc' },
    { '<leader>sd',    function() Snacks.picker.diagnostics() end,                            desc = 'Diagnostics' },
    { '<leader>sD',    function() Snacks.picker.diagnostics_buffer() end,                     desc = 'Buffer diagnostics' },
    { '<leader>fk',    function() Snacks.picker.keymaps() end,                                desc = 'Keymaps' },
    { '<leader>ql',    function() Snacks.picker.qflist() end,                                 desc = 'Quickfix List' },
    { '<leader>gd',    function() Snacks.picker.lsp_definitions() end,                        desc = 'goto definition' },
    { '<leader>gD',    function() Snacks.picker.lsp_declarations() end,                       desc = 'got to declarations' },
    { '<leader>gr',    function() Snacks.picker.lsp_references() end,                         desc = ' Show references' },
    { '<leader>gI',    function() Snacks.picker.lsp_implementations() end,                    desc = 'goto implemtations' },
    { '<leader>ss',    function() Snacks.picker.lsp_symbols() end,                            desc = 'show symbols' },
    { '<leader>sS',    function() Snacks.picker.lsp_workspace_symbols() end,                  desc = 'Workspace symbols' },
    { '<leader>bD',    function() Snacks.bufdelete() end,                                     desc = 'Delete buffer' },
    { '<leader>bO',    function() Snacks.bufdelete.other() end,                               desc = 'Delete Other buffers' },
    { '<leader>td',    function() Snacks.toggle.dim() end,                                    desc = 'Dim Enable' },
    { '<leader>tD',    function() Snacks.toggle.disagnostics() end,                           desc = 'Dim Disable' },
    { '<leader>ti',    function() Snacks.toggle.inlay_hints() end,                            desc = 'toggle hints' },
    { '<leader>tl',    function() Snacks.toggle.line_number() end,                            desc = 'toggle line numbers' },
    { '<leader>term',  function() Snacks.terminal() end,                                      desc = 'Toggle Terminal' },
    { '<leader>rn',    function() Snacks.rename.rename_file() end,                            desc = 'LSP aware rename' },
    {
      '<leader>}',
      function()
        Snacks.scope.jump(
          {
            min_size = 1,
            bottom = true,
            cursor = false,
            edge = true,
            treesitter = { blocks = { enabled = false } },
            -- desc = 'jump to bottom edge of scope'
          }
        )
      end,
      desc = 'jump to bottom scope'
    },
    {
      '<leader>{',
      function()
        Snacks.scope.jump(
          {
            min_size = 1,
            bottom = false,
            cursor = false,
            edge = true,
            treesitter = { blocks = { enabled = false } },
            -- desc = 'jump to top edge of scope'
          }
        )
      end,
      desc = 'jump to top scope'
    },
    {
      '<leader>>',
      function()
        Snacks.scope.textobject(
          {
            min_size = 2,
            cursor = false,
            edge = false,
            treesitter = { blocks = { enabled = false } },
            -- desc = 'cw to top edge of scope'
          }
        )
      end,
      desc = 'inner scope'
    },
    {
      '<leader>[',
      function()
        Snacks.scope.textobject(
          {
            min_size = 2,
            cursor = false,
            treesitter = { blocks = { enabled = false } },
            -- desc = 'jump to full scope'
          }
        )
      end,
      desc = 'select to top scope'
    },
    { '<leader>vs', function() Snacks.scope.textobject() end, desc = 'Select scope' },
    {
      '<leader>bs',
      function()
        vim.ui.input({ prompt = 'entery filetype' }, function(input)
          Snacks.notify('Scratch for filetype=' .. input)
          Snacks.scratch({ ft = input })
        end
        )
      end,
      desc = 'toggle Scratch buffer'
    },
    { '<leader>bS', function() Snacks.scratch.select() end,   desc = 'Select Scratch Buffer' },
  },
}
