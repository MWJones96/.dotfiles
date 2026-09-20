-- Python's counterpart to rustaceanvim.lua and easy-dotnet.lua. No single
-- plugin owns the language the way those two do, so the pieces are assembled
-- here: neotest for the test runner, nvim-dap-python for the debugger, and
-- venv-selector for picking an interpreter. The LSP half (basedpyright + ruff)
-- is enabled in nvim-lspconfig.lua, alongside the other plain servers.

-- Which interpreter the test runner, the debuggee and <leader>ru all use.
-- Shared so they can't disagree: neotest, nvim-dap-python and venv-selector
-- each ship their own venv detection, and three answers to "which python" is
-- exactly the failure this is meant to avoid. VIRTUAL_ENV comes first because
-- that's what venv-selector sets when you pick one explicitly.
local function venv_python()
  local venv = vim.env.VIRTUAL_ENV
  if venv and vim.uv.fs_stat(venv .. "/bin/python") then
    return venv .. "/bin/python"
  end

  local root = vim.fs.root(0, ".venv")
  if root and vim.uv.fs_stat(root .. "/.venv/bin/python") then
    return root .. "/.venv/bin/python"
  end

  return vim.fn.exepath "python3"
end

-- Same Mason path shape as nvim-dap.lua's codelldb. debugpy is installed into
-- its own venv, and it's that venv's python that has to run the adapter --
-- the debuggee's interpreter is resolved separately, by venv_python above.
local function debugpy_python()
  return vim.fn.stdpath "data" .. "/mason/packages/debugpy/venv/bin/python"
end

local function run_current_file()
  local file = vim.fn.expand "%:p"
  local cmd = vim.fn.shellescape(venv_python()) .. " " .. vim.fn.shellescape(file)
  if vim.bo.modified then
    vim.cmd.write()
  end
  vim.cmd.new()
  vim.cmd.terminal(cmd)
  vim.cmd.startinsert()
end

local function keymaps(buf)
  local map = vim.keymap.set
  local function opts(desc)
    return { buffer = buf, desc = "Python " .. desc }
  end
  local function neotest()
    return require "neotest"
  end

  -- lowercase acts on the cursor or the current file, uppercase widens to the
  -- whole project -- the same split rustaceanvim.lua and easy-dotnet.lua use.
  map("n", "<leader>rr", function()
    neotest().run.run()
  end, opts "run nearest test")
  map("n", "<leader>rd", function()
    neotest().run.run { strategy = "dap" }
  end, opts "debug nearest test")
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
  map("n", "<leader>rw", function()
    neotest().watch.toggle(vim.fn.expand "%")
  end, opts "watch this file")

  map("n", "<leader>ru", run_current_file, opts "run this file")
  map("v", "<leader>re", function()
    require("dap-python").debug_selection()
  end, opts "debug selection")
  map("n", "<leader>rv", "<cmd>VenvSelect<cr>", opts "select interpreter")
  map("n", "<leader>ri", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = buf }, { bufnr = buf })
  end, opts "toggle inlay hints")
end

return {
  {
    "nvim-neotest/neotest",
    ft = "python",
    dependencies = {
      "nvim-neotest/nvim-nio",
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
      "nvim-neotest/neotest-python",
      "mfussenegger/nvim-dap",
    },
    config = function()
      require("neotest").setup {
        adapters = {
          require "neotest-python" {
            python = venv_python,
            -- Stepping stops at the first line of your own code by default,
            -- which makes debugging anything that fails inside a library
            -- (pydantic validators, fastapi dependencies) a dead end.
            dap = { justMyCode = false },
          },
        },
      }

      -- lazy.nvim re-emits FileType after loading an `ft`-gated plugin, so this
      -- still fires for the buffer that triggered the load.
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "python",
        callback = function(args)
          keymaps(args.buf)
        end,
      })
      -- ...but not when something else (a `require`, or :Neotest) pulled the
      -- plugin in first, in which case the event has already been and gone.
      if vim.bo.filetype == "python" then
        keymaps(0)
      end
    end,
  },

  {
    "mfussenegger/nvim-dap-python",
    ft = "python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      local dap_python = require "dap-python"
      dap_python.setup(debugpy_python())
      -- Without this the debuggee runs on the Mason venv's python, which has
      -- debugpy but none of the project's dependencies.
      dap_python.resolve_python = venv_python
    end,
  },

  {
    "linux-cultist/venv-selector.nvim",
    -- No `branch` key: the rewrite that most of the docs still call the
    -- "regexp" branch has been folded back into main, and pinning the old
    -- name now makes the plugin raise on load -- which, from an `ft`
    -- autocmd, means :edit on a .py file fails outright.
    ft = "python",
    cmd = "VenvSelect",
    dependencies = {
      "neovim/nvim-lspconfig",
      "mfussenegger/nvim-dap-python",
      "nvim-telescope/telescope.nvim",
    },
    opts = {
      settings = {
        options = {
          notify_user_on_venv_activation = true,
        },
      },
    },
  },
}
