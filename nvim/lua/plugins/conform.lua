return {
  "stevearc/conform.nvim",
  lazy = false,
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      css = { "prettier" },
      html = { "prettier" },
      rust = { "rustfmt" },
      -- fix lint issues, sort imports, then format — ruff's own recommended order
      python = { "ruff_fix", "ruff_organize_imports", "ruff_format" },
    },

    format_on_save = {
      timeout_ms = 500,
      lsp_fallback = true,
    },
  },
}
