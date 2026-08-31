local M = {}

M.palettes = {
  harmony = {
    keyword = "#CAA5F7",
    function_ = "#FF70A2",
    string = "#93E1D4",
    type = "#FAB286",
    var = "#FBA6CD",
    number = "#9DCFF9",
    boolean = "#FF85B9",
    comment = "#9E8195",
    operator = "#F86EA7",
    constant = "#FFBEDD",
    param = "#E5A4C7",
    delimiter = "#9399B3",
    match_paren = "#F79E45",
    match_bg = "#3B2230",
    border = "#9DCFF9",
    title = "#FF8EBD",
    pmenu_sel = "#93E1D4",
    pmenu_sel_fg = "#101010",
    diag_err = "#FF4F88",
    diag_warn = "#F5E36C",
    diag_info = "#9DCFF9",
    diag_hint = "#93E1D4",
  },
  sakura = {
    keyword = "#DDB6F2",
    function_ = "#F4B8E4",
    string = "#A6D189",
    type = "#EA999C",
    var = "#F2CDCD",
    number = "#85C1DC",
    boolean = "#EEBEBE",
    comment = "#8C838E",
    operator = "#E78284",
    constant = "#F5C2E7",
    param = "#E5C890",
    delimiter = "#9399B3",
    match_paren = "#FFA066",
    match_bg = "#362734",
    border = "#85C1DC",
    title = "#F4B8E4",
    pmenu_sel = "#A6D189",
    pmenu_sel_fg = "#101010",
    diag_err = "#E78284",
    diag_warn = "#E5C890",
    diag_info = "#85C1DC",
    diag_hint = "#A6D189",
  },
  cyber = {
    keyword = "#D4A5FF",
    function_ = "#FF5CA0",
    string = "#7EE8D0",
    type = "#FFD180",
    var = "#FFC0E0",
    number = "#80D8FF",
    boolean = "#FF79B0",
    comment = "#827083",
    operator = "#FF80B5",
    constant = "#FFE082",
    param = "#EBB0D2",
    delimiter = "#9399B3",
    match_paren = "#FF9100",
    match_bg = "#421832",
    border = "#7EE8D0",
    title = "#FF5CA0",
    pmenu_sel = "#80D8FF",
    pmenu_sel_fg = "#050505",
    diag_err = "#FF3366",
    diag_warn = "#FFE082",
    diag_info = "#80D8FF",
    diag_hint = "#7EE8D0",
  },
  vaporwave = {
    keyword = "#B4BEFE",
    function_ = "#F38BA8",
    string = "#89DCEB",
    type = "#F9E2AF",
    var = "#F5C2E7",
    number = "#74C7EC",
    boolean = "#F5A97F",
    comment = "#7F849C",
    operator = "#CBA6F7",
    constant = "#FAB387",
    param = "#EBA0AC",
    delimiter = "#9399B3",
    match_paren = "#FAB387",
    match_bg = "#312338",
    border = "#89DCEB",
    title = "#F5C2E7",
    pmenu_sel = "#89DCEB",
    pmenu_sel_fg = "#101010",
    diag_err = "#F38BA8",
    diag_warn = "#F9E2AF",
    diag_info = "#89DCEB",
    diag_hint = "#A6E3A1",
  },
}

