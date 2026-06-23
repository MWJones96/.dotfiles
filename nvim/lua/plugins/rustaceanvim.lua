return {
  "mrcjkb/rustaceanvim",
  version = "^5",
  lazy = false,
  ft = "rust",
  config = function()
    local install_path = require("mason.settings").current.install_root_dir .. "/packages/codelldb"
    local extension_path = install_path .. "/extension"
    local codelldb_path = extension_path .. "/adapter/codelldb"
    local codelldb_lib_ext = (jit.os == "Linux") and ".so" or ".dylib"
    local liblldb_path = extension_path .. "/lldb/lib/liblldb" .. codelldb_lib_ext
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
              extraArgs = { "--", "-W", "clippy::pedantic", "-W", "clippy::nursery" },
              features = "all",
            },
            imports = {
              granularity = {
                enforce = true,
              },
            },
            inlayHints = {
              inlayHints = {
                bindingModeHints = { enable = false },
                closingBraceHints = { minLines = 10 },
                closureReturnTypeHints = { enable = "always" },
                discriminantHints = { enable = "always" },
                expressionAdjustmentHints = { enable = "never" },
                lifetimeElisionHints = { enable = "skip_trivial" },
                reborrowHints = { enable = "never" },
                typeHints = { enable = true },
              },
            },
          },
        },
      },
    }
  end,
}
