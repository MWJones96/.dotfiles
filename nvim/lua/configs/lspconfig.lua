local nvim_lsp = require "nvchad.configs.lspconfig"
local servers = { "html", "cssls"}

for _, lsp in ipairs(servers) do
  vim.lsp.config(lsp, {
    on_attach = nvim_lsp.on_attach,
    on_init = nvim_lsp.on_init,
    capabilities = nvim_lsp.capabilities,
  })

  vim.lsp.enable(lsp)
end
