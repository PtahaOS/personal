
hl.on("hyprland.start", function () 
    h1.exec_cmd("awww-daemon")
    hl.exec_cmd("waybar")
    hl.exec_cmd("swaync")
    hl.exec_cmd("helium-browser")
end)

hl.on("hyprland.shutdown", function()
end)
