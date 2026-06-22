return {
  "mrcjkb/rustaceanvim",
  version = "^5",
  lazy = false,
  ft = "rust",
  config = function()
    local install_path = require("mason.settings").current.install_root_dir .. "/packages/codelldb"
    local extension_path = install_path .. "/extension"
    local codelldb_path = extension_path .. "/adapter/codelldb"
    local liblldb_path = extension_path .. "/lldb/lib/liblldb.so"
    local cfg = require "rustaceanvim.config"

    vim.g.rustaceanvim = {
      dap = {
        adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
      },
      server = {
        default_settings = {
          ["rust-analyzer"] = {
            check = {
              command = "clippy",
            },
          },
        },
      },
    }
  end,
}
