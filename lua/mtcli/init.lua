-- mtcli.nvim - Typing test on function under cursor
-- Main entry point

local M = {}

-- Default configuration
M.config = {
  -- Keymap to trigger typing test (set to false to disable)
  keymap = '<leader>mt',

  -- Node types to treat as "function" per filetype
  -- Keys are filetypes, values are lists of Tree-sitter node types
  node_types = {
    -- Defaults that work for many languages
    default = {
      'function_declaration',
      'function_definition',
      'method_declaration',
      'method_definition',
      'function_item',
      'arrow_function',
      'function_expression',
      'generator_function',
      'generator_function_declaration',
      'lambda_expression',
      'anonymous_function',
    },
    -- Language-specific overrides
    lua = {
      'function_declaration',
      'function_definition',
      'function',
    },
    python = {
      'function_definition',
      'lambda',
    },
    javascript = {
      'function_declaration',
      'function_expression',
      'arrow_function',
      'method_definition',
      'generator_function',
      'generator_function_declaration',
    },
    typescript = {
      'function_declaration',
      'function_expression',
      'arrow_function',
      'method_definition',
      'generator_function',
      'generator_function_declaration',
    },
    go = {
      'function_declaration',
      'method_declaration',
      'func_literal',
    },
    rust = {
      'function_item',
      'closure_expression',
    },
    c = {
      'function_definition',
    },
    cpp = {
      'function_definition',
      'lambda_expression',
    },
  },

  -- Maximum characters for the typing test (0 = no limit)
  max_chars = 4000,

  -- Highlight groups
  hl_gray = 'MtcliGray',
  hl_wrong = 'MtcliWrong',
  hl_caret = 'MtcliCaret',
}

-- Plugin state
M.state = nil

-- Setup function
function M.setup(opts)
  opts = opts or {}

  -- Merge user config with defaults
  M.config = vim.tbl_deep_extend('force', M.config, opts)

  -- Define highlight groups
  vim.api.nvim_set_hl(0, 'MtcliGray', { link = 'Comment', default = true })
  vim.api.nvim_set_hl(0, 'MtcliWrong', { fg = '#ff6b6b', bold = true, default = true })
  vim.api.nvim_set_hl(0, 'MtcliCaret', { reverse = true, default = true })

  -- Create user command
  vim.api.nvim_create_user_command('MtType', function()
    M.start()
  end, { desc = 'Start typing test on function under cursor' })

  -- Set up keymap if configured
  if M.config.keymap then
    vim.keymap.set('n', M.config.keymap, ':MtType<CR>', {
      desc = 'Typing test: function under cursor',
      silent = true,
    })
  end
end

-- Start the typing test
function M.start()
  local ts = require('mtcli.ts')
  local normalize = require('mtcli.normalize')
  local session = require('mtcli.session')
  local render = require('mtcli.render')
  local ui = require('mtcli.ui')

  -- Get current buffer
  local bufnr = vim.api.nvim_get_current_buf()

  -- Check if Tree-sitter is available
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr)
  if not ok or not parser then
    vim.notify('mtcli: Tree-sitter parser not available for this buffer', vim.log.levels.ERROR)
    return
  end

  -- Get function range under cursor
  local range = ts.get_function_range(bufnr, M.config)
  if not range then
    vim.notify('mtcli: No function found under cursor', vim.log.levels.WARN)
    return
  end

  -- Extract and normalize text
  local target, idx_to_pos = normalize.normalize_range(bufnr, range)
  if not target or #target == 0 then
    vim.notify('mtcli: Function is empty', vim.log.levels.WARN)
    return
  end

  -- Check max chars
  if M.config.max_chars > 0 and #target > M.config.max_chars then
    vim.notify(
      string.format('mtcli: Function too large (%d chars, max %d)', #target, M.config.max_chars),
      vim.log.levels.WARN
    )
    return
  end

  -- Save view state
  local saved_view = vim.fn.winsaveview()

  -- Initialize state
  M.state = {
    bufnr = bufnr,
    range = range,
    target = target,
    idx_to_pos = idx_to_pos,
    saved_view = saved_view,
  }

  -- Initialize rendering
  render.init(bufnr, M.config)
  render.gray_range(bufnr, range, idx_to_pos, 1, #target, M.config)

  -- Run the session
  local result = session.run(M.state, M.config, render)

  -- Show results or cleanup
  if result then
    ui.show_results(bufnr, range, result, M.config)
  else
    -- Cancelled - cleanup
    render.cleanup(bufnr)
    vim.fn.winrestview(saved_view)
  end

  M.state = nil
end

-- Cleanup function (called by ui module)
function M.cleanup()
  if M.state then
    local render = require('mtcli.render')
    render.cleanup(M.state.bufnr)
    vim.fn.winrestview(M.state.saved_view)
    M.state = nil
  end
end

return M

