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
  "basedpyright",
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
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
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

      local capabilities = vim.lsp.protocol.make_client_capabilities()
      capabilities.offsetEncoding = { "utf-16" }

      local on_attach = function(client, bufnr)
        local map = function(mode, lhs, rhs, desc)
          vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, silent = true, desc = desc })
        end

        map("n", "gd", vim.lsp.buf.definition, "Definition")
        map("n", "K", vim.lsp.buf.hover, "Hover")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("n", "gi", vim.lsp.buf.implementation, "Implementation")
        map("n", "<leader>cl", vim.lsp.codelens.run, "Run Code Lens")
        map("n", "gr", require("telescope.builtin").lsp_references, "References")

        -- if client.supports_method("textDocument/inlayHint") then
        --   vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        -- end

        if client.supports_method("textDocument/codeLens") then
          local codelens_group = vim.api.nvim_create_augroup("LSPCodeLens" .. bufnr, { clear = true })
          vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
            buffer = bufnr,
            group = codelens_group,
            callback = function()
              vim.lsp.codelens.refresh({ bufnr = bufnr })
            end,
          })
        end

        if client.supports_method("textDocument/formatting") then
          map("n", "<leader>cf", function()
            vim.lsp.buf.format({ bufnr = bufnr })
          end, "Format")
        end
      end

      for _, server in ipairs(servers) do
        if server ~= "basedpyright" then
          lspconfig[server].setup({
            on_attach = on_attach,
            capabilities = capabilities,
          })
        end
      end

      lspconfig.basedpyright.setup({
        on_attach = on_attach,
        capabilities = capabilities,
        settings = {
          basedpyright = {
            typeCheckingMode = "basic",
            analysis = {
              inlayhints = {
                variableTypes = true,
                functionReturnTypes = true,
                callArguments = true,
                genericTypes = true,
              },
            },
          },
        },
      })
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

  {

    "filipdutescu/renamer.nvim",
    event = "VeryLazy",
    config = function()
      require("renamer").setup({})
    end,
    keys = {
      {
        "<leader>cr",
        function()
          require("renamer").rename()
        end,
        desc = "Rename Var",
      },
    },
  },
}
