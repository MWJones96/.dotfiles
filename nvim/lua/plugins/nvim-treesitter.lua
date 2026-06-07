return {
  "nvim-treesitter/nvim-treesitter",
  -- Add the dependencies block below:
  dependencies = {
    "neovim-treesitter/treesitter-parser-registry",
  },
  build = ":TSUpdate",
  config = function()
    local configs = require "nvim-treesitter"

    configs.setup {
      -- Your existing treesitter setup options here
      ensure_installed = { "lua", "vim", "vimdoc", "rust", "python" },
      highlight = { enable = true },
      indent = { enable = true },
    }
  end,
}
