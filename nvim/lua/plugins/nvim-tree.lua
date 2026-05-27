return {
  "nvim-tree/nvim-tree.lua",
  opts = {
    renderer = {
      icons = {
        glyphs = {
          git = {
            unstaged  = "󰏫",  -- Subtle alert or modified mark
            staged    = "󰸞",  -- Clean staging check
            unmerged  = "",  -- Traditional git branch/merge conflict symbol
            renamed   = "➜",  -- Clean movement indicator
            untracked = "",  -- Clean "plus" symbol for new files
            deleted   = "",  -- Clean minus/trash symbol
            ignored   = "◌",  -- Minimal circle for ignored items
          }
        }
      }
    }
  }
}
