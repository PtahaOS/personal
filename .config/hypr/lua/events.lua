
hl.on("hyprland.start", function () 
    hl.exec_cmd("awww-daemon")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("nm-applet")
    hl.exec_cmd("helium-browser")
end)

hl.on("hyprland.shutdown", function()
    hl.exec_cmd("killall helium & sleep 0.1")
end)
