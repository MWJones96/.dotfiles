return {
  "neovim/nvim-lspconfig",
  config = function()
    local nvim_lsp = require "nvchad.configs.lspconfig"

    -- lazy.nvim merges every spec for a given plugin and keeps one `config`,
    -- so this function *replaces* the one NvChad ships for nvim-lspconfig —
    -- which exists only to make this call. Without it nothing registers the
    -- global LspAttach autocmd behind gd/gD/<leader>ra, nothing sets
    -- vim.lsp.config("*") capabilities, NvChad's diagnostic styling is never
    -- applied, and lua_ls is never enabled despite Mason installing it. Only
    -- servers that pass on_attach by hand (the two below, and rustaceanvim)
    -- escaped that, which is why it went unnoticed.
    nvim_lsp.defaults()

    local servers = { "html", "cssls" }

    for _, lsp in ipairs(servers) do
      vim.lsp.config(lsp, {
        on_attach = nvim_lsp.on_attach,
        on_init = nvim_lsp.on_init,
        capabilities = nvim_lsp.capabilities,
      })

      vim.lsp.enable(lsp)
    end
  end,
}
