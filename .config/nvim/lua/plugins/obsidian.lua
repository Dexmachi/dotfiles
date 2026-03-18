return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
    event = "VeryLazy",
    ---@module 'render-markdown'
    ---@type render.md.UserConfig
    opts = {
      bullet = {
        icons = {
          "✸",
          "✿",
          "◉",
          "○",
        },
        right_pad = 1,
      },
      heading = {
        sign = false,
        icons = { "󰲡 ", "󰲣 ", "󰲥 ", "󰲧 ", "󰲩 ", "󰲫 " },
      },
    },
  },

  {
    "Toprun123/PicVim",
    config = function()
      require("picvim").setup()
    end,
  },
}
