return {
  {
    'ThePrimeagen/harpoon',
    branch = 'harpoon2',
    dependencies = { 'nvim-lua/plenary.nvim' },
    config = function()
      local harpoon = require 'harpoon'
      harpoon:setup {}

      vim.keymap.set('n', '<leader>a', function()
        harpoon:list():add()
      end, { desc = 'Harpoon add file to quick list' })

      vim.keymap.set('n', '<leader>cc', function()
        harpoon:list():clear()
      end, { desc = 'Harpoon clear all' })
      vim.keymap.set('n', '<leader>ci', function()
        local idx = vim.fn.line '.'
        local item = harpoon:list():get(idx)
        harpoon:list():remove(item)
        harpoon.ui:toggle_quick_menu(harpoon:list())
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end, { desc = 'Harpoon delete selected item' })

      vim.keymap.set('n', '<leader>n', function()
        harpoon.ui:toggle_quick_menu(harpoon:list())
      end)

      -- vim.keymap.set('n', '<leader>ch', function()
      --   harpoon:list():select(1)
      -- end)
      -- vim.keymap.set('n', '<leader>ct', function()
      --   harpoon:list():select(2)
      -- end)
      -- vim.keymap.set('n', '<leader>cn', function()
      --   harpoon:list():select(3)
      -- end)
      -- vim.keymap.set('n', '<leader>cs', function()
      --   harpoon:list():select(4)
      -- end)

      -- Toggle previous & next buffers stored within Harpoon list
      vim.keymap.set('n', '<C-S-P>', function()
        harpoon:list():prev()
      end)
      vim.keymap.set('n', '<C-S-N>', function()
        harpoon:list():next()
      end)

      local conf = require('telescope.config').values
      local function toggle_telescope(harpoon_files)
        local file_paths = {}
        for _, item in ipairs(harpoon_files.items) do
          table.insert(file_paths, item.value)
        end

        require('telescope.pickers')
            .new({}, {
              prompt_title = 'Harpoon',
              finder = require('telescope.finders').new_table {
                results = file_paths,
              },
              previewer = conf.file_previewer {},
              sorter = conf.generic_sorter {},
            })
            :find()
      end

      vim.keymap.set('n', '<leader>sh', function()
        toggle_telescope(harpoon:list())
      end, { desc = ' OPen harpoon window' })
    end,
  },
}
