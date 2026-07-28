return {
  -- Catppuccin (minimal integrations)
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "latte",
      integrations = {
        cmp = true,
        gitsigns = true,
        mason = true,
        mini = true,
        native_lsp = { enabled = true },
        treesitter = true,
        which_key = true,
      },
    },
  },

  -- Disable noice (biggest UI perf hit)
  { "folke/noice.nvim", enabled = false },

  -- Simpler notifications
  { "rcarriga/nvim-notify", opts = { timeout = 2000, render = "minimal", stages = "static" } },

  -- Bufferline (lighter config)
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        diagnostics = false,
        always_show_bufferline = false,
      },
    },
  },
}
