return {
  -- Telescope tweaks
  {
    "nvim-telescope/telescope.nvim",
    opts = {
      defaults = {
        layout_strategy = "horizontal",
        layout_config = { prompt_position = "top" },
        sorting_strategy = "ascending",
        file_ignore_patterns = { "node_modules", ".git/", "dist/", "build/" },
      },
    },
  },

  -- Gitsigns (no inline blame — it's slow)
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      current_line_blame = false,
    },
  },

  -- Surround
  { "echasnovski/mini.surround", opts = {} },

  -- Todo comments
  {
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    opts = {},
  },
}
