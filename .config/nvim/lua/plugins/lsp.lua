local servers = {
  "clangd",
  "lua_ls",
  "tsserver",
  "html",
  "cssls",
  "marksman",
  "bashls",
  "gopls",
  "ansiblels",
  "pyright",
  "jsonls",
  "eslint",
  "asm_lsp",
}

local tools = {
  "stylua",
  "asmfmt",
  "shfmt",
  "black",
  "isort",
  "prettier",
  "shellcheck",
  "flake8",
  "ansible-lint",
}

return {
  {
    "mason-org/mason.nvim",
    opts = { ensure_installed = tools },
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
    "lark-parser/vim-lark-syntax",
    ft = "lark",
  },
}
