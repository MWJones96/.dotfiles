return {
  "saecki/crates.nvim",
  -- Precise trigger: only loads for Cargo.toml, not every .toml file
  -- (stylua.toml, rustfmt.toml, etc. no longer load this plugin at all).
  -- Matches the lazy-loading example in crates.nvim's own README.
  event = { "BufRead Cargo.toml" },
  config = function()
    local crates = require "crates"

    crates.setup {
      -- The old completion.cmp.enabled + manual cmp.setup.buffer wiring is
      -- deprecated upstream in favor of crates.nvim's own in-process LSP
      -- server, which plugs into the same completion/code-action path every
      -- other language here already uses — no separate cmp source needed.
      lsp = {
        enabled = true,
        completion = true,
        actions = true,
      },
    }

    -- Every user-facing function (toggle/reload/upgrade/open_*/show_*_popup)
    -- is aggregated directly onto this one module — confirmed by reading
    -- lua/crates/init.lua itself, not assumed from memory.
    local function setup_buffer_keymaps(bufnr)
      local map = vim.keymap.set
      local function opts(desc)
        return { buffer = bufnr, desc = "Crates " .. desc }
      end

      map("n", "<leader>cv", crates.show_versions_popup, opts "show versions")
      map("n", "<leader>cf", crates.show_features_popup, opts "show features")
      map("n", "<leader>cD", crates.show_dependencies_popup, opts "show dependencies")
      map("n", "<leader>ct", crates.toggle, opts "toggle")
      map("n", "<leader>cR", crates.reload, opts "reload")
      map("n", "<leader>cu", crates.upgrade_crate, opts "upgrade crate")
      map("n", "<leader>cU", crates.upgrade_all_crates, opts "upgrade all crates")
      map("n", "<leader>cO", crates.open_repository, opts "open repository")
    end

    -- lazy.nvim's `event` trigger above only loads this plugin because
    -- BufRead already fired for the Cargo.toml that triggered it — a
    -- BufRead autocmd registered only now would miss that same buffer.
    -- Handle it directly, then rely on the autocmd below for any other
    -- Cargo.toml opened later in the session (e.g. a different crate in a
    -- workspace).
    setup_buffer_keymaps(vim.api.nvim_get_current_buf())

    vim.api.nvim_create_autocmd("BufRead", {
      pattern = "Cargo.toml",
      callback = function(args)
        setup_buffer_keymaps(args.buf)
      end,
    })
  end,
}
