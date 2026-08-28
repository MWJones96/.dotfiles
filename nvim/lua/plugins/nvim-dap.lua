return {
  'mfussenegger/nvim-dap',
  config = function()
    local dap, dapui = require("dap"), require("dapui")
    dap.listeners.before.attach.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
      dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
      dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
      dapui.close()
    end

    -- C/C++ debugging via the same Mason-installed codelldb rustaceanvim
    -- already uses for Rust — registered directly on nvim-dap (rather than
    -- through rustaceanvim's internal wiring) so the generic `<leader>d*`
    -- keymaps work here: with no session active, <leader>dc (dap.continue)
    -- prompts you to pick one of the configurations below and starts it.
    local mason_root = vim.fn.stdpath "data" .. "/mason"
    local codelldb_path = mason_root .. "/packages/codelldb/extension/adapter/codelldb"

    dap.adapters.codelldb = {
      type = "server",
      port = "${port}",
      executable = {
        command = codelldb_path,
        args = { "--port", "${port}" },
      },
    }

    local c_cpp_config = {
      {
        name = "Launch",
        type = "codelldb",
        request = "launch",
        program = function()
          return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
        end,
        cwd = "${workspaceFolder}",
        stopOnEntry = false,
      },
    }
    dap.configurations.c = c_cpp_config
    dap.configurations.cpp = c_cpp_config
  end,
}
