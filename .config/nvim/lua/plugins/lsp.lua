local servers = {
  "clangd",
  "lua_ls",
  "html",
  "cssls",
  "marksman",
  "bashls",
  "gopls",
  "ruff",
  "ansiblels",
  "pyright",
  "jsonls",
  "eslint",
}

local tools = {
  "stylua",
  "asmfmt",
  "shfmt",
  "black",
  "isort",
  "prettier",
  "gofumpt",
  "goimports-reviser",
  "golines",
  "shellcheck",
  "flake8",
  "ansible-lint",
}

return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    opts = {
      ensure_installed = vim.list_extend(vim.deepcopy(servers), tools),
      auto_update = false,
      run_on_start = true,
    },
  },
  {
    "mason-org/mason.nvim",
    config = true,
  },
  {
    "mason-org/mason-lspconfig.nvim",
    opts = { ensure_installed = servers },
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.diagnostic.config({
        virtual_text = { prefix = "●", spacing = 2 },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      local lspconfig = require("lspconfig")

      local on_attach = function(_, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end

        map("n", "gd", vim.lsp.buf.definition, "Definition")
        map("n", "K", vim.lsp.buf.hover, "Hover")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("n", "gi", vim.lsp.buf.implementation, "Implementation")
      end

      for _, server in ipairs(servers) do
        lspconfig[server].setup({ on_attach = on_attach })
      end
    end,
  },

  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format", "ruff_fix", "ruff_organize_imports" },
        go = { "gofumpt", "goimports-reviser", "golines" },
      },
    },
  },

  {
    "lark-parser/vim-lark-syntax",
    ft = "lark",
  },
}
