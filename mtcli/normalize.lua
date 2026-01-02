-- mtcli.nvim - Text normalization
-- Normalize function text and build index-to-buffer-position mapping

local M = {}

--- Normalize text from a buffer range
--- Collapses all whitespace (spaces, tabs, newlines) into single spaces
--- and builds a mapping from each normalized char index to buffer position
---@param bufnr number Buffer number
---@param range table Range { start_row, start_col, end_row, end_col } (0-indexed)
---@return string normalized_text The normalized typing target
---@return table idx_to_pos Array mapping char index to { row, col } in buffer
function M.normalize_range(bufnr, range)
  -- Get lines in the range
  local lines = vim.api.nvim_buf_get_text(
    bufnr,
    range.start_row,
    range.start_col,
    range.end_row,
    range.end_col,
    {}
  )

  local normalized = {}
  local idx_to_pos = {}
  local in_whitespace = false

  for line_idx, line in ipairs(lines) do
    -- Calculate actual row in buffer
    local row = range.start_row + line_idx - 1

    -- For first line, start col is range.start_col; for others, it's 0
    local start_col = (line_idx == 1) and range.start_col or 0

    -- Iterate through characters in the line
    local col = start_col
    for char in line:gmatch('.') do
      local is_ws = char:match('%s') ~= nil

      if is_ws then
        if not in_whitespace then
          -- Start of whitespace run - emit single space
          table.insert(normalized, ' ')
          table.insert(idx_to_pos, { row = row, col = col })
          in_whitespace = true
        end
        -- Skip additional whitespace characters (they collapse)
      else
        -- Non-whitespace character
        table.insert(normalized, char)
        table.insert(idx_to_pos, { row = row, col = col })
        in_whitespace = false
      end

      col = col + #char  -- Handle multi-byte (UTF-8)
    end

    -- End of line is whitespace (newline) - unless it's the last line
    if line_idx < #lines then
      if not in_whitespace then
        -- Emit space for the newline
        table.insert(normalized, ' ')
        -- Map to end of current line
        table.insert(idx_to_pos, { row = row, col = col })
        in_whitespace = true
      end
    end
  end

  -- Build final string
  local result = table.concat(normalized)

  -- Trim leading/trailing whitespace
  local trimmed, trim_start, trim_end = M.trim_with_offsets(result)

  -- Adjust idx_to_pos to match trimmed string
  local trimmed_idx_to_pos = {}
  for i = trim_start, #idx_to_pos - trim_end do
    table.insert(trimmed_idx_to_pos, idx_to_pos[i])
  end

  return trimmed, trimmed_idx_to_pos
end

--- Trim string and return offsets
---@param s string Input string
---@return string trimmed Trimmed string
---@return number start_offset Number of chars trimmed from start (1-indexed first kept char)
---@return number end_offset Number of chars trimmed from end
function M.trim_with_offsets(s)
  local start_idx = 1
  local end_idx = #s

  -- Find first non-whitespace
  while start_idx <= end_idx and s:sub(start_idx, start_idx):match('%s') do
    start_idx = start_idx + 1
  end

  -- Find last non-whitespace
  while end_idx >= start_idx and s:sub(end_idx, end_idx):match('%s') do
    end_idx = end_idx - 1
  end

  if start_idx > end_idx then
    return '', 1, 0
  end

  local trimmed = s:sub(start_idx, end_idx)
  local trim_end = #s - end_idx

  return trimmed, start_idx, trim_end
end

--- Get character at index (1-indexed, UTF-8 safe)
---@param s string The string
---@param idx number 1-indexed character position
---@return string|nil The character or nil if out of bounds
function M.char_at(s, idx)
  if idx < 1 or idx > #s then
    return nil
  end
  return s:sub(idx, idx)
end

return M

