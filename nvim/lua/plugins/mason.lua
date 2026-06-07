return {
  "williamboman/mason.nvim",
  opts = {
    ensure_installed = {
      "lua-language-server",
      "python-lsp-server",
      "stylua",
      "codelldb",
      "clangd",
    },
  },
}
