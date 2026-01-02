-- mtcli.nvim - Rendering with extmarks
-- Overlay management: gray untyped, red wrong, caret

local M = {}

-- Namespace for all mtcli extmarks
M.ns = vim.api.nvim_create_namespace('mtcli')

--- Initialize highlight groups
---@param bufnr number Buffer number (unused, but for consistency)
---@param config table Plugin configuration
function M.init(bufnr, config)
  -- Ensure highlight groups exist
  vim.api.nvim_set_hl(0, config.hl_gray, { link = 'Comment', default = true })
  vim.api.nvim_set_hl(0, config.hl_wrong, { fg = '#ff6b6b', bold = true, default = true })
  vim.api.nvim_set_hl(0, config.hl_caret, { reverse = true, default = true })
end

--- Gray the entire function range initially
---@param bufnr number Buffer number
---@param range table Range { start_row, start_col, end_row, end_col }
---@param idx_to_pos table Mapping from char index to buffer position
---@param from_idx number Start index (1-indexed)
---@param to_idx number End index (1-indexed, inclusive)
function M.gray_range(bufnr, range, idx_to_pos, from_idx, to_idx)
  -- Clear any existing marks first
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, range.start_row, range.end_row + 1)

  -- Apply gray highlight to each character position
  for i = from_idx, to_idx do
    local pos = idx_to_pos[i]
    if pos then
      M.set_char_highlight(bufnr, pos.row, pos.col, 'MtcliGray')
    end
  end
end

--- Update the display based on current typing state
---@param bufnr number Buffer number
---@param range table Range { start_row, start_col, end_row, end_col }
---@param idx_to_pos table Mapping from char index to buffer position
---@param current_idx number Current typing position (1-indexed)
---@param total number Total characters
---@param wrong_indices table Set of indices that were typed wrong
---@param config table Plugin configuration
function M.update(bufnr, range, idx_to_pos, current_idx, total, wrong_indices, config)
  -- Clear all existing marks in the range
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, range.start_row, range.end_row + 1)

  -- 1. Characters before current_idx that were wrong -> red
  for i = 1, current_idx - 1 do
    if wrong_indices[i] then
      local pos = idx_to_pos[i]
      if pos then
        M.set_char_highlight(bufnr, pos.row, pos.col, config.hl_wrong)
      end
    end
    -- Correct characters: no overlay (shows original TS colors)
  end

  -- 2. Current character -> caret highlight
  if current_idx <= total then
    local pos = idx_to_pos[current_idx]
    if pos then
      M.set_char_highlight(bufnr, pos.row, pos.col, config.hl_caret)
    end
  end

  -- 3. Characters after current_idx -> gray
  for i = current_idx + 1, total do
    local pos = idx_to_pos[i]
    if pos then
      M.set_char_highlight(bufnr, pos.row, pos.col, config.hl_gray)
    end
  end
end

--- Set highlight for a single character
---@param bufnr number Buffer number
---@param row number Row (0-indexed)
---@param col number Column (0-indexed)
---@param hl_group string Highlight group name
function M.set_char_highlight(bufnr, row, col, hl_group)
  -- Get the line to determine character width
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1]
  if not line then
    return
  end

  -- Calculate end column (handle multi-byte characters)
  local end_col = col + 1
  if col < #line then
    -- Try to get proper character width
    local char = line:sub(col + 1, col + 1)
    if char then
      end_col = col + #char
    end
  end

  -- Clamp to line length
  if end_col > #line then
    end_col = #line
  end

  -- Don't create zero-width marks
  if end_col <= col then
    return
  end

  pcall(vim.api.nvim_buf_set_extmark, bufnr, M.ns, row, col, {
    end_row = row,
    end_col = end_col,
    hl_group = hl_group,
    priority = 1000,  -- High priority to override other highlights
  })
end

--- Clear all overlay extmarks (but not virt_lines)
---@param bufnr number Buffer number
function M.clear_overlays(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
end

--- Full cleanup - clear all extmarks
---@param bufnr number Buffer number
function M.cleanup(bufnr)
  vim.api.nvim_buf_clear_namespace(bufnr, M.ns, 0, -1)
end

return M

