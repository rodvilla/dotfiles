local function has_upward(path, start)
  local dir = vim.fs.normalize(start or vim.uv.cwd())

  while dir and dir ~= "" do
    if vim.uv.fs_stat(dir .. "/" .. path) then
      return true
    end

    local parent = vim.fs.dirname(dir)
    if not parent or parent == dir then
      break
    end
    dir = parent
  end

  return false
end

return {
  -- LazyVim's PHP extra defaults to phpactor; use the Intelephense server you already have.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        intelephense = {
          settings = {
            intelephense = {
              files = {
                -- Laravel projects can easily exceed Intelephense's smaller defaults.
                maxSize = 10000000,
              },
            },
          },
        },
      },
    },
  },

  -- PHP formatting order:
  -- 1. Project-local Laravel Pint when present.
  -- 2. Mago as a fast fallback for non-Pint PHP projects.
  {
    "stevearc/conform.nvim",
    optional = true,
    opts = function(_, opts)
      local util = require("conform.util")

      opts.formatters_by_ft = opts.formatters_by_ft or {}
      opts.formatters_by_ft.php = { "pint", "mago", stop_after_first = true }

      opts.formatters = opts.formatters or {}
      opts.formatters.pint = vim.tbl_deep_extend("force", opts.formatters.pint or {}, {
        condition = function(_, ctx)
          return has_upward("vendor/bin/pint", ctx.dirname) or has_upward("pint.json", ctx.dirname)
        end,
      })

      opts.formatters.mago = {
        command = util.find_executable({ "vendor/bin/mago" }, "mago"),
        args = { "fmt", "--stdin-input", "--stdin-filepath", "$FILENAME" },
        stdin = true,
        condition = function(_, ctx)
          return has_upward("vendor/bin/mago", ctx.dirname) or vim.fn.executable("mago") == 1
        end,
      }
    end,
  },

  -- Keep automatic PHP linting lightweight. Intelephense handles semantic diagnostics;
  -- `php -l` catches syntax errors immediately. PHPStan/Rector/Mago run on demand via commands.
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.php = { "php" }
    end,
  },
}
