return {
  "pwntester/octo.nvim",
  cmd = "Octo",
  opts = {
    picker = "telescope",
    enable_builtin = true,
  },
  keys = {
    {
      "<leader>goi",
      "<CMD>Octo issue list<CR>",
      desc = "List GitHub Issues",
    },
    {
      "<leader>gop",
      "<CMD>Octo pr list<CR>",
      desc = "List GitHub PullRequests",
    },
    {
      "<leader>god",
      "<CMD>Octo discussion list<CR>",
      desc = "List GitHub Discussions",
    },
    {
      "<leader>gon",
      "<CMD>Octo notification list<CR>",
      desc = "List GitHub Notifications",
    },
    {
      "<leader>gos",
      function()
        require("octo.utils").create_base_search_command({ include_current_repo = true })
      end,
      desc = "Search GitHub",
    },
  },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "nvim-telescope/telescope.nvim",
    "nvim-tree/nvim-web-devicons",
  },
}
