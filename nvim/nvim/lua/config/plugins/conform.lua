return {
  "stevearc/conform.nvim",
  event = { "BufReadPre", "BufNewFile" },
  cmd = { "ConformInfo" },
  config = function()
    require("conform").setup({
      formatters_by_ft = {
        python = { "ruff_fix", "ruff_format" },
        lua = { "stylua" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        json = { "jq" },
        yaml = { "yamlfmt" },
        markdown = { "prettier" },
      },
      -- Manual formatting only (no auto-format on save)
      format_on_save = false,
      -- Show notification on format
      notify_on_error = true,
      -- Formatters configuration (respects pyproject.toml automatically)
      formatters = {
        ruff_format = {
          -- ruff automatically reads pyproject.toml
          prepend_args = {},
        },
        ruff_fix = {
          -- ruff automatically reads pyproject.toml
          prepend_args = {},
        },
      },
    })

    -- Format with conform (uses ruff)
    vim.keymap.set("n", "<leader>lf", function()
      require("conform").format({ lsp_fallback = true })
    end, { desc = "[L]SP [F]ormat (ruff)" })

    -- Format with LSP only (fallback)
    vim.keymap.set("n", "<leader>lF", function()
      vim.lsp.buf.format()
    end, { desc = "[L]SP [F]ormat (LSP only)" })

    -- Show conform info
    vim.keymap.set("n", "<leader>li", "<cmd>ConformInfo<CR>", { desc = "[L]SP conform [I]nfo" })
  end,
}
