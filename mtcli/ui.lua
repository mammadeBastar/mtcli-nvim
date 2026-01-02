-- mtcli.nvim - UI utilities
-- Results display and cleanup

local M = {}

-- Reference to render module's namespace
local render_ns = nil

--- Show results as a virtual line below the function
---@param bufnr number Buffer number
---@param range table Range { start_row, start_col, end_row, end_col }
---@param result table Result from session { duration_s, typed_count, correct_count, raw_wpm, net_wpm, accuracy }
---@param config table Plugin configuration
function M.show_results(bufnr, range, result, config)
  local render = require('mtcli.render')
  render_ns = render.ns

  -- Format the results line
  local results_text = string.format(
    ' mtcli: %.1f wpm | raw %.1f | acc %.1f%% | %.1fs | %d/%d chars (Esc to close)',
    result.net_wpm,
    result.raw_wpm,
    result.accuracy,
    result.duration_s,
    result.correct_count,
    result.target_len
  )

  -- Create virtual line at the end of the function
  local virt_line = { { results_text, 'MtcliResults' } }

  -- Define results highlight (green-ish for success feel)
  vim.api.nvim_set_hl(0, 'MtcliResults', {
    fg = '#98c379',
    bg = '#2c323c',
    italic = true,
    default = true,
  })

  -- Add the virtual line extmark
  local mark_id = vim.api.nvim_buf_set_extmark(bufnr, render_ns, range.end_row, 0, {
    virt_lines = { virt_line },
    virt_lines_above = false,
  })

  -- Store mark_id for cleanup
  M.results_mark_id = mark_id
  M.results_bufnr = bufnr

  -- Set up Escape keymap to dismiss
  M.setup_dismiss_keymap(bufnr)

  -- Force redraw
  vim.cmd('redraw')
end

--- Set up temporary keymap to dismiss results
---@param bufnr number Buffer number
function M.setup_dismiss_keymap(bufnr)
  -- Create buffer-local keymap for Escape
  vim.keymap.set('n', '<Esc>', function()
    M.dismiss()
  end, {
    buffer = bufnr,
    desc = 'Dismiss mtcli results',
    nowait = true,
  })

  -- Also allow Enter to dismiss
  vim.keymap.set('n', '<CR>', function()
    M.dismiss()
  end, {
    buffer = bufnr,
    desc = 'Dismiss mtcli results',
    nowait = true,
  })

  -- Store that we set up keymaps
  M.keymaps_bufnr = bufnr
end

--- Dismiss results and cleanup
function M.dismiss()
  -- Clear the extmark with results
  if M.results_bufnr and render_ns then
    vim.api.nvim_buf_clear_namespace(M.results_bufnr, render_ns, 0, -1)
  end

  -- Remove keymaps
  if M.keymaps_bufnr then
    pcall(vim.keymap.del, 'n', '<Esc>', { buffer = M.keymaps_bufnr })
    pcall(vim.keymap.del, 'n', '<CR>', { buffer = M.keymaps_bufnr })
  end

  -- Restore view if mtcli module has state
  local ok, mtcli = pcall(require, 'mtcli')
  if ok and mtcli.state and mtcli.state.saved_view then
    vim.fn.winrestview(mtcli.state.saved_view)
  end

  -- Clear state
  M.results_mark_id = nil
  M.results_bufnr = nil
  M.keymaps_bufnr = nil

  -- Force redraw
  vim.cmd('redraw')
end

return M

