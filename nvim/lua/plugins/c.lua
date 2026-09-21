-- C's counterpart to rustaceanvim.lua, easy-dotnet.lua and python.lua.
-- cmake-tools.nvim plays the part cargo and dotnet play for those: it owns
-- configure/build/run/debug/test and, just as importantly, the
-- compile_commands.json that clangd needs to understand the project at all.
-- clangd itself is enabled in nvim-lspconfig.lua with the other plain servers.

local function cmd(name)
  return function()
    vim.cmd(name)
  end
end

local function open_cmakelists()
  local root = vim.fs.root(0, "CMakeLists.txt")
  if not root then
    vim.notify("no CMakeLists.txt above this file", vim.log.levels.WARN)
    return
  end
  vim.cmd.edit(vim.fs.joinpath(root, "CMakeLists.txt"))
end

local function keymaps(buf)
  local map = vim.keymap.set
  local function opts(desc)
    return { buffer = buf, desc = "C " .. desc }
  end

  -- lowercase acts on the current selection/target, uppercase widens or
  -- resets -- the same split the Rust, C# and Python configs use.
  map("n", "<leader>rg", cmd "CMakeGenerate", opts "configure (cmake generate)")
  map("n", "<leader>rb", cmd "CMakeBuild", opts "build")
  map("n", "<leader>rB", cmd "CMakeClean", opts "clean")
  map("n", "<leader>ru", cmd "CMakeRun", opts "run launch target")
  map("n", "<leader>rd", cmd "CMakeDebug", opts "debug launch target")
  map("n", "<leader>rt", cmd "CMakeRunTest", opts "run ctest")
  map("n", "<leader>rx", cmd "CMakeStopExecutor", opts "stop the running target")

  map("n", "<leader>rs", cmd "CMakeSelectBuildTarget", opts "select build target")
  map("n", "<leader>rS", cmd "CMakeSelectLaunchTarget", opts "select launch target")
  map("n", "<leader>ry", cmd "CMakeSelectBuildType", opts "select build type")
  map("n", "<leader>rk", cmd "CMakeSelectKit", opts "select kit")
  map("n", "<leader>rc", open_cmakelists, opts "open CMakeLists.txt")

  -- The two clangd actions with no equivalent anywhere else in this config.
  -- Header/source switching is the single most-used C-specific motion there
  -- is, and the AST view is what makes a macro-heavy translation unit
  -- readable.
  map("n", "<leader>rh", cmd "ClangdSwitchSourceHeader", opts "switch header/source")
  map("n", "<leader>rA", cmd "ClangdAST", opts "show clangd AST")

  map("n", "<leader>ri", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = buf }, { bufnr = buf })
  end, opts "toggle inlay hints")
end

return {
  {
    "Civitasv/cmake-tools.nvim",
    ft = { "c", "cpp", "cmake" },
    dependencies = { "nvim-lua/plenary.nvim", "mfussenegger/nvim-dap" },
    config = function()
      require("cmake-tools").setup {
        cmake_build_directory = "build/${variant:buildType}",
        -- clangd only resolves includes if it can find this file, and CMake
        -- writes it into the build directory rather than the project root.
        -- Soft-linking it is what makes the LSP work without a .clangd or a
        -- hand-maintained compile_flags.txt.
        cmake_soft_link_compile_commands = true,
        -- Ninja over the default Unix Makefiles generator: it's in
        -- packages.nix for this, and its dependency scanning is what makes
        -- an incremental <leader>rb worth pressing.
        cmake_generate_options = { "-G", "Ninja", "-D", "CMAKE_EXPORT_COMPILE_COMMANDS=ON" },
        cmake_regenerate_on_save = true,
        cmake_dap_configuration = {
          name = "cpp",
          type = "codelldb",
          request = "launch",
          stopOnEntry = false,
          runInTerminal = true,
          console = "integratedTerminal",
        },
        cmake_executor = {
          name = "quickfix",
          opts = { show = "always", position = "belowright", size = 10 },
        },
        cmake_runner = {
          name = "terminal",
        },
        cmake_notifications = {
          runner = { enabled = true },
          executor = { enabled = true },
        },
      }

      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "c", "cpp" },
        callback = function(args)
          keymaps(args.buf)
        end,
      })
      if vim.bo.filetype == "c" or vim.bo.filetype == "cpp" then
        keymaps(0)
      end
    end,
  },

  {
    -- clangd speaks a handful of requests outside the LSP spec (AST,
    -- symbol info, type hierarchy, memory usage). This is the only thing
    -- that surfaces them, and it's the C analogue of the extras
    -- rustaceanvim adds on top of rust-analyzer.
    "p00f/clangd_extensions.nvim",
    ft = { "c", "cpp" },
    opts = {
      -- init.lua turns inlay hints on globally through the native API, so
      -- this plugin's own virtual-text implementation would double them up.
      inlay_hints = { inline = false },
      ast = {
        role_icons = {
          type = "",
          declaration = "",
          expression = "",
          specifier = "",
          statement = "",
          ["template argument"] = "",
        },
        kind_icons = {
          Compound = "",
          Recovery = "",
          TranslationUnit = "",
          PackExpansion = "",
          TemplateTypeParm = "",
          TemplateTemplateParm = "",
          TemplateParamObject = "",
        },
      },
    },
  },
}
