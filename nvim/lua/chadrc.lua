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

M.ui = {
  statusline = {
    order = { "mode", "file", "git", "%=", "lsp_msg", "%=", "diagnostics", "lsp", "fileinfo", "cwd", "cursor" },
    modules = {
      git = function()
        local bufnr = vim.api.nvim_win_get_buf(vim.g.statusline_winid or 0)
        local head = vim.b[bufnr].gitsigns_head
        if not head then
          return ""
        end

        local status = vim.b[bufnr].gitsigns_status_dict or {}
        local added = (status.added and status.added > 0) and ("  " .. status.added) or ""
        local changed = (status.changed and status.changed > 0) and ("  " .. status.changed) or ""
        local removed = (status.removed and status.removed > 0) and ("  " .. status.removed) or ""

        return "%#St_gitIcons#  " .. head .. added .. changed .. removed .. " "
      end,

      fileinfo = function()
        local enc = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
        local ff = vim.bo.fileformat:upper()
        return "%#St_cwd_text# " .. enc .. " " .. ff .. " "
      end,
    },
  },
}

return M
