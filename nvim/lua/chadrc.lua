-- This file needs to have same structure as nvconfig.lua
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua
-- Please read that file to know all available options :(

---@type ChadrcConfig
local M = {}

M.base46 = {
  theme = "tokyonight",

  hl_override = {
    NvimTreeNormal = { bg = "black2" },
    NvimTreeNormalNC = { bg = "black2" },
    NvimTreeEndOfBuffer = { fg = "black2", bg = "black2" },
    NvimTreeWinSeparator = { fg = "black2", bg = "black2" },
    NvimTreeCursorLine = { bg = "one_bg" },
    NvimTreeRootFolder = { fg = "light_grey", bold = true },

    NvimTreeFolderName = { fg = "white" },
    NvimTreeOpenedFolderName = { fg = "white" },
    NvimTreeEmptyFolderName = { fg = "light_grey" },
    NvimTreeFolderArrowClosed = { fg = "light_grey" },
    NvimTreeFolderArrowOpen = { fg = "light_grey" },
    NvimTreeIndentMarker = { fg = "grey" },
  },

  hl_add = {
    NvimTreeGitDirtyIcon = { fg = "yellow" },
    NvimTreeGitStagedIcon = { fg = "green" },
    NvimTreeGitNewIcon = { fg = "green" },
    NvimTreeGitRenamedIcon = { fg = "green" },
    NvimTreeGitDeletedIcon = { fg = "red" },
    NvimTreeGitMergeIcon = { fg = "orange", bold = true },
    NvimTreeGitIgnoredIcon = { fg = "grey_fg" },
  },
}

M.ui = {
  statusline = {
    theme = "vscode_colored",
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "cursor", "fileinfo", "cwd" },
    modules = {
      git = function()
        local git = require "configs.gitstatus"
        local status = git.get()

        local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
        local head = status.head
        if head == "" then
          head = vim.b[bufnr].gitsigns_head or vim.g.gitsigns_head or ""
        end
        if head == "" then
          return ""
        end

        local out = "%#St_GitBranch#  " .. head
        if not status.tracked then
          return out .. " "
        end

        local sync = ""
        if status.ahead > 0 then
          sync = sync .. "%#St_GitAhead#↑" .. status.ahead
        end
        if status.behind > 0 then
          sync = sync .. "%#St_GitBehind#↓" .. status.behind
        end
        if sync ~= "" then
          out = out .. " " .. sync
        end

        local counts = {}
        if status.staged > 0 then
          counts[#counts + 1] = "%#St_GitStaged#+" .. status.staged
        end
        if status.modified > 0 then
          counts[#counts + 1] = "%#St_GitModified#~" .. status.modified
        end
        if status.untracked > 0 then
          counts[#counts + 1] = "%#St_GitUntracked#?" .. status.untracked
        end

        if #counts > 0 then
          out = out .. " " .. table.concat(counts, " ")
        elseif sync == "" then
          out = out .. " %#St_GitClean#✓"
        end

        return out .. " "
      end,

      fileinfo = function()
        local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
        local ff = vim.bo.fileformat:upper()
        return "%#StText# " .. enc .. " " .. ff .. " "
      end,
    },
  },
}

return M
