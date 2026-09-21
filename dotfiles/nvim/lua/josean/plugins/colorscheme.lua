-- return {
--   "folke/tokyonight.nvim",
--   priority = 1000,
--   config = function()
--     local transparent = false -- set to true if you would like to enable transparency

--     local bg = "#011628"
--     local bg_dark = "#011423"
--     local bg_highlight = "#143652"
--     local bg_search = "#0A64AC"
--     local bg_visual = "#275378"
--     local fg = "#CBE0F0"
--     local fg_dark = "#B4D0E9"
--     local fg_gutter = "#627E97"
--     local border = "#547998"

--     require("tokyonight").setup({
--       style = "night",
--       transparent = transparent,
--       styles = {
--         sidebars = transparent and "transparent" or "dark",
--         floats = transparent and "transparent" or "dark",
--       },
--       on_colors = function(colors)
--         colors.bg = bg
--         colors.bg_dark = transparent and colors.none or bg_dark
--         colors.bg_float = transparent and colors.none or bg_dark
--         colors.bg_highlight = bg_highlight
--         colors.bg_popup = bg_dark
--         colors.bg_search = bg_search
--         colors.bg_sidebar = transparent and colors.none or bg_dark
--         colors.bg_statusline = transparent and colors.none or bg_dark
--         colors.bg_visual = bg_visual
--         colors.border = border
--         colors.fg = fg
--         colors.fg_dark = fg_dark
--         colors.fg_float = fg
--         colors.fg_gutter = fg_gutter
--         colors.fg_sidebar = fg_dark
--       end,
--     })

--     vim.cmd("colorscheme tokyonight")
--   end,
-- }


return {
  "olimorris/onedarkpro.nvim",
  priority = 1000,
  config = function()
    local transparent = false -- flip to true if you want glass mode

    -- Night Flat palette (custom overrides)
    local bg = "#0b0e14"
    local bg_dark = "#07090d"
    local bg_highlight = "#1a1f28"
    local bg_search = "#2d4f72"
    local bg_visual = "#233345"
    local fg = "#c5d0e6"
    local fg_dark = "#aeb7c8"
    local fg_gutter = "#4c566a"
    local border = "#3a4653"

    require("onedarkpro").setup({
      colors = {
        bg = transparent and "NONE" or bg,
        bg_dark = transparent and "NONE" or bg_dark,
        bg_highlight = bg_highlight,
        bg_search = bg_search,
        bg_visual = bg_visual,
        fg = fg,
        fg_dark = fg_dark,
        fg_gutter = fg_gutter,
        border = border,
      },

      options = {
        transparency = transparent,
      },

      highlights = {
        Normal = { bg = transparent and "NONE" or bg },
        NormalFloat = { bg = transparent and "NONE" or bg_dark },
        FloatBorder = { fg = border, bg = transparent and "NONE" or bg_dark },
        StatusLine = { bg = transparent and "NONE" or bg_dark },
        Visual = { bg = bg_visual },
        Search = { bg = bg_search },
        LineNr = { fg = fg_gutter, bg = transparent and "NONE" or bg },
      },

      styles = {
        types = "NONE",
        methods = "NONE",
        numbers = "NONE",
        strings = "NONE",
        comments = "italic",
        constants = "NONE",
        functions = "NONE",
        keywords = "NONE",
        operators = "NONE",
        variables = "NONE",
        conditionals = "NONE",
        virtual_text = "italic",
      },
    })

    vim.cmd("colorscheme onedark_vivid") -- or onedark_dark / onedark / onelight
  end,
}