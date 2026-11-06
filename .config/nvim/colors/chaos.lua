if vim.o.background == "light" then
  require("config.themes_data").apply("chaos")
else
  require("config.themes_data").apply("chaos_dark")
end
