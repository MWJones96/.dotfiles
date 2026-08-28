return {
  "mrcjkb/rustaceanvim",
  version = "^5",
  -- rustaceanvim is a Neovim *filetype plugin* (ftplugin/rust.lua), not a
  -- plugin lazy.nvim calls config() on when a trigger fires. Neovim only
  -- sources ftplugin/<ft>.lua if the plugin is already on 'runtimepath' at
  -- the moment a buffer's filetype is set — deferring that via lazy.nvim's
  -- own `ft` key risks a race where Neovim's one-shot ftplugin scan already
  -- ran and never picks it up. `lazy = false` is rustaceanvim's own
  -- documented required setting for exactly this reason ("this plugin is
  -- already lazy" — the actual work still only runs per Rust buffer).
  lazy = false,
  config = function()
    local mason_root = vim.fn.stdpath "data" .. "/mason"
    local codelldb_path = mason_root .. "/packages/codelldb/extension/adapter/codelldb"
    local codelldb_lib_ext = (jit.os == "Linux") and ".so" or ".dylib"
    local liblldb_path = mason_root .. "/packages/codelldb/extension/lldb/lib/liblldb" .. codelldb_lib_ext
    local cfg = require "rustaceanvim.config"
    local nvim_lsp = require "nvchad.configs.lspconfig"

    vim.g.rustaceanvim = {
      dap = {
        adapter = cfg.get_codelldb_adapter(codelldb_path, liblldb_path),
      },
      server = {
        -- Reuse the same on_attach as every other LSP in this config (gd,
        -- gD, rename, workspace-folder maps) so Rust isn't the one language
        -- that behaves differently.
        on_attach = nvim_lsp.on_attach,
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
    }

    -- Runs `cargo test --workspace` through rustaceanvim's own terminal
    -- executor (the same backend it uses for "all targets" runs), rather
    -- than a disconnected `:terminal` split — keeps output UI consistent
    -- with every other run/debug/test action. rust-analyzer's per-file
    -- runnables aren't reliably workspace-scoped, so this is a dedicated
    -- path rather than relying on the runnables picker for this.
    local function run_all_tests()
      local clients = vim.lsp.get_clients { bufnr = 0, name = "rust-analyzer" }
      local cwd = (clients[1] and clients[1].config.root_dir) or vim.fn.getcwd()
      require("rustaceanvim.executors").termopen.execute_command("cargo", { "test", "--workspace" }, cwd)
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "rust",
      callback = function(args)
        local map = vim.keymap.set
        local function opts(desc)
          return { buffer = args.buf, desc = "Rust " .. desc }
        end

        map("n", "K", function() vim.cmd.RustLsp("hover", "actions") end, opts "hover actions")
        map("n", "<leader>ca", function() vim.cmd.RustLsp "codeAction" end, opts "code action")

        -- lowercase: act on whatever's under the cursor immediately, no picker
        map("n", "<leader>rr", function() vim.cmd.RustLsp "run" end, opts "run at cursor")
        map("n", "<leader>rd", function() vim.cmd.RustLsp "debug" end, opts "debug at cursor")

        -- uppercase: browse/pick, or act project-wide
        map("n", "<leader>rR", function() vim.cmd.RustLsp "runnables" end, opts "runnables")
        map("n", "<leader>rD", function() vim.cmd.RustLsp "debuggables" end, opts "debuggables")
        map("n", "<leader>rt", function() vim.cmd.RustLsp "testables" end, opts "testables (current file)")
        map("n", "<leader>rT", run_all_tests, opts "run all tests in project")

        map("n", "<leader>re", function() vim.cmd.RustLsp "expandMacro" end, opts "expand macro")
        map("n", "<leader>rc", function() vim.cmd.RustLsp "openCargo" end, opts "open Cargo.toml")
        map("n", "<leader>rp", function() vim.cmd.RustLsp "parentModule" end, opts "parent module")
        map("n", "<leader>rE", function() vim.cmd.RustLsp "renderDiagnostic" end, opts "render diagnostic")
      end,
    })
  end,
}
