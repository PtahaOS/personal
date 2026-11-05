
hl.on("hyprland.start", function () 
    hl.exec_cmd("awww-daemon")
    -- wallpaper2.jpg основные, wallpaper1.jpg запасные. Обе в ~/.config/hypr/wallpapers.
    hl.exec_cmd("sleep 0.4 && awww img \"$HOME/.config/hypr/wallpapers/wallpaper2.jpg\"")
    hl.exec_cmd("$HOME/.config/waybar/launch.sh")
    hl.exec_cmd("swaync")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("helium-browser")
    hl.exec_cmd("$HOME/.config/hypr/scripts/touchpad_toggle.sh -s")
end)

hl.on("hyprland.shutdown", function()
    hl.exec_cmd("killall helium & sleep 0.1")
end)
