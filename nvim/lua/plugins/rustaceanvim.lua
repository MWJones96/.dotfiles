local function keymaps(buf)
  local map = vim.keymap.set
  local function opts(desc)
    return { buffer = buf, desc = "Rust " .. desc }
  end
  local function neotest()
    return require "neotest"
  end
  local function rust(...)
    local args = { ... }
    return function()
      vim.cmd.RustLsp(args)
    end
  end

  map("n", "K", rust("hover", "actions"), opts "hover actions")
  map("n", "<leader>ca", rust "codeAction", opts "code action")

  map("n", "<leader>rr", function()
    neotest().run.run()
  end, opts "run nearest test")
  map("n", "<leader>rd", rust "debug", opts "debug at cursor")
  map("n", "<leader>rt", function()
    neotest().run.run(vim.fn.expand "%")
  end, opts "run tests in this file")
  map("n", "<leader>rT", function()
    neotest().run.run(vim.uv.cwd())
  end, opts "run the whole test suite")
  map("n", "<leader>rl", function()
    neotest().run.run_last()
  end, opts "re-run last test")
  map("n", "<leader>rx", function()
    neotest().run.stop()
  end, opts "stop the running test")
  map("n", "<leader>rs", function()
    neotest().summary.toggle()
  end, opts "toggle test summary")
  map("n", "<leader>ro", function()
    neotest().output.open { enter = true, auto_close = true }
  end, opts "test output")
  map("n", "<leader>rO", function()
    neotest().output_panel.toggle()
  end, opts "toggle output panel")

  map("n", "<leader>ru", rust "run", opts "run at cursor")
  map("n", "<leader>rU", rust "runnables", opts "runnables")
  map("n", "<leader>rD", rust "debuggables", opts "debuggables")

  map("n", "<leader>re", rust "expandMacro", opts "expand macro")
  map("n", "<leader>rc", rust "openCargo", opts "open Cargo.toml")
  map("n", "<leader>rp", rust "parentModule", opts "parent module")
  map("n", "<leader>rE", rust "renderDiagnostic", opts "render diagnostic")
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "rust",
  callback = function(args)
    keymaps(args.buf)
  end,
})

return {
  {
    "mrcjkb/rustaceanvim",
    version = "^9",
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
      local nvim_lsp = require "nvchad.configs.lspconfig"

      vim.g.rustaceanvim = {
        tools = {
          test_executor = "neotest",
        },
        server = {
          -- Reuse the same on_attach as every other LSP in this config (gd,
          -- gD, rename, workspace-folder maps) so Rust isn't the one language
          -- that behaves differently.
          on_attach = nvim_lsp.on_attach,
          capabilities = nvim_lsp.capabilities,
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
    end,
  },

  {
    "nvim-neotest/neotest",
    ft = "rust",
    opts = function(_, opts)
      opts.adapters = opts.adapters or {}
      table.insert(opts.adapters, require "rustaceanvim.neotest")
    end,
  },
}
