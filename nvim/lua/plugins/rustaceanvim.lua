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
        on_attach = function(_, bufnr)
          vim.keymap.set("n", "<leader>ca", function()
            vim.cmd.RustLsp "codeAction"
          end, { desc = "Code Action", buffer = bufnr })
          vim.keymap.set("n", "<leader>dd", function()
            vim.cmd.RustLsp "debuggables"
          end, { desc = "Rust Debuggables", buffer = bufnr })
          vim.keymap.set("n", "<leader>dt", function()
            vim.cmd.RustLsp "testables"
          end, { desc = "Rust Testables", buffer = bufnr })
        end,
        default_settings = {
          ["rust-analyzer"] = {
            check = {
              command = "clippy",
              features = "all",
            },
            imports = {
              granularity = {
                enforce = true,
              },
            },
            inlayHints = {
              bindingModeHints = { enable = true },
              closingBraceHints = { enable = true },
              closureReturnTypeHints = { enable = "always" },
              discriminantHints = { enable = "always" },
              expressionAdjustmentHints = { enable = "always" },
              lifetimeElisionHints = { enable = "always" },
              reborrowHints = { enable = "always" },
              typeHints = { enable = true },
            },
          },
        },
      },
    }
  end,
}
