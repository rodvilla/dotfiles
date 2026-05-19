-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local function root_dir()
  if LazyVim and LazyVim.root then
    return LazyVim.root()
  end
  return vim.uv.cwd()
end

local function executable(bin)
  local local_bin = root_dir() .. "/vendor/bin/" .. bin
  if vim.fn.executable(local_bin) == 1 then
    return vim.fn.shellescape(local_bin)
  end
  return bin
end

local function terminal(command)
  Snacks.terminal(command, { cwd = root_dir() })
end

local function current_file()
  return vim.fn.shellescape(vim.api.nvim_buf_get_name(0))
end

local commands = {
  pint_file = function()
    return executable("pint") .. " " .. current_file()
  end,
  pint_project = function()
    return executable("pint")
  end,
  phpstan = function()
    return executable("phpstan") .. " analyze --memory-limit=1G"
  end,
  rector_dry = function()
    return executable("rector") .. " process --dry-run"
  end,
  rector_apply = function()
    return executable("rector") .. " process"
  end,
  mago_lint = function()
    return executable("mago") .. " lint --reporting-format=medium"
  end,
  mago_fix = function()
    return executable("mago") .. " lint --fix --format-after-fix"
  end,
}

vim.api.nvim_create_user_command("PhpPint", function()
  terminal(commands.pint_file())
end, { desc = "Run Pint on the current PHP file" })

vim.api.nvim_create_user_command("PhpPintAll", function()
  terminal(commands.pint_project())
end, { desc = "Run Pint on the project" })

vim.api.nvim_create_user_command("PhpStan", function()
  terminal(commands.phpstan())
end, { desc = "Run PHPStan analyze" })

vim.api.nvim_create_user_command("RectorDry", function()
  terminal(commands.rector_dry())
end, { desc = "Run Rector dry run" })

vim.api.nvim_create_user_command("Rector", function()
  terminal(commands.rector_apply())
end, { desc = "Run Rector and apply changes" })

vim.api.nvim_create_user_command("MagoLint", function()
  terminal(commands.mago_lint())
end, { desc = "Run Mago lint" })

vim.api.nvim_create_user_command("MagoFix", function()
  terminal(commands.mago_fix())
end, { desc = "Run Mago safe fixes and format" })

vim.keymap.set("n", "<leader>cpl", function()
  terminal(commands.pint_file())
end, { desc = "PHP Pint Current File" })

vim.keymap.set("n", "<leader>cpL", function()
  terminal(commands.pint_project())
end, { desc = "PHP Pint Project" })

vim.keymap.set("n", "<leader>cps", function()
  terminal(commands.phpstan())
end, { desc = "PHPStan Analyze" })

vim.keymap.set("n", "<leader>cpr", function()
  terminal(commands.rector_dry())
end, { desc = "Rector Dry Run" })

vim.keymap.set("n", "<leader>cpR", function()
  terminal(commands.rector_apply())
end, { desc = "Rector Apply" })

vim.keymap.set("n", "<leader>cpm", function()
  terminal(commands.mago_lint())
end, { desc = "Mago Lint" })

vim.keymap.set("n", "<leader>cpM", function()
  terminal(commands.mago_fix())
end, { desc = "Mago Fix" })
