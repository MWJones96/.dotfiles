-- easy-dotnet is to C# what rustaceanvim is to Rust in this config: one
-- plugin that owns the LSP, the debugger wiring, the test runner and the
-- solution/package/EF actions, rather than gluing four plugins together.
--
-- It needs two things lazy.nvim can't install, because neither is Lua:
--   * EasyDotnet -- its JSON-RPC backend, a dotnet global tool. Seeded on
--     activation by nix/home/editors.nix so a fresh machine doesn't need a
--     manual `dotnet tool install`.
--   * roslyn-language-server -- the same server VS Code's C# extension uses.
--     The plugin installs and updates this one itself on first use, which is
--     why it isn't in packages.nix: nixpkgs' roslyn-ls is 5.11.0 and the
--     current server line is 5.12.x.
return {
  "GustavEikaas/easy-dotnet.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    "mfussenegger/nvim-dap",
    -- NvChad already ships telescope; naming it here is what lets
    -- `picker = "telescope"` below resolve without pulling in snacks.nvim,
    -- which the upstream README suggests instead.
    "nvim-telescope/telescope.nvim",
  },
  -- Same reason as mason.lua and rustaceanvim.lua: this plugin registers
  -- filetypes for .csproj/.fsproj/.sln/.slnx and installs its buffer
  -- mappings from hooks that must already be on 'runtimepath' when a buffer's
  -- filetype is set. Deferring it risks missing that one-shot pass. The
  -- actual work still only happens in .NET buffers.
  lazy = false,
  config = function()
    -- easy-dotnet starts Roslyn itself, under the client name `easy_dotnet`.
    --
    -- Only `settings` is worth setting here. Unlike rustaceanvim.lua, this
    -- plugin *replaces* vim.lsp.config.easy_dotnet with its own table when it
    -- starts the server, carrying across just `settings` and `capabilities`
    -- from whatever was already there — an `on_attach` passed here is
    -- silently dropped. It isn't needed anyway: NvChad's
    -- configs.lspconfig.defaults() registers one global LspAttach autocmd
    -- that applies its keymaps to every client, and a vim.lsp.config("*")
    -- entry that supplies its capabilities.
    --
    -- Roslyn namespaces its settings with a `|`; these are the server's own
    -- option names, not Neovim's. init.lua already calls
    -- vim.lsp.inlay_hint.enable(true), so the hint options below actually
    -- render rather than just being advertised.
    vim.lsp.config("easy_dotnet", {
      settings = {
        ["csharp|inlay_hints"] = {
          csharp_enable_inlay_hints_for_implicit_object_creation = true,
          csharp_enable_inlay_hints_for_implicit_variable_types = true,
          csharp_enable_inlay_hints_for_lambda_parameter_types = true,
          csharp_enable_inlay_hints_for_types = true,
          dotnet_enable_inlay_hints_for_indexer_parameters = true,
          dotnet_enable_inlay_hints_for_literal_parameters = true,
          dotnet_enable_inlay_hints_for_object_creation_parameters = true,
          dotnet_enable_inlay_hints_for_other_parameters = true,
          dotnet_enable_inlay_hints_for_parameters = true,
          -- Hints that only restate the argument name are noise.
          dotnet_suppress_inlay_hints_for_parameters_that_differ_only_by_suffix = true,
          dotnet_suppress_inlay_hints_for_parameters_that_match_argument_name = true,
          dotnet_suppress_inlay_hints_for_parameters_that_match_method_intent = true,
        },
        ["csharp|code_lens"] = {
          dotnet_enable_references_code_lens = true,
          dotnet_enable_tests_code_lens = true,
        },
        ["csharp|completion"] = {
          dotnet_provide_regex_completions = true,
          dotnet_show_completion_items_from_unimported_namespaces = true,
          dotnet_show_name_completion_suggestions = true,
        },
        -- Without this Roslyn only diagnoses files you've actually opened,
        -- which is the single biggest difference from the Rider/VS
        -- experience -- `:Dotnet diagnostic errors` depends on it.
        ["csharp|background_analysis"] = {
          dotnet_analyzer_diagnostics_scope = "fullSolution",
          dotnet_compiler_diagnostics_scope = "fullSolution",
        },
        ["csharp|symbol_search"] = {
          dotnet_search_reference_assemblies = true,
        },
        ["csharp|formatting"] = {
          dotnet_organize_imports_on_format = true,
        },
      },
    })

    require("easy-dotnet").setup {
      picker = "telescope",

      lsp = {
        enabled = true,
        roslynator_enabled = true,
        auto_refresh_codelens = true,
        -- Roslyn otherwise keeps serving analysis from the branch you were
        -- on when it started.
        restart_roslyn_on_branch_change = true,
        enhanced_rename = true,
        create_type_from_usage = true,
      },

      -- netcoredbg comes from packages.nix, so it's already on PATH; leaving
      -- bin_path nil means the store path can change under us without this
      -- file going stale. auto_register_dap wires the launch/attach configs
      -- into nvim-dap, so the generic <leader>d* maps in configs/mappings.lua
      -- drive C# sessions too.
      debugger = {
        engine = "netcoredbg",
        console = "integratedTerminal",
        auto_register_dap = true,
      },

      test_runner = {
        viewmode = "float",
        auto_start_testrunner = true,
        -- These five are buffer-local maps in C# source files, and their
        -- defaults (<leader>r, <leader>d, <leader>t, <leader>p, <leader>e)
        -- would shadow the DAP prefix from configs/mappings.lua and NvChad's
        -- <leader>e. Moved under <leader>r* to match rustaceanvim's scheme:
        -- lowercase acts on what's under the cursor, uppercase widens scope.
        mappings = {
          run_test_from_buffer = { lhs = "<leader>rr", desc = "run test at cursor" },
          debug_test_from_buffer = { lhs = "<leader>rd", desc = "debug test at cursor" },
          run_all_tests_from_buffer = { lhs = "<leader>rt", desc = "run all tests in file" },
          peek_stack_trace_from_buffer = { lhs = "<leader>rp", desc = "peek test output" },
          get_build_errors = { lhs = "<leader>rb", desc = "build errors" },
        },
      },

      -- Fills in namespace + type declaration when you open a new empty .cs
      -- file. file_scoped rather than the plugin's block_scoped default
      -- because that's what quaisr/core's .editorconfig asks for
      -- (csharp_style_namespace_declarations = file_scoped).
      auto_bootstrap_namespace = {
        enabled = true,
        type = "file_scoped",
      },

      diagnostics = {
        default_severity = "error",
        setqflist = true,
      },
    }

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "cs", "razor", "cshtml" },
      callback = function(args)
        local map = vim.keymap.set
        local function opts(desc)
          return { buffer = args.buf, desc = "Dotnet " .. desc }
        end
        local function cmd(sub)
          return function()
            vim.cmd("Dotnet " .. sub)
          end
        end

        -- <leader>rr/rd/rt/rp/rb are the test_runner mappings above.
        -- Uppercase widens the same verb from cursor/file to the solution.
        map("n", "<leader>rR", cmd "testrunner", opts "test runner")
        map("n", "<leader>rT", cmd "test solution", opts "test solution")
        map("n", "<leader>rB", cmd "build solution", opts "build solution")

        map("n", "<leader>ru", cmd "run", opts "run project")
        map("n", "<leader>rw", cmd "watch", opts "watch project")
        map("n", "<leader>rc", cmd "solution select", opts "select solution")

        -- The C# counterpart to crates-nvim on the Rust side. <leader>ra is
        -- deliberately left alone -- NvChad binds it to the LSP renamer.
        map("n", "<leader>rn", cmd "add package", opts "add NuGet package")
        map("n", "<leader>ro", cmd "outdated", opts "outdated packages")

        map("n", "<leader>rs", cmd "secrets", opts "user secrets")

        -- services/Migrations is why dotnet-ef is in packages.nix; this is
        -- the same workflow without leaving the editor.
        map("n", "<leader>rm", cmd "ef migrations list", opts "EF migrations")
        map("n", "<leader>rM", cmd "ef database update", opts "EF database update")

        map("n", "<leader>rx", cmd "diagnostic errors", opts "solution diagnostics")
      end,
    })
  end,
}
