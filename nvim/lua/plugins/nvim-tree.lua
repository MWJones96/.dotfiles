return {
  "nvim-tree/nvim-tree.lua",
  config = function(_, opts)
    require("nvim-tree").setup(opts)

    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      local diagnostics = vim.diagnostic.get(buf)
      if #diagnostics > 0 then
        vim.api.nvim_exec_autocmds("DiagnosticChanged", {
          group = "NvimTree",
          buffer = buf,
          modeline = false,
          data = { diagnostics = diagnostics },
        })
      end
    end
  end,
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
        show_on_open_dirs = false,
        severity = { min = vim.diagnostic.severity.WARN },
      },

      renderer = {
        group_empty = true,
        symlink_destination = false,
        indent_width = 2,
        highlight_git = "all",
        highlight_diagnostics = "none",

        decorators = {
          "Git",
          "Open",
          "Hidden",
          "Modified",
          "Bookmark",
          "Diagnostics",
          "Copied",
          "Cut",
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
          diagnostics_placement = "signcolumn",
          padding = {
            icon = " ",
          },

          web_devicons = {
            file = { enable = true, color = true },
            folder = { enable = false, color = false },
          },

          show = {
            folder_arrow = true,
            diagnostics = true,
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
