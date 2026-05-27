require("nvchad.configs.lspconfig").defaults()

local lspconfig = require "lspconfig"
local nvim_lsp = require "nvchad.configs.lspconfig"

local servers = { "html", "cssls", "rust_analyzer" }

for _, lsp in ipairs(servers) do
  lspconfig[lsp].setup {
    on_attach = nvim_lsp.on_attach,
    on_init = nvim_lsp.on_init,
    capabilities = nvim_lsp.capabilities,
  }
end
