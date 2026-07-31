local browser = "helium"

hl.on("hyprland.start", function () 
   hl.exec_cmd("helium-browser")
   hl.exec_cmd("nm-applet")
   --hl.exec_cmd("waybar") --hyprpaper & firefox
   --hl.exec_cmd("~/.local/bin/start-touchpad-toggle")
   hl.exec_cmd("waybar")
end)

hl.on("hyprland.shutdown", function()
    hl.exec_cmd("killall " .. browser .. " && sleep 1")
end)
