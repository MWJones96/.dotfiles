return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  lazy = false,
  build = ":TSUpdate",
  config = function()
    -- "stable" is nvim-treesitter's own tier of well-maintained parsers —
    -- installing it covers all mainstream languages without hand-maintaining
    -- a list (main branch dropped configs.setup's ensure_installed/highlight/
    -- indent options; highlighting and indent are enabled below instead).
    require("nvim-treesitter").install { "stable" }

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "*",
      callback = function()
        pcall(vim.treesitter.start)
        pcall(function()
          vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
        end)
      end,
    })
  end,
}
