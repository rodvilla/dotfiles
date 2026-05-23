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
  -- LSP Config
  {
    "neovim/nvim-lspconfig",
    dependencies = { "jose-elias-alvarez/typescript.nvim" },
    init = function()
      require("snacks.util.lsp").on(function(buffer, client)
        vim.keymap.set("n", "<leader>co", "TypescriptOrganizeImports", { buffer = buffer, desc = "Organize Imports" })
        vim.keymap.set("n", "<leader>cR", "TypescriptRenameFile", { desc = "Rename File", buffer = buffer })
      end)
    end,
    opts = {
      servers = {
        pyright = {},
        tsserver = {},
        intelephense = {
          settings = {
            intelephense = {
              files = {
                maxSize = 10000000,
              },
            },
          },
        },
      },
      setup = {
        tsserver = function(_, opts)
          require("typescript").setup({ server = opts })
          return true
        end,
      },
    },
  },

  -- TreeSitter
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "bash",
        "html",
        "javascript",
        "json",
        "lua",
        "markdown",
        "markdown_inline",
        "php",
        "python",
        "query",
        "regex",
        "tsx",
        "typescript",
        "vim",
        "yaml",
      },
    },
  },

  -- Laravel
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

  -- Laravel blink.cmp integration
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

  -- PHP formatting
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

  -- PHP linting
  {
    "mfussenegger/nvim-lint",
    optional = true,
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.php = { "php" }
    end,
  },

  -- neotest
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