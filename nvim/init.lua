vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

vim.keymap.set({ "n", "i", "v" }, "<Up>", function()
  vim.api.nvim_echo({ { "Use 'k' for up!", "WarningMsg" } }, false, {})
end, { desc = "Nudge for k" })
vim.keymap.set({ "n", "i", "v" }, "<Down>", function()
  vim.api.nvim_echo({ { "Use 'j' for down!", "WarningMsg" } }, false, {})
end, { desc = "Nudge for j" })
vim.keymap.set({ "n", "i", "v" }, "<Left>", function()
  vim.api.nvim_echo({ { "Use 'h' for left!", "WarningMsg" } }, false, {})
end, { desc = "Nudge for h" })
vim.keymap.set({ "n", "i", "v" }, "<Right>", function()
  vim.api.nvim_echo({ { "Use 'l' for right!", "WarningMsg" } }, false, {})
end, { desc = "Nudge for l" })

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "configs.options"
require "configs.autocmds"

vim.schedule(function()
  require "configs.mappings"
end)

vim.lsp.inlay_hint.enable(true)
