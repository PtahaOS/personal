local wezterm = require 'wezterm'
local config = wezterm.config_builder()

config.keys = {
  -- CTRL-SHIFT-l activates the debug overlay
  { key = 'L', mods = 'CTRL', action = wezterm.action.ShowDebugOverlay },
  { key = "f", mods = 'CTRL', action = wezterm.action_callback(function(win, pane)
    print("from the action callback")
  end)
  },
}
wezterm.log_error("FRESH CONFIG LOAD!!")
-- config.wrong = true


config.font = wezterm.font "JetBrains Mono"
config.font_size = 20

return config
