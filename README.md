# What is it

A plugin to send a command to the terminal that makes sense. The terminal is picked in that order
- The most recent visible terminal
- If no visible terminal, use the most recent hidden terminal:
-- In that case, we show that hidden terminal in its last visible window.
-- If its last visible window is closed, use a new window.

## How is it different from similar plugins

Unlike other similar plugins this plugin automatically choose a terminal (the most recent one) so you do not
have to "mark" the terminal you want to use.

## Use case

I mainly use with a [keymap](#example-of-keybinding) to quickly repeat last command (`SendToTerm !!`).

# Setup

Like any other plugin add "ilan/nvim-send-to-first-term" to your package manager and call
`require("nvim-send-to-first-term").setup()`.

## Lazy

```lua
{
  "ilan-schemoul/nvim-send-to-first-term",
  opts = {},
}
```

# Commands

```vim
:SendToTerm <command>
```
If no command is provided an input is shown to you so you can type your command.

The last opened, non-hidden, terminal in your current tab is used. If no terminal is found
a new one is created and the command is sent to it.

# Example of keybinding

```lua
-- Repeat last command
vim.keymap.set("n", "<leader>pr", "<cmd>SendToTerm !!<cr>")
-- Open a ui input so you can type any command
vim.keymap.set("n", "<leader>ps", "<cmd>SendToTerm<cr>")
-- Run make
vim.keymap.set("n", "<leader>ps", "<cmd>SendToTerm make<cr>")
```
