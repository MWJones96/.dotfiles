-- Repo-wide git state for the statusline. gitsigns only tracks hunks in the
-- current buffer, so it can't answer "what's uncommitted across the repo" or
-- "am I ahead of origin" — this fills that gap from a single `git status` call,
-- cached so the statusline never shells out on redraw.
local M = {}

-- Own groups, with the background taken from StatusLine at runtime: each base46
-- statusline theme derives that background differently (vscode_colored lightens
-- it), so a fixed colour in chadrc's hl_add would leave a seam behind the git
-- section, and borrowing another theme's group loses its colour when the
-- statusline theme changes.
local highlights = {
  St_GitBranch = "purple",
  St_GitClean = "green",
  St_GitAhead = "vibrant_green",
  St_GitBehind = "orange",
  St_GitStaged = "green",
  St_GitModified = "yellow",
  St_GitUntracked = "cyan",
}

local function set_highlights()
  local colors = require("base46").get_theme_tb "base_30"
  local bg = vim.api.nvim_get_hl(0, { name = "StatusLine", link = false }).bg

  for group, color in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, { fg = colors[color], bg = bg, bold = true })
  end
end

local empty = {
  head = "",
  ahead = 0,
  behind = 0,
  staged = 0,
  modified = 0,
  untracked = 0,
  tracked = false,
}

local state = vim.deepcopy(empty)
local pending = false

local function parse(out)
  local result = vim.deepcopy(empty)
  result.tracked = true

  for line in vim.gsplit(out, "\n", { plain = true }) do
    if line:sub(1, 2) == "##" then
      local branch = line:sub(4):gsub("^No commits yet on ", "")
      result.head = branch:match "^(.-)%.%.%." or branch:match "^(%S+)" or ""
      result.ahead = tonumber(branch:match "ahead (%d+)") or 0
      result.behind = tonumber(branch:match "behind (%d+)") or 0
    elseif line ~= "" then
      local index, worktree = line:sub(1, 1), line:sub(2, 2)
      if index == "?" then
        result.untracked = result.untracked + 1
      else
        if index ~= " " then
          result.staged = result.staged + 1
        end
        if worktree ~= " " then
          result.modified = result.modified + 1
        end
      end
    end
  end

  return result
end

local function run()
  local cwd = vim.uv.cwd()
  if not cwd then
    return
  end

  vim.system({ "git", "status", "--porcelain=v1", "--branch" }, { cwd = cwd, text = true }, function(res)
    vim.schedule(function()
      state = res.code == 0 and parse(res.stdout or "") or vim.deepcopy(empty)
      vim.cmd.redrawstatus()
    end)
  end)
end

-- Several of the triggers below fire in bursts (writing a file also updates the
-- gitsigns index), so coalesce them into one call.
function M.refresh()
  if pending then
    return
  end
  pending = true
  vim.defer_fn(function()
    pending = false
    run()
  end, 100)
end

function M.get()
  return state
end

local group = vim.api.nvim_create_augroup("StatuslineGitStatus", { clear = true })

vim.api.nvim_create_autocmd({ "VimEnter", "BufWritePost", "FocusGained", "DirChanged" }, {
  group = group,
  callback = M.refresh,
})

vim.api.nvim_create_autocmd("User", {
  pattern = { "GitSignsUpdate", "GitSignsChanged" },
  group = group,
  callback = M.refresh,
})

vim.api.nvim_create_autocmd("ColorScheme", {
  group = group,
  callback = set_highlights,
})

set_highlights()
M.refresh()

return M