function M.get_highlights(name, colors)
  local c = M.palettes[name] or M.palettes.harmony

  return {
    -- 🧱 Base UI & Janelas Flutuantes
    NormalFloat = { fg = c.border, bg = "NONE" },
    FloatBorder = { fg = c.border, bg = "NONE" },
    FloatTitle = { fg = c.title, bg = "NONE", bold = true },
    DexHoverNormal = { fg = c.string, bg = "#292628" },
    Transparent = { bg = "NONE" },
    CursorLineNr = { fg = c.operator, bold = true },

    -- 🎯 Parênteses e Delimitadores
    Delimiter = { fg = c.delimiter },
    MatchParen = { fg = c.match_paren, bg = c.match_bg, bold = true },

    -- 🔲 Janela de autocomplete/documentação (nvim-cmp)
    Pmenu = { fg = c.constant, bg = "NONE" },
    PmenuSel = { fg = c.pmenu_sel_fg, bg = c.pmenu_sel, bold = true },
    PmenuThumb = { bg = c.function_ },
    CmpItemAbbr = { fg = c.constant },
    CmpItemAbbrMatch = { fg = c.function_, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = c.function_, italic = true },
    CmpItemMenu = { fg = c.border, italic = true },

    -- 🧠 Tipos genéricos e por ícone (cmp)
    CmpItemKind = { fg = c.border, bold = true },
    CmpItemKindText = { fg = c.constant },
    CmpItemKindMethod = { fg = c.function_ },
    CmpItemKindFunction = { fg = c.function_ },
    CmpItemKindConstructor = { fg = c.function_ },
    CmpItemKindField = { fg = c.var },
    CmpItemKindVariable = { fg = c.var },
    CmpItemKindClass = { fg = c.type },
    CmpItemKindInterface = { fg = c.type },
    CmpItemKindModule = { fg = c.border },
    CmpItemKindProperty = { fg = c.var },
    CmpItemKindUnit = { fg = c.constant },
    CmpItemKindValue = { fg = c.number },
    CmpItemKindEnum = { fg = c.type },
    CmpItemKindKeyword = { fg = c.keyword },
    CmpItemKindSnippet = { fg = c.string },
    CmpItemKindColor = { fg = c.var },
    CmpItemKindFile = { fg = c.border },
    CmpItemKindReference = { fg = c.border },
    CmpItemKindFolder = { fg = c.border },
    CmpItemKindEnumMember = { fg = c.type },
    CmpItemKindConstant = { fg = c.constant },
    CmpItemKindStruct = { fg = c.type },
    CmpItemKindEvent = { fg = c.boolean },
    CmpItemKindOperator = { fg = c.operator },
    CmpItemKindTypeParameter = { fg = c.type },
    CmpItemKindCopilot = { fg = c.title },
    CmpItemKindAI = { fg = c.keyword, italic = true },

    -- 🔠 Sintaxe Base Unificada
    Comment = { fg = c.comment, italic = true },
    String = { fg = c.string },
    Function = { fg = c.function_, bold = true },
    Keyword = { fg = c.keyword, bold = true, italic = true },
    Type = { fg = c.type },
    Identifier = { fg = c.var },
    Constant = { fg = c.constant },
    Statement = { fg = c.keyword },
    Operator = { fg = c.operator },
    Number = { fg = c.number },
    Boolean = { fg = c.boolean, bold = true },
    Title = { fg = c.border, bold = true },
    Special = { fg = c.border },
    Directory = { fg = c.border },

    -- 🧠 Treesitter Completo & Específico
    ["@function"] = { fg = c.function_, bold = true },
    ["@function.builtin"] = { fg = c.function_ },
    ["@function.macro"] = { fg = c.function_ },
    ["@keyword"] = { fg = c.keyword, italic = true },
    ["@keyword.function"] = { fg = c.keyword, bold = true, italic = true },
    ["@keyword.return"] = { fg = c.keyword, bold = true, italic = true },
    ["@type"] = { fg = c.type },
    ["@type.builtin"] = { fg = c.type },
    ["@constant"] = { fg = c.constant },
    ["@constant.builtin"] = { fg = c.constant },
    ["@variable"] = { fg = c.var },
    ["@variable.builtin"] = { fg = c.title },
    ["@variable.parameter"] = { fg = c.param },
    ["@parameter"] = { fg = c.param },
    ["@field"] = { fg = c.var },
    ["@property"] = { fg = c.var },
    ["@string"] = { fg = c.string },
    ["@string.escape"] = { fg = c.border },
    ["@comment"] = { fg = c.comment, italic = true },
    ["@boolean"] = { fg = c.boolean, bold = true },
    ["@number"] = { fg = c.number },
    ["@operator"] = { fg = c.operator },
    ["@punctuation.bracket"] = { fg = c.delimiter },
    ["@punctuation.delimiter"] = { fg = c.delimiter },
    ["@punctuation.special"] = { fg = c.delimiter },

    -- ⚡ LSP Semantic Tokens
    ["@lsp.type.function"] = { fg = c.function_ },
    ["@lsp.type.method"] = { fg = c.function_ },
    ["@lsp.type.variable"] = { fg = c.var },
    ["@lsp.type.parameter"] = { fg = c.param },
    ["@lsp.type.property"] = { fg = c.var },
    ["@lsp.type.type"] = { fg = c.type },
    ["@lsp.type.class"] = { fg = c.type },
    ["@lsp.type.interface"] = { fg = c.type },
    ["@lsp.type.enum"] = { fg = c.type },
    ["@lsp.type.enumMember"] = { fg = c.type },
    ["@lsp.type.keyword"] = { fg = c.keyword },
    ["@lsp.type.comment"] = { fg = c.comment, italic = true },
    ["@lsp.type.string"] = { fg = c.string },
    ["@lsp.type.number"] = { fg = c.number },
    ["@lsp.typemod.variable.defaultLibrary"] = { fg = c.title },
    ["@lsp.typemod.function.defaultLibrary"] = { fg = c.function_ },

    -- 💡 Diagnostics
    DiagnosticUnderlineError = { sp = c.diag_err, underdouble = true, italic = true },
    DiagnosticUnderlineWarn = { sp = c.diag_warn, undercurl = true, italic = true },
    DiagnosticUnderlineInfo = { sp = c.diag_info, undercurl = true, italic = true },
    DiagnosticUnderlineHint = { sp = c.diag_hint, undercurl = true },

    -- ⛓️ StatusLine
    StatusLine = { fg = "#ffd1ea", bg = "#1a0e17" },
    StatusLineNC = { fg = "#cfa5b6", bg = "#1a0e17" },

    -- ✨ Outros / Custom Tags
    Hack = { fg = "#f79e45", bg = "NONE", bold = true },
    Hint = { fg = "#cce6ff", bg = "NONE", italic = true },
    Warn = { fg = "#f5e36c", bg = "NONE", bold = true },
    Fix = { fg = "#ff4f88", bg = "NONE", bold = true },
  }
end

function M.apply(name)
  local theme_name = name or "harmony"
  vim.g.dex_theme = theme_name

  -- Aplica a base do catppuccin
  vim.cmd("colorscheme catppuccin")

  -- Aplica instantaneamente os highlights da paleta selecionada
  local highlights = M.get_highlights(theme_name)
  for group, hl in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, hl)
  end

  vim.g.colors_name = "dex-" .. theme_name
end

return M
