local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local make_entry = require('telescope.make_entry')
local conf = require('telescope.config').values
local M = {}


local search_live_grep = function(opts)
  opts = opts or {}
  opts.cwd = opts.cwd or vim.uv.cwd()
  local finder = finders.new_async_job {
    command_generator = function(prompt)
      if not prompt or prompt == '' then
        return nil
      end
      print(prompt)
      local pieces = vim.split(prompt, "  ")
      local args = vim.tbl_flatten { conf.vimgrep_arguments } --require('telescope').defaults.vimgrep_arguments
      local extra_args = {}
      if pieces[1] then
        table.insert(extra_args, '-e ' .. pieces[1])
      end
      if pieces[2] then
        table.insert(extra_args, '--include ' .. pieces[2])
        -- table.insert(extra_args, pieces[2])
      end
      -- print('hi')
      args = vim.tbl_flatten { args, extra_args }
      local len = #args
      local out = ''
      for i = 1, len do
        out = out .. ' ' .. args[i]
        -- print(i, args[i])
      end
      print(out)
      -- print(vim.tbl_flatten(args))
      -- return args
      return args
      --@diagnostic disable-next-line deprecated
      -- return vim.tbl_flatten {
      --   args
      --   --  { "--color=never", "--no-heading", "--with-filename", "--line-number", "--column", "--smartcase" }
      -- }
    end,
    entry_maker = make_entry.gen_from_vimgrep(opts),
    cwd = opts.cwd,
  }
  pickers.new(opts, {
    debounce = 200,
    prompt_title = 'Search live grep',
    finder = finder,
    previewer = conf.grep_previewer(opts),
    sorter = require('telescope.sorters').empty(),
  }):find()
end
M.livegrep = search_live_grep
-- search_live_grep()
return M
