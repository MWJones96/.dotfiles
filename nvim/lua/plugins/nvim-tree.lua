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
        git_ignored = true,
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
        indent_width = 2,
        highlight_git = "all",
        highlight_diagnostics = "name",

        decorators = {
          "Git",
          "Open",
          "Hidden",
          "Modified",
          "Bookmark",
          "Diagnostics",
          "Copied",
          "Cut",
          require "configs.diagcount",
        },

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
          padding = {
            icon = " ",
          },

          web_devicons = {
            file = { enable = true, color = true },
            folder = { enable = false, color = false },
          },

          show = {
            folder_arrow = true,
            diagnostics = false,
            bookmarks = false,
          },

          glyphs = {
            folder = {
              arrow_closed = "",
              arrow_open = "",
              default = "",
              open = "",
              empty = "",
              empty_open = "",
              symlink = "",
              symlink_open = "",
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
