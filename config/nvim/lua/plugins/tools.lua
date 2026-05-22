local function extend_unique(list, items)
  list = list or {}
  for _, item in ipairs(items) do
    if not vim.tbl_contains(list, item) then
      table.insert(list, item)
    end
  end
  return list
end

return {
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = extend_unique(opts.ensure_installed, {
        -- PHP / Laravel
        "intelephense",
        "phpstan",

        -- TypeScript / React / React Native
        "eslint_d",
        "prettier",

        -- Markdown / TOML / shell
        "bash-language-server",
        "markdownlint-cli2",
        "marksman",
        "shellcheck",
        "shfmt",
        "taplo",

        -- Neovim Lua config formatting
        "stylua",
      })
    end,
  },
  { "sindrets/diffview.nvim" },
  {
    "folke/flash.nvim",
    event = "VeryLazy",
    opts = {},
    keys = {
      { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash" },
      { "S", mode = { "n", "x", "o" }, function() require("flash").treesitter() end, desc = "Flash Treesitter" },
      { "r", mode = "o", function() require("flash").remote() end, desc = "Remote Flash" },
      { "R", mode = { "o", "x" }, function() require("flash").treesitter_search() end, desc = "Treesitter Search" },
      { "<c-s>", mode = { "c" }, function() require("flash").toggle() end, desc = "Toggle Flash Search" },
    },
  },
  {
    "akinsho/toggleterm.nvim",
    version = "*",
    opts = {
      size = function(term)
        if term.direction == "horizontal" then
          return 20
        elseif term.direction == "vertical" then
          return 80
        end
      end,
      hide_numbers = true,
      open_mapping = [[<M-\>]],
      direction = "horizontal",
      close_on_exit = true,
      float_opts = {
        border = "rounded",
        winblend = 0,
      },
    },
  },
  { "christoomey/vim-tmux-navigator" },
}
