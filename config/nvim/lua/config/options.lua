-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Use Intelephense for PHP instead of LazyVim's default phpactor server.
vim.g.lazyvim_php_lsp = "intelephense"

-- Only run Prettier when a project explicitly opts in with a Prettier config.
-- This avoids surprise formatting churn in repos without Prettier settings.
vim.g.lazyvim_prettier_needs_config = true

-- Disable import order check since extras are managed via lazyvim.json
vim.g.lazyvim_check_order = false

-- Use Telescope as the default picker instead of Snacks
vim.g.lazyvim_picker = "telescope"
