return {
  'milanglacier/minuet-ai.nvim',
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    -- Helper function to strip markdown code blocks
    local function strip_markdown(text)
      if not text or type(text) ~= 'string' then return text end
      -- Remove opening markdown fence with language (e.g., ```python) at start
      text = text:gsub('^%s*```[%w_]+%s*\n?', '')
      -- Remove opening markdown fence without language (just ```)
      text = text:gsub('^%s*```%s*\n?', '')
      -- Remove any leading newlines
      text = text:gsub('^\n+', '')
      -- Remove closing markdown fence
      text = text:gsub('\n?%s*```%s*$', '')
      -- Remove any inline markdown fences
      text = text:gsub('```[%w_]*\n?', '')
      text = text:gsub('\n?```', '')
      return text
    end

    -- Monkey-patch the utils.remove_spaces function to also strip markdown
    local utils = require('minuet.utils')
    local original_remove_spaces = utils.remove_spaces
    utils.remove_spaces = function(items, keep_leading_newline)
      -- First apply original processing
      items = original_remove_spaces(items, keep_leading_newline)
      -- Then strip markdown from each item
      for i, item in ipairs(items) do
        if type(item) == 'string' then
          items[i] = strip_markdown(item)
        end
      end
      return items
    end

    -- Also patch remove_spaces_single
    local original_remove_spaces_single = utils.remove_spaces_single
    utils.remove_spaces_single = function(item, keep_leading_newline)
      item = original_remove_spaces_single(item, keep_leading_newline)
      if type(item) == 'string' then
        item = strip_markdown(item)
      end
      return item
    end

    require('minuet').setup({
      provider = 'openai_compatible',
      provider_options = {
        openai_compatible = {
          name = 'Ollama',
          end_point = 'http://localhost:11234/v1/chat/completions',
          api_key = 'TERM',
          model = 'qwen3-coder-next',
          timeout = 120000,
          options = { temperature = 0.2, num_predict = 256 },
        },
      },
      virtualtext = {
        auto_trigger_ft = { 'python', 'lua', 'javascript', 'typescript', 'rust', 'go', 'cpp', 'c', 'java', 'bash', 'sh' },
        keymap = {
          accept = '<C-y>',
          accept_line = '<C-l>',
          next = '<C-n>',
          prev = '<C-p>',
          dismiss = '<C-e>',
        },
      },
      throttle = 1000,
      debounce = 400,
      notify = 'error',
    })
  end,
}
