return {
  {
    "williamboman/mason.nvim",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- This plugin's auto-install trigger lives in its plugin/*.lua (a
    -- VimEnter autocmd) — as a bare `dependencies` entry it loaded too
    -- late for that file to be sourced (same class of issue as
    -- rustaceanvim's ftplugin; verified: :MasonToolsInstallSync didn't
    -- even exist as a command without this). `lazy = false` guarantees
    -- it's on runtimepath before Neovim's plugin/ auto-source pass.
    lazy = false,
    dependencies = { "williamboman/mason.nvim" },
    -- Core mason.nvim does NOT implement `ensure_installed` itself
    -- (verified against its source) — this is the plugin that actually
    -- consumes the list below and installs on startup.
    config = function()
      require("mason-tool-installer").setup {
        ensure_installed = {
          "lua-language-server",
          -- basedpyright over python-lsp-server: pylsp needs a separate
          -- plugin installed per feature and has no inlay hints. Kept here
          -- rather than in packages.nix so it tracks the ruff below, which
          -- has to come from Mason -- nixpkgs' ruff loses to a stale
          -- ~/.local/bin/ruff on PATH, Mason's bin dir doesn't.
          "basedpyright",
          "ruff",
          -- What nvim-dap-python runs as its adapter, the same way codelldb
          -- below backs Rust and C++.
          "debugpy",
          "stylua",
          "codelldb",
          "clangd",
          "rust-analyzer",
        },
        run_on_start = true,
      }
    end,
  },
}
