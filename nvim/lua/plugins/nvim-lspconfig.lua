return {
  "neovim/nvim-lspconfig",
  config = function()
    local nvim_lsp = require "nvchad.configs.lspconfig"

    -- lazy.nvim merges every spec for a given plugin and keeps one `config`,
    -- so this function *replaces* the one NvChad ships for nvim-lspconfig —
    -- which exists only to make this call. Without it nothing registers the
    -- global LspAttach autocmd behind gd/gD/<leader>ra, nothing sets
    -- vim.lsp.config("*") capabilities, NvChad's diagnostic styling is never
    -- applied, and lua_ls is never enabled despite Mason installing it. Only
    -- servers that pass on_attach by hand (the two below, and rustaceanvim)
    -- escaped that, which is why it went unnoticed.
    nvim_lsp.defaults()

    -- Servers with no plugin of their own driving them. Rust (rustaceanvim)
    -- and C# (easy-dotnet) are absent because those plugins start their own.
    local servers = {
      html = {},
      cssls = {},

      -- Mason has been installing clangd all along, but nothing ever called
      -- vim.lsp.enable on it, so C and C++ buffers had no LSP at all. Most of
      -- clangd's behaviour is argv rather than settings, which is why this one
      -- overrides `cmd` instead of passing a settings table.
      clangd = {
        cmd = {
          "clangd",
          -- Index the whole project in the background, not just open files:
          -- without it, workspace symbols and find-references only ever see
          -- the translation units you've already opened.
          "--background-index",
          -- clangd embeds clang-tidy, so this needs no separate binary; it is
          -- what turns the LSP from a navigator into a linter.
          "--clang-tidy",
          -- Insert the header the symbol actually comes from on completion,
          -- rather than whichever one happens to re-export it.
          "--header-insertion=iwyu",
          "--completion-style=detailed",
          -- C++ only in practice: completes a symbol sitting in a namespace
          -- you haven't qualified or `using`-ed yet, and adds the qualifier.
          -- C has no namespaces, so it costs those buffers nothing.
          "--all-scopes-completion",
          "--function-arg-placeholders",
          -- Without a fallback, a file clangd has no compile command for gets
          -- no formatting style at all.
          "--fallback-style=llvm",
          "--pch-storage=memory",
        },
        init_options = {
          usePlaceholders = true,
          completeUnimported = true,
          clangdFileStatus = true,
        },
      },

      -- Python is split across two servers, which is the supported way to run
      -- both: basedpyright does types, completion and navigation, ruff does
      -- lint diagnostics and fixes. basedpyright replaced python-lsp-server
      -- here — pylsp needs a plugin installed per feature and has no inlay
      -- hints at all.
      ruff = {},
      basedpyright = {
        settings = {
          basedpyright = {
            analysis = {
              -- basedpyright defaults to "recommended", which treats every
              -- missing annotation and every Unknown as an error — unusable
              -- on code that wasn't written against it. "standard" is
              -- pyright's own default.
              typeCheckingMode = "standard",
              -- "workspace" would be the C#-style full-project analysis, but
              -- Python has no solution file to bound it: in a monorepo it
              -- walks everything under the root. Switch it if you want it.
              diagnosticMode = "openFilesOnly",
              autoImportCompletions = true,
              inlayHints = {
                variableTypes = true,
                callArgumentNames = true,
                functionReturnTypes = true,
                genericTypes = false,
              },
            },
            -- conform.nvim already runs ruff_organize_imports on save;
            -- leaving basedpyright's on too gives two competing sorts.
            disableOrganizeImports = true,
          },
        },
      },
    }

    for name, opts in pairs(servers) do
      vim.lsp.config(
        name,
        vim.tbl_deep_extend("force", {
          on_attach = nvim_lsp.on_attach,
          on_init = nvim_lsp.on_init,
          capabilities = nvim_lsp.capabilities,
        }, opts)
      )

      vim.lsp.enable(name)
    end

    -- ruff advertises hover but only ever answers with the documentation for
    -- a noqa code, so on a Python buffer it competes with basedpyright's
    -- types for the same K press.
    vim.api.nvim_create_autocmd("LspAttach", {
      callback = function(args)
        local client = vim.lsp.get_client_by_id(args.data.client_id)
        if client and client.name == "ruff" then
          client.server_capabilities.hoverProvider = false
        end
      end,
    })
  end,
}
