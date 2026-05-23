return {
  {
    "nvim-telescope/telescope.nvim",
    keys = {
      {
        "<leader>fp",
        function() require("telescope.builtin").find_files({ cwd = require("lazy.core.config").options.root }) end,
        desc = "Find Plugin File",
      },
      {
        "<leader>fg",
        function() require("telescope.builtin").live_grep({ no_ignore = true, hidden = true }) end,
        desc = "Grep (with hidden & gitignored)",
      },
    },
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        winblend = 0,
        file_ignore_patterns = { "node_modules", ".git" },
        vimgrep_arguments = { "rg", "--hidden", "--glob=!**/.git/**", "--glob=!**/node_modules/**" },
      },
    },
  },
}