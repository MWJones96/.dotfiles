require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>", { desc = "Exit insert mode" })

-- Nvim DAP
map("n", "<Leader>dl", function() require("dap").step_into() end, { desc = "Debugger step into" })
map("n", "<Leader>dj", function() require("dap").step_over() end, { desc = "Debugger step over" })
map("n", "<Leader>dk", function() require("dap").step_out() end, { desc = "Debugger step out" })
map("n", "<Leader>dc", function() require("dap").continue() end, { desc = "Debugger continue" })
map("n", "<Leader>db", function() require("dap").toggle_breakpoint() end, { desc = "Debugger toggle breakpoint" })
map("n", "<Leader>dd", function()
  require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
end, { desc = "Debugger set conditional breakpoint" })
map("n", "<Leader>de", function() require("dap").terminate() end, { desc = "Debugger reset" })
map("n", "<Leader>dr", function() require("dap").run_last() end, { desc = "Debugger run last" })
