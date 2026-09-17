return {
  "nvim-tree/nvim-tree.lua",
  opts = function(_, opts)
    opts.renderer.special_files = {}

    return vim.tbl_deep_extend("force", opts, {
      view = {
        width = 34,
        signcolumn = "yes",
      },

      filters = {
        git_ignored = false,
        custom = { "^\\.git$" },
      },

      git = {
        enable = true,
        show_on_dirs = true,
      },

      diagnostics = {
        enable = true,
        show_on_dirs = true,
      },

      renderer = {
        group_empty = true,
        symlink_destination = false,
        highlight_git = "all",
        highlight_diagnostics = "name",
        highlight_opened_files = "none",

        root_folder_label = function(path)
          return vim.fn.fnamemodify(path, ":t"):upper()
        end,

        indent_markers = {
          enable = true,
          inline_arrows = true,
          icons = {
            corner = "│",
            edge = "│",
            item = "│",
            bottom = "",
            none = " ",
          },
        },

        icons = {
          git_placement = "right_align",
          diagnostics_placement = "signcolumn",

          show = {
            folder_arrow = true,
          },

          glyphs = {
            folder = {
              arrow_closed = "",
              arrow_open = "",
            },
            git = {
              unstaged = "M",
              staged = "A",
              unmerged = "C",
              renamed = "R",
              untracked = "U",
              deleted = "D",
              ignored = "",
            },
          },
        },
      },
    })
  end,
}
