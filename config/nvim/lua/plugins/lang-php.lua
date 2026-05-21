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
  -- Laravel-specific navigation, Artisan/Composer commands, Sail integration, and completions.
  {
    "adibhanna/laravel.nvim",
    event = "VeryLazy",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "nvim-lua/plenary.nvim",
    },
    keys = {
      { "<leader>la", "<cmd>Artisan<cr>", desc = "Laravel Artisan" },
      { "<leader>lc", "<cmd>Composer<cr>", desc = "Composer" },
      { "<leader>lr", "<cmd>LaravelRoute<cr>", desc = "Laravel Routes" },
      { "<leader>lm", "<cmd>LaravelMake<cr>", desc = "Laravel Make" },
      { "<leader>ls", "<cmd>LaravelStatus<cr>", desc = "Laravel Status" },
    },
    opts = {
      notifications = true,
      debug = false,
      keymaps = false,
      sail = {
        enabled = true,
        auto_detect = true,
      },
    },
  },

  -- laravel.nvim uses the PHP parser for accurate framework-aware navigation.
  {
    "nvim-treesitter/nvim-treesitter",
    optional = true,
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      if not vim.tbl_contains(opts.ensure_installed, "php") then
        table.insert(opts.ensure_installed, "php")
      end
    end,
  },

  {
    "saghen/blink.cmp",
    optional = true,
    opts = function(_, opts)
      opts.sources = opts.sources or {}
      opts.sources.default = opts.sources.default or {}
      opts.sources.providers = opts.sources.providers or {}

      if not vim.tbl_contains(opts.sources.default, "laravel") then
        table.insert(opts.sources.default, 1, "laravel")
      end

      opts.sources.providers.laravel = {
        name = "laravel",
        module = "laravel.blink_source",
      }
    end,
  },

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

  -- Keep PHPUnit results in neotest's bottom output panel instead of opening floating output.
  {
    "nvim-neotest/neotest",
    optional = true,
    opts = function(_, opts)
      opts.output = vim.tbl_deep_extend("force", opts.output or {}, {
        open_on_run = false,
      })
      opts.output_panel = vim.tbl_deep_extend("force", opts.output_panel or {}, {
        open = "botright split | resize 15",
      })
    end,
  },
}
