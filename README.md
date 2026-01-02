## Neovim Plugin

mtcli also includes a Neovim plugin that lets you practice typing by retyping the **chunk under your cursor** (single line, `if` block, multi-line list, etc.).

### Features

- Uses Tree-sitter to detect the smallest chunk starting on the cursor line
- Untyped characters appear gray
- Correctly typed characters show their original syntax highlighting
- Incorrectly typed characters turn red
- Results displayed as a virtual line when complete

### Installation (Neovim)

Using lazy.nvim:

```lua
{
  'mammadeBastar/mtcli-nvim',
  config = function()
    require('mtcli').setup({
      keymap = '<leader>mt',  -- or false to disable
    })
  end,
}
```

Using packer.nvim:

```lua
use {
  'mammadeBastar/mtcli-nvim',
  config = function()
    require('mtcli').setup()
  end,
}
```

### Usage (Neovim)

1. Place your cursor on a line you want to type
2. Run `:MtType` or press `<leader>mt` to type the **chunk under cursor**
3. Type the code (whitespace is normalized to single spaces; Enter/Tab can be used to type a normalized space)
4. Press `<Esc>` at any time to cancel
5. After completion, results appear below the chunk
6. Press `<Esc>` or `<Enter>` to dismiss results

To type the **entire buffer**:

- Run `:MtTypePage` or press `<leader>mp`

### Configuration (Neovim)

```lua
require('mtcli').setup({
  -- Keymap to trigger test (false to disable)
  keymap = '<leader>mt',
  -- Keymap to trigger test on entire buffer (false to disable)
  keymap_page = '<leader>mp',

  -- Max characters (0 = no limit)
  max_chars = 4000,

  -- Node types per filetype (Tree-sitter node names)
  node_types = {
    default = { 'function_declaration', 'function_definition' },
    lua = { 'function_declaration', 'function_definition', 'function' },
    go = { 'function_declaration', 'method_declaration', 'func_literal' },
    -- Add more filetypes as needed
  },

  -- Highlight group names (customize colors)
  hl_gray = 'MtcliGray',
  hl_wrong = 'MtcliWrong',
  hl_caret = 'MtcliCaret',
})
```

### Requirements (Neovim)

- Neovim 0.9.0+
- Tree-sitter parser installed for your language
