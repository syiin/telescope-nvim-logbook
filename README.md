# telescope-logbook.nvim

Telescope extension for searching and browsing your nvim-logbook files.

## Requirements

- [nvim-telescope/telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)
- [syiin/nvim-logbook](https://github.com/syiin/nvim-logbook)
- [ripgrep](https://github.com/BurntSushi/ripgrep) (for content search)
- Neovim 0.7+

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
  "syiin/telescope-logbook.nvim",
  dependencies = {
    "syiin/nvim-logbook",
    "nvim-telescope/telescope.nvim",
  },
  config = function()
    require("telescope").load_extension("logbook")
  end
}
```

## Usage

```vim
:Telescope logbook       " Search content in all logbook files
:Telescope logbook_files " Browse logbook files
```

Suggested keymaps:
```lua
vim.keymap.set('n', '<leader>fl', '<cmd>Telescope logbook<cr>')
vim.keymap.set('n', '<leader>fL', '<cmd>Telescope logbook_files<cr>')
```

## License

MIT
