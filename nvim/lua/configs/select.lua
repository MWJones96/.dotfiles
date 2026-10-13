vim.ui.select = function(items, opts, on_choice)
  opts = opts or {}
  local format = opts.format_item or tostring
  local prompt = opts.prompt and vim.trim(opts.prompt):gsub(":$", "")

  local lines = {}
  local width = prompt and #prompt + 4 or 0
  for i, item in ipairs(items) do
    lines[i] = " " .. format(item) .. " "
    width = math.max(width, vim.fn.strdisplaywidth(lines[i]))
  end
  width = math.min(width, vim.o.columns - 4)
  local height = math.min(#lines, vim.o.lines - 6)

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    style = "minimal",
    border = "rounded",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2) - 1,
    col = math.floor((vim.o.columns - width) / 2),
    title = prompt and " " .. prompt .. " ",
    title_pos = "center",
  })
  vim.wo[win].cursorline = true

  local done = false
  local function finish(idx)
    if done then
      return
    end
    done = true
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    on_choice(idx and items[idx], idx)
  end

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = buf, nowait = true })
  end
  map("<CR>", function()
    finish(vim.api.nvim_win_get_cursor(win)[1])
  end)
  map("<Esc>", function()
    finish()
  end)
  map("q", function()
    finish()
  end)

  vim.api.nvim_create_autocmd("WinLeave", {
    buffer = buf,
    once = true,
    callback = function()
      finish()
    end,
  })
end
