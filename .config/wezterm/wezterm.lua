local wezterm = require("wezterm")
local style = require("lua.style")
local config = wezterm.config_builder()

config = style
return config
