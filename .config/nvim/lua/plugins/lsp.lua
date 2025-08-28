--INFO: Tabelas LUA para as paradas que preciso em geral
--INFO: adicione LSPs na tabela servers, Linters e Formatters na tabela styles e DAPs na tabela daps (em ./dap.lua)
local servers = {
  "clangd",
  "lua_ls",
  "html",
  "cssls",
  "marksman",
  "bashls",
  "ansiblels",
  "pyright",
  "jsonls",
  "eslint",
  "asm_lsp",
}
local stylers = { "stylua", "asmfmt", "shellcheck", "shfmt", "flake8", "black", "ansible-lint", "isort", "prettier" }

return {

  --INFO: stylers

  {
    "williamboman/mason.nvim",
    opts = {
      ensure_installed = stylers,
    },
  },

  --INFO: servers

  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = servers,
    },
  },

  --INFO: lspconfig

  {
    "neovim/nvim-lspconfig",
    config = function()
      vim.diagnostic.config({
        virtual_text = {
          prefix = "●",
          spacing = 2,
        },
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      local handlers = {
        ["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, { border = "rounded" }),
        ["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, { border = "rounded" }),
      }

      local lspconfig = require("lspconfig")
      --INFO: carregando os lsps settados em servers
      for _, server in ipairs(servers) do
        lspconfig[server].setup({ handlers = handlers, on_attach = on_attach })
      end

      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
      vim.keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, {})
    end,
  },
}
