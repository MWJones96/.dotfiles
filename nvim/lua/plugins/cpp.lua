-- C++ builds on c.lua rather than beside it: clangd, cmake-tools,
-- clangd_extensions and conform's clang_format are already wired for `cpp`
-- there, and the <leader>r* build/run/debug maps bind for both filetypes.
-- What's left here is the part that is C++ and not C.
--
-- There is deliberately no neotest adapter. neotest-gtest is the only
-- GoogleTest one, and it calls query:iter_matches(..., { all = false }) --
-- a Neovim 0.10 API. Since 0.11 iter_matches always yields a *list* per
-- capture, so its get_node_text is handed a table and every discovery dies
-- with "attempt to call method 'start' (a nil value)". Upstream has no
-- version guard as of its Sept 2025 HEAD. Tests go through ctest instead,
-- which is where gtest_discover_tests() registers them anyway.

-- Runs at import time, i.e. startup -- a filetype rule is no use once the
-- buffer is already open. Neovim 0.12 already maps .cc, .cxx, .hpp, .hh,
-- .inl, .cppm, .ixx and .cxxm correctly; these two it does not, and `.tpp`
-- is worse than unmapped -- it resolves to the `tpp` filetype, which belongs
-- to a terminal presentation tool.
vim.filetype.add {
  extension = {
    tpp = "cpp",
    txx = "cpp",
  },
}

-- The enclosing TEST/TEST_F/TEST_P above the cursor, as ctest knows it.
local function gtest_at_cursor()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  for i = row, 1, -1 do
    local line = vim.api.nvim_buf_get_lines(0, i - 1, i, false)[1] or ""
    local suite, name = line:match "^%s*TEST_?[FP]?%s*%(%s*([%w_]+)%s*,%s*([%w_]+)%s*%)"
    if suite then
      return suite, name
    end
  end
end

local function run_ctest(filter, what)
  local ok, cmake = pcall(require, "cmake-tools")
  local build = ok and tostring(cmake.get_build_directory() or "") or ""
  -- Before a generate, get_build_directory() hands back the configured
  -- template with ${variant:buildType} still in it, which ctest would take
  -- literally. Treat that the same as no build tree at all.
  if build == "" or build:find("${", 1, true) or vim.fn.isdirectory(build) == 0 then
    vim.notify("no CMake build directory yet -- run <leader>rg first", vim.log.levels.WARN)
    return
  end

  local cmd = ("ctest --test-dir %s --output-on-failure"):format(vim.fn.shellescape(tostring(build)))
  if filter then
    cmd = cmd .. " -R " .. vim.fn.shellescape(filter)
  end

  vim.notify("ctest: " .. what)
  vim.cmd.new()
  vim.cmd.terminal(cmd)
  vim.cmd.startinsert()
end

local function keymaps(buf)
  local map = vim.keymap.set
  local function opts(desc)
    return { buffer = buf, desc = "C++ " .. desc }
  end

  -- c.lua already binds <leader>rt to :CMakeRunTest, which is ctest over the
  -- whole project with a picker. These narrow it to what's under the cursor,
  -- on the same letters Python uses. Both depend on the project registering
  -- cases with gtest_discover_tests() -- a single add_test for the whole
  -- binary gives ctest nothing per-test to filter on.
  --
  -- The filters are left unanchored on purpose: TEST_P registers as
  -- Instantiation/Suite.Name/0, so anchoring would miss every parameterised
  -- case.
  map("n", "<leader>rr", function()
    local suite, name = gtest_at_cursor()
    if not suite then
      vim.notify("no TEST/TEST_F/TEST_P above the cursor", vim.log.levels.WARN)
      return
    end
    run_ctest(("%s\\.%s"):format(suite, name), suite .. "." .. name)
  end, opts "run the test under the cursor")

  map("n", "<leader>rf", function()
    local suite = gtest_at_cursor()
    if not suite then
      vim.notify("no TEST/TEST_F/TEST_P above the cursor", vim.log.levels.WARN)
      return
    end
    run_ctest(("%s\\."):format(suite), "suite " .. suite)
  end, opts "run the whole suite at the cursor")

  -- Presets are how a modern C++ project pins its toolchain and build dirs.
  -- cmake-tools reads CMakePresets.json but can't guess which one you want.
  map("n", "<leader>rp", "<cmd>CMakeSelectConfigurePreset<cr>", opts "select configure preset")
end

vim.api.nvim_create_autocmd("FileType", {
  pattern = "cpp",
  callback = function(args)
    keymaps(args.buf)
  end,
})

-- No plugin of its own: everything C++ needs, c.lua already installs.
return {}
