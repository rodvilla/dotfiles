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
}
