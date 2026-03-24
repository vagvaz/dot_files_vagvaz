return {
  "mfussenegger/nvim-lint",
  event = { "BufReadPre", "BufNewFile" },
  config = function()
    local lint = require("lint")

    -- Configure linters by filetype
    lint.linters_by_ft = {
      python = { "ruff", "mypy" },
      lua = { "luacheck" }, -- Uncomment after installing: luarocks install luacheck
    }

    -- Configure ruff to respect pyproject.toml
    lint.linters.ruff = {
      cmd = "ruff",
      stdin = false,
      args = { "check", "--output-format", "concise", "--quiet" },
      stream = "stdout",
      ignore_exitcode = true,
      parser = require("lint.parser").from_pattern(
        "([^:]+):(%d+):(%d+):(%d+):?(%d+)?:? ([^:]+): (.+)",
        { "file", "lnum", "col", "end_lnum", "end_col", "severity", "message" },
        {
          error = vim.diagnostic.severity.ERROR,
          warning = vim.diagnostic.severity.WARN,
          info = vim.diagnostic.severity.INFO,
          hint = vim.diagnostic.severity.HINT,
        },
        { source = "ruff" }
      ),
    }

    -- Configure mypy to respect pyproject.toml
    lint.linters.mypy = {
      cmd = "mypy",
      stdin = false,
      args = { "--show-column-numbers", "--show-error-end", "--no-error-summary" },
      stream = "stdout",
      ignore_exitcode = true,
      parser = require("lint.parser").from_pattern(
        "([^:]+):(%d+):(%d+): (%^?[^:]+): (.+)",
        { "file", "lnum", "col", "severity", "message" },
        {
          error = vim.diagnostic.severity.ERROR,
          warning = vim.diagnostic.severity.WARN,
          note = vim.diagnostic.severity.HINT,
        },
        { source = "mypy" }
      ),
    }

    -- Manual linting keymaps (no auto-lint on save)
    vim.keymap.set("n", "<leader>lr", function()
      lint.try_lint("ruff")
    end, { desc = "[L]SP [R]uff check" })

    vim.keymap.set("n", "<leader>lm", function()
      lint.try_lint("mypy")
    end, { desc = "[L]SP [M]ypy type check" })

    vim.keymap.set("n", "<leader>lA", function()
      lint.try_lint()
    end, { desc = "[L]SP Lint [A]ll" })

    -- Show available linters for current filetype
    vim.keymap.set("n", "<leader>ll", function()
      local filetype = vim.bo.filetype
      local linters = lint.linters_by_ft[filetype]
      if linters then
        print("Linters for " .. filetype .. ": " .. table.concat(linters, ", "))
      else
        print("No linters configured for " .. filetype)
      end
    end, { desc = "[L]SP [L]inters info" })
  end,
}
