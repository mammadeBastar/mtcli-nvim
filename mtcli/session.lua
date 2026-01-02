-- mtcli.nvim - Typing session
-- Main input loop and metrics tracking

local M = {}

--- Run a typing session
---@param state table Plugin state { bufnr, range, target, idx_to_pos, saved_view }
---@param config table Plugin configuration
---@param render table Render module
---@return table|nil Result table or nil if cancelled
function M.run(state, config, render)
  local target = state.target
  local idx_to_pos = state.idx_to_pos
  local bufnr = state.bufnr
  local range = state.range

  -- Session state
  local current_idx = 1  -- 1-indexed position in target
  local typed_count = 0
  local correct_count = 0
  local wrong_indices = {}  -- Set of indices that were typed incorrectly
  local started_at = nil
  local ended_at = nil

  -- Render initial state with caret
  render.update(bufnr, range, idx_to_pos, current_idx, #target, wrong_indices, config)

  -- Main input loop
  while current_idx <= #target do
    -- Force redraw to show updates
    vim.cmd('redraw')

    -- Get a character
    local ok, char = pcall(vim.fn.getcharstr)
    if not ok then
      -- Error or interrupt
      return nil
    end

    -- Handle special keys
    if char == '\27' then  -- Escape
      return nil
    elseif char == '\8' or char == '\127' then  -- Backspace (BS or DEL)
      if current_idx > 1 then
        current_idx = current_idx - 1
        -- Remove from wrong set if it was there
        wrong_indices[current_idx] = nil
        -- Update display
        render.update(bufnr, range, idx_to_pos, current_idx, #target, wrong_indices, config)
      end
    elseif #char == 1 and char:byte() >= 32 then  -- Printable character
      -- Start timer on first character
      if not started_at then
        started_at = vim.loop.hrtime()
      end

      -- Get expected character
      local expected = target:sub(current_idx, current_idx)

      -- Check correctness
      typed_count = typed_count + 1
      if char == expected then
        correct_count = correct_count + 1
      else
        wrong_indices[current_idx] = true
      end

      -- Advance
      current_idx = current_idx + 1

      -- Update display
      if current_idx <= #target then
        render.update(bufnr, range, idx_to_pos, current_idx, #target, wrong_indices, config)
      end
    end
    -- Ignore other keys (arrows, function keys, etc.)
  end

  -- Test complete
  ended_at = vim.loop.hrtime()

  -- Calculate results
  local duration_ns = ended_at - (started_at or ended_at)
  local duration_s = duration_ns / 1e9
  if duration_s < 0.1 then
    duration_s = 0.1  -- Avoid division by zero
  end

  local minutes = duration_s / 60

  -- WPM calculations (standard: 5 chars = 1 word)
  local raw_wpm = (typed_count / 5) / minutes
  local net_wpm = (correct_count / 5) / minutes

  -- Accuracy
  local accuracy = 0
  if typed_count > 0 then
    accuracy = (correct_count / typed_count) * 100
  end

  -- Clear the gray/wrong overlays, keep for results display
  render.clear_overlays(bufnr)

  return {
    duration_s = duration_s,
    typed_count = typed_count,
    correct_count = correct_count,
    wrong_count = typed_count - correct_count,
    raw_wpm = raw_wpm,
    net_wpm = net_wpm,
    accuracy = accuracy,
    target_len = #target,
  }
end

return M

