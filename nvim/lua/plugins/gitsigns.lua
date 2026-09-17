return {
  "lewis6991/gitsigns.nvim",
  lazy = false,
  opts = function()
    local opts = require "nvchad.configs.gitsigns"
    opts.current_line_blame = true
    opts.current_line_blame_opts = {
      virt_text_pos = "eol",
    }
    return opts
  end,
}
