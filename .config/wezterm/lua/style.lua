local wezterm = require("wezterm")
local rose_pine = require("lua.rose-pine").moon
local style = {}

-- Font
style.font = wezterm.font_with_fallback {
    "JetBrains Mono Nerd Font",
   "Iosevka Nerd Font",
    "Font Awesome 7",
}
style.font_size = 20


-- Background
style.window_background_opacity = 0.85
style.window_background_image = ""

-- Appearance
style.hide_tab_bar_if_only_one_tab = true

-- Theme
style.colors = rose_pine.colors()
style.window_frame = rose_pine.window_frame()

return style
