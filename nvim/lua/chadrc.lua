-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "tokyonight",

  hl_override = {
    NvimTreeGitDirty = { fg = "yellow" },
    NvimTreeGitStaged = { fg = "green" },
    NvimTreeGitMerge = { fg = "red", bold = true },
    NvimTreeGitRename = { fg = "purple" },
    NvimTreeGitNew = { fg = "cyan" },
    NvimTreeGitDeleted = { fg = "red" },
    NvimTreeGitIgnored = { fg = "dark_grey" },
  },
}

return M
