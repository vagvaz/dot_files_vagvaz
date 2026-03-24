return {
  "rachartier/tiny-inline-diagnostic.nvim",
  event = "LspAttach",
  priority = 1000,
  config = function()
    require("tiny-inline-diagnostic").setup({
      -- Use modern preset for nice styling
      preset = "modern",
      -- Show diagnostics with icons and arrows
      hi = {
        error = "DiagnosticError",
        warn = "DiagnosticWarn",
        info = "DiagnosticInfo",
        hint = "DiagnosticHint",
        arrow = "NonText",
        background = "CursorLine",
        mixing_color = "None",
      },
      -- Show diagnostic on the line where the error is
      options = {
        -- Show multiple diagnostics per line
        multiple_diagonistics_under_cursor = true,
        -- Show all diagnostics on the line
        show_all_diags_on_cursorline = false,
        -- Format diagnostics
        format = nil,
        -- Overflow handling
        overflow = {
          -- Mode: "wrap" or "none"
          mode = "wrap",
        },
        -- Break line after character
        break_line = {
          enabled = false,
          after = 30,
        },
        -- Show virtual text
        virt_texts = {
          priority = 2048,
        },
        -- Disable diagnostics in insert mode
        disable_diagnostic_under_cursor = false,
        -- Enable diagnostic signs
        enable_diag_signs = true,
      },
    })

    -- Disable native virtual text to avoid duplicates
    vim.diagnostic.config({
      virtual_text = false,
      underline = true,
      update_in_insert = false,
      severity_sort = true,
    })

    -- Toggle diagnostics on/off
    vim.keymap.set("n", "<leader>ud", function()
      local is_enabled = vim.diagnostic.is_enabled()
      vim.diagnostic.enable(not is_enabled)
      if is_enabled then
        print("Diagnostics disabled")
      else
        print("Diagnostics enabled")
      end
    end, { desc = "[U]I Toggle [D]iagnostics" })

    -- Toggle between inline and native virtual text
    local use_inline = true
    vim.keymap.set("n", "<leader>uD", function()
      use_inline = not use_inline
      if use_inline then
        vim.diagnostic.config({ virtual_text = false })
        require("tiny-inline-diagnostic").toggle_enable()
        print("Using inline diagnostics")
      else
        require("tiny-inline-diagnostic").toggle_disable()
        vim.diagnostic.config({
          virtual_text = {
            spacing = 4,
            source = "if_many",
            prefix = "●",
          },
        })
        print("Using native virtual text diagnostics")
      end
    end, { desc = "[U]I Toggle [D]iagnostics style" })
  end,
}
