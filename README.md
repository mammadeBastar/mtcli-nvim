## Neovim Plugin

mtcli also includes a Neovim plugin that lets you practice typing by retyping the function under your cursor.

### Features

- Uses Tree-sitter to detect function boundaries
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

1. Place your cursor inside a function
2. Run `:MtType` or press `<leader>mt`
3. Type the function code (whitespace is normalized to single spaces)
4. Press `<Esc>` at any time to cancel
5. After completion, results appear below the function
6. Press `<Esc>` or `<Enter>` to dismiss results

### Configuration (Neovim)

```lua
require('mtcli').setup({
  -- Keymap to trigger test (false to disable)
  keymap = '<leader>mt',

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

## Development

### Building

```bash
go build -o mtcli ./cmd/mtcli
```

### Running tests

```bash
go test ./...
```

### Project structure

```
mtcli/
├── cmd/mtcli/          # CLI application entrypoint
├── internal/
│   ├── assets/         # Embedded word lists and quotes
│   ├── charts/         # ASCII chart rendering
│   ├── cli/            # CLI root command
│   ├── commands/       # Subcommands (test, stats, history, show)
│   ├── config/         # Configuration handling
│   ├── input/          # Raw terminal input
│   ├── metrics/        # WPM/accuracy calculations
│   ├── storage/        # SQLite persistence
│   ├── test/           # Typing session logic
│   ├── text/           # Text generation
│   └── ui/             # ANSI rendering
├── lua/mtcli/          # Neovim plugin (Lua)
│   ├── init.lua        # Plugin setup and entry point
│   ├── ts.lua          # Tree-sitter function detection
│   ├── normalize.lua   # Text normalization
│   ├── session.lua     # Typing session logic
│   ├── render.lua      # Extmark overlay rendering
│   └── ui.lua          # Results display
├── plugin/mtcli.lua    # Neovim autoload
├── doc/mtcli.txt       # Neovim help file
└── README.md
```

## License

MIT
