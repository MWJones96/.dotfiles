local Decorator = require("nvim-tree.api").Decorator

local ERROR = vim.diagnostic.severity.ERROR
local WARN = vim.diagnostic.severity.WARN

local DiagnosticCount = Decorator:extend()

function DiagnosticCount:new()
  self.enabled = true
  self.highlight_range = "none"
  self.icon_placement = "right_align"

  self.counts = {}

  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    local path = vim.api.nvim_buf_get_name(buf)
    if path ~= "" then
      local errors = #vim.diagnostic.get(buf, { severity = ERROR })
      local warnings = #vim.diagnostic.get(buf, { severity = WARN })

      if errors > 0 or warnings > 0 then
        self.counts[path] = { errors = errors, warnings = warnings }
      end
    end
  end
end

function DiagnosticCount:icons(node)
  local errors, warnings = 0, 0
  local own = self.counts[node.absolute_path]

  if own then
    errors, warnings = own.errors, own.warnings
  elseif node.type == "directory" then
    local prefix = node.absolute_path .. "/"

    for path, count in pairs(self.counts) do
      if path:sub(1, #prefix) == prefix then
        errors = errors + count.errors
        warnings = warnings + count.warnings
      end
    end
  end

  if errors > 0 then
    return { { str = tostring(errors), hl = { "NvimTreeDiagnosticErrorIcon" } } }
  elseif warnings > 0 then
    return { { str = tostring(warnings), hl = { "NvimTreeDiagnosticWarnIcon" } } }
  end
end

return DiagnosticCount
