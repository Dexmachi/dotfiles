return {
  {
    "michaelrommel/nvim-silicon",
    lazy = true,
    cmd = "Silicon",
    keys = {
      {
        "<leader>p",
        ":Silicon<CR>",
        mode = "v",
        desc = "Screenshot",
      },
    },
    config = function()
      require("silicon").setup({
        font = "Maple Mono NF CN=34;Noto Color Emoji=34",
        theme = vim.fn.stdpath("config") .. "/colors/dex-abyssal.tmTheme",
        background = "#14B8A6",
        language = function()
          if vim.bo.buftype == "terminal" or vim.bo.filetype == "snacks_terminal" then
            return "bash"
          end
          return vim.bo.filetype ~= "" and vim.bo.filetype
            or vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":e")
        end,
        window_title = function()
          return vim.fn.fnamemodify(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()), ":t")
        end,
      })
    end,
  },
}
