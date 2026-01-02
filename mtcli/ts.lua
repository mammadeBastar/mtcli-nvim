-- mtcli.nvim - Tree-sitter utilities
-- Find function node under cursor

local M = {}

--- Get the list of function node types for the current filetype
---@param config table Plugin configuration
---@return string[] List of node type names
function M.get_function_types(config)
  local ft = vim.bo.filetype

  -- Check for filetype-specific config
  if config.node_types[ft] then
    return config.node_types[ft]
  end

  -- Fall back to defaults
  return config.node_types.default or {}
end

--- Check if a node type is a function type
---@param node_type string The node type to check
---@param function_types string[] List of function type names
---@return boolean
function M.is_function_type(node_type, function_types)
  for _, ft in ipairs(function_types) do
    if node_type == ft then
      return true
    end
  end
  return false
end

--- Find the function node containing the cursor
---@param bufnr number Buffer number
---@param config table Plugin configuration
---@return table|nil Range table { start_row, start_col, end_row, end_col } (0-indexed)
function M.get_function_range(bufnr, config)
  -- Get cursor position (1-indexed)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1  -- Convert to 0-indexed
  local col = cursor[2]

  -- Get the node at cursor
  local node = vim.treesitter.get_node({
    bufnr = bufnr,
    pos = { row, col },
  })

  if not node then
    return nil
  end

  -- Get function types for this filetype
  local function_types = M.get_function_types(config)

  -- Walk up the tree to find a function node
  local current = node
  while current do
    local node_type = current:type()

    if M.is_function_type(node_type, function_types) then
      -- Found a function node, get its range
      local start_row, start_col, end_row, end_col = current:range()
      return {
        start_row = start_row,
        start_col = start_col,
        end_row = end_row,
        end_col = end_col,
      }
    end

    current = current:parent()
  end

  return nil
end

--- Get the text content of a range
---@param bufnr number Buffer number
---@param range table Range table { start_row, start_col, end_row, end_col }
---@return string[] Lines of text
function M.get_range_text(bufnr, range)
  return vim.api.nvim_buf_get_text(
    bufnr,
    range.start_row,
    range.start_col,
    range.end_row,
    range.end_col,
    {}
  )
end

return M

