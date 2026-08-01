
hl.on("hyprland.start", function () 
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("helium-browser")
    hl.exec_cmd("awww-daemon")
end)

hl.on("hyprland.shutdown", function()
    hl.exec_cmd("killall helium & sleep 0.1")
end)
