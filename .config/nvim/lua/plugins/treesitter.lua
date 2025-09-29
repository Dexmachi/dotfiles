return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "css",
        "bash",
        "html",
        "javascript",
        "json",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "tsx",
        "dockerfile",
        "typescript",
        "vim",
        "yaml",
        "toml",
        "rust",
        "java",
        "cpp",
        "rust",
        "go",
      },
      auto_install = true,
      highlight = {
        enable = true,
      },
      indent = {
        enable = true,
      },
    },
  },
  --{ import = "lazyvim.plugins.extras.lang.json" },
}
