-- mtcli.nvim - Typing session
-- Main input loop and metrics tracking

local M = {}

local function tc(keys)
  return vim.api.nvim_replace_termcodes(keys, true, false, true)
end

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
  local keystrokes = 0      -- counts printable keypresses (does NOT decrement on backspace)
  local correct_count = 0   -- current correct characters in the buffer positions (can decrease on backspace)
  local typed_state = {}    -- typed_state[i] = true if correct, false if incorrect (for backspace accounting)
  local wrong_indices = {}  -- Set of indices currently wrong (for red overlay)
  local started_at = nil
  local ended_at = nil

  local KEY_ESC = tc('<Esc>')
  local KEY_BS = tc('<BS>')
  local KEY_DEL = tc('<Del>')
  local KEY_CR = tc('<CR>')
  local KEY_TAB = tc('<Tab>')

  -- Render initial state with caret
  render.update(bufnr, range, idx_to_pos, current_idx, #target, wrong_indices, config)
  render.move_cursor_to_idx(bufnr, idx_to_pos, current_idx)

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
    if char == KEY_ESC or char == '\27' then  -- Escape
      return nil
    elseif char == KEY_BS or char == KEY_DEL or char == '\8' or char == '\127' or char == '\b' then  -- Backspace/Delete
      if current_idx > 1 then
        local prev_idx = current_idx - 1

        -- Undo correctness accounting for the character we're removing
        local prev_state = typed_state[prev_idx]
        if prev_state ~= nil then
          if prev_state == true then
            correct_count = math.max(0, correct_count - 1)
          end
          typed_state[prev_idx] = nil
        end

        -- Remove wrong overlay for that index (it becomes untyped again)
        wrong_indices[prev_idx] = nil

        current_idx = prev_idx

        -- Update display
        render.update(bufnr, range, idx_to_pos, current_idx, #target, wrong_indices, config)
        render.move_cursor_to_idx(bufnr, idx_to_pos, current_idx)
      end
    else
      -- Allow natural \"line end\" keys to type a normalized space.
      -- When the target expects a single space (representing any whitespace/newline),
      -- treat Enter/Tab as typing that space.
      local expected = target:sub(current_idx, current_idx)
      if expected == ' ' then
        if char == KEY_CR or char == '\r' or char == '\n' or char == KEY_TAB then
          char = ' '
        end
      end

      if #char == 1 and char:byte() >= 32 then  -- Printable character (including space)
        -- Start timer on first character
        if not started_at then
          started_at = vim.loop.hrtime()
        end

        -- Check correctness
        keystrokes = keystrokes + 1
        if char == expected then
          correct_count = correct_count + 1
          typed_state[current_idx] = true
          wrong_indices[current_idx] = nil
        else
          wrong_indices[current_idx] = true
          typed_state[current_idx] = false
        end

        -- Advance
        current_idx = current_idx + 1

        -- Update display
        if current_idx <= #target then
          render.update(bufnr, range, idx_to_pos, current_idx, #target, wrong_indices, config)
          render.move_cursor_to_idx(bufnr, idx_to_pos, current_idx)
        end
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
  local raw_wpm = (keystrokes / 5) / minutes
  local net_wpm = (correct_count / 5) / minutes

  -- Accuracy
  local accuracy = (correct_count / #target) * 100

  -- Clear the gray/wrong overlays, keep for results display
  render.clear_overlays(bufnr)

  return {
    duration_s = duration_s,
    typed_count = keystrokes,
    correct_count = correct_count,
    wrong_count = #target - correct_count,
    raw_wpm = raw_wpm,
    net_wpm = net_wpm,
    accuracy = accuracy,
    target_len = #target,
  }
end

return M

