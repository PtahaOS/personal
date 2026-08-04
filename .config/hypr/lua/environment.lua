-- Arch Variables
hl.env("XDG_MENU_PREFIX", "arch-") 

-- Hyprland Environment Variables
hl.env("HYPRLAND_TRACE", "1")
hl.env("HYPRLAND_NO_RT", "1")
hl.env("HYPRLAND_NO_SD_NOTIFY", "1")
hl.env("HYPRLAND_NO_SD_VARS", "1")
hl.env("HYPRLAND_CONFIG", "/path/to/hyprland.lua")

-- Theme Variables
hl.env("XCURSOR_THEME", "BreezeX-RosePine-Linux")
hl.env("XCURSOR_SIZE", "24") 
-- hl.env("HYPRCURSOR_THEME", "BreezeX-RosePine-Linux")
-- hl.env("HYPRCURSOR_SIZE", "24")

-- Toolkit Backend Variables 
hl.env("GDK_BACKEND", "wayland,x11,*") 
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("SDL_VIDEODRIVER", "wayland")

-- XDG Specifications
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Qt Variables
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", "1")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", "1")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
