-- mtcli.nvim - Tree-sitter utilities
-- Chunk selection helpers

local M = {}

--- Get indent column (0-indexed) for a given line
---@param line string
---@return number
local function indent_col(line)
  local _, ws = line:find('^%s*')
  return ws or 0
end

--- Return a single-line range for the current cursor row
---@param bufnr number
---@param row number 0-indexed
---@return table
local function line_range(bufnr, row)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
  return {
    start_row = row,
    start_col = 0,
    end_row = row,
    end_col = #line,
  }
end

--- Find the smallest multiline Tree-sitter node that starts at the cursor line.
--- We prefer nodes that start at the line's indentation column, so `if ...` selects
--- the `if` block and not an inner expression node.
---@param bufnr number
---@param row number 0-indexed cursor row
---@param col number 0-indexed cursor col
---@return table|nil
local function smallest_multiline_node_starting_on_line(bufnr, row, col)
  local line = vim.api.nvim_buf_get_lines(bufnr, row, row + 1, false)[1] or ''
  local want_col = indent_col(line)

  local node = vim.treesitter.get_node({
    bufnr = bufnr,
    pos = { row, col },
  })
  if not node then
    return nil
  end

  local fallback = nil
  local current = node
  while current do
    local sr, sc, er, ec = current:range()
    if sr == row and er > row then
      local r = { start_row = sr, start_col = sc, end_row = er, end_col = ec }
      -- Prefer nodes that begin at indentation
      if sc == want_col then
        return r
      end
      if not fallback then
        fallback = r
      end
    end
    current = current:parent()
  end

  return fallback
end

--- Get the chunk range under cursor using the requested logic:
--- - If the cursor line begins a multiline construct (block/list/call split across lines), test that chunk.
--- - Otherwise, test only the current line.
---@param bufnr number
---@return table|nil Range { start_row, start_col, end_row, end_col } (0-indexed, end exclusive)
function M.get_chunk_range(bufnr)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local row = cursor[1] - 1
  local col = cursor[2]

  local multiline = smallest_multiline_node_starting_on_line(bufnr, row, col)
  if multiline then
    return multiline
  end

  return line_range(bufnr, row)
end

--- Get a range covering the entire buffer
---@param bufnr number
---@return table
function M.get_buffer_range(bufnr)
  local line_count = vim.api.nvim_buf_line_count(bufnr)
  if line_count == 0 then
    return { start_row = 0, start_col = 0, end_row = 0, end_col = 0 }
  end

  local last_row = line_count - 1
  local last_line = vim.api.nvim_buf_get_lines(bufnr, last_row, last_row + 1, false)[1] or ''

  return {
    start_row = 0,
    start_col = 0,
    end_row = last_row,
    end_col = #last_line,
  }
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

