-- LOCALS
local ls = require("luasnip")
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
local extras = require("luasnip.extras")
local fmt = require("luasnip.extras.fmt").fmt
local c = ls.choice_node
local f = ls.function_node
local sn = ls.snippet_node
local d = ls.dynamic_node
local rep = extras.rep
-- LOCALS

-- ############################################################################
-- ############################################################################
--                                   C++
-- ############################################################################
-- ############################################################################

ls.add_snippets("cpp", {
  s("init", {
    t({ "", "#include <bits/stdc++.h>" }),
    t({ "", "#include <ios>" }),
    t({ "", "#include<stdio.h>" }),
    t({ "", "#include<stdlib.h>", "" }),
    t({ "", "using namespace std;", "" }),
    t({ "", "int main() {", "" }),
    t({ "  ios::sync_with_stdio(false);", "  cin.tie(NULL);", "" }),
    t({ "  ", "" }),
    t("}"),
  }),
  s("for", {
    t({ "int n;", "" }),
    t("for (int "),
    i(1, "i"),
    t(" = 0; "),
    rep(1),
    t(" < "),
    i(2, "n"),
    t("; "),
    rep(1),
    t("++) {"),
    t({ "", "  " }),
    i(0),
    t({ "", "}" }),
  }),
  s("vec", {
    t("vector<"),
    i(1, "int"),
    t("> "),
    i(2, "v"),
    t(";"),
  }),
})
