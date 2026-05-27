-- This file needs to have same structure as nvconfig.lua 
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :( 

---@type ChadrcConfig
local M = {}

M.base46 = {
	theme = "tokyonight",

  hl_override = {
    -- Text & Icon Colors for each Git Status
    NvimTreeGitDirty     = { fg = "yellow" },
    NvimTreeGitStaged    = {},
    NvimTreeGitNew       = { fg = "green" },
    NvimTreeGitDeleted   = { fg = "red" },
    NvimTreeGitMerge     = { fg = "purple" },
    NvimTreeGitRename    = { fg = "blue" },
    NvimTreeGitIgnored   = { fg = "dark_grey" },
  },
}

return M
