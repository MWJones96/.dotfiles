return {
  "nvim-treesitter/nvim-treesitter",
  dependencies = {
    "neovim-treesitter/treesitter-parser-registry",
  },
  build = ":TSUpdate",
  config = function()
    local configs = require "nvim-treesitter"

    configs.setup {
      ensure_installed = { "lua", "vim", "vimdoc", "rust", "python" },
      highlight = { enable = true },
      indent = { enable = true },
    }
  end,
}
