local wezterm = require("wezterm")
local style = {}

-- Font
style.font = wezterm.font("JetBrains Mono Nerd Font")
style.font_size = 20

-- Colors
style.colors = {
    cursor_bg = "white",
    cursor_border = "white",
}

-- Background
style.window_background_opacity = 0.85
style.window_background_image = ""

-- Appearance
style.hide_tab_bar_if_only_one_tab = true

return style
