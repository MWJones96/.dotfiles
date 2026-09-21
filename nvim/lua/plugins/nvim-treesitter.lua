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

    -- "stable" resolves and downloads in the background, and in practice it
    -- had not delivered cpp, cmake or rust here at all: the parser directory
    -- held ten unrelated languages. C only looked fine because Neovim bundles
    -- c (along with lua, markdown, query, vim and vimdoc), so the gap stayed
    -- invisible until a C++ buffer had no highlighting or indent. Name the
    -- languages this config gives an LSP, debugger or test runner to instead
    -- of waiting on the group to get to them.
    require("nvim-treesitter").install {
      "c",
      "cpp",
      "cmake",
      "c_sharp",
      "python",
      "rust",
      "lua",
      "bash",
      "json",
      "yaml",
      "toml",
      "markdown",
    }

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
