return {
  -- LSP — only servers NOT already provided by LazyVim extras
  -- (typescript, python, go, json, yaml extras handle their own servers)
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        lua_ls = {
          settings = {
            Lua = {
              workspace = { checkThirdParty = false },
              diagnostics = { globals = { "vim" } },
            },
          },
        },
        bashls = {},
        dockerls = {},
        html = {},
        cssls = {},
      },
      diagnostics = {
        underline = true,
        update_in_insert = false,
        virtual_text = { spacing = 4, source = "if_many", prefix = "●" },
        severity_sort = true,
      },
    },
  },

  -- Mason — only tools not auto-installed by extras
  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = {
        "lua-language-server",
        "bash-language-server",
        "dockerfile-language-server",
        "html-lsp",
        "css-lsp",
        "stylua",
        "shfmt",
        "shellcheck",
        "prettier",
      },
    },
  },

  -- Formatting
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        css = { "prettier" },
        html = { "prettier" },
        json = { "prettier" },
        yaml = { "prettier" },
        markdown = { "prettier" },
      },
      format_on_save = {
        timeout_ms = 2000,
        lsp_format = "fallback",
      },
    },
  },
}
