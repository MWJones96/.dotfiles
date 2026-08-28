return {
  'rcarriga/nvim-dap-ui',
  -- mfussenegger/nvim-dap is already declared as its own plugin spec in
  -- nvim-dap.lua; only list the dependency that's unique to this plugin.
  dependencies = {"nvim-neotest/nvim-nio"},
  config = function()
    require("dapui").setup()
  end,
}
