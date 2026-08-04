#!/usr/bin/env bash

# status bar
sudo pacman -S --noconfirm --needed waybar 
paru -S --noconfirm --needed networkmanager-dmenu

# app menu
sudo pacman -S --noconfirm --needed rofi

# rofi disable xgps and xgpspeed
mkdir -p ~/.local/share/applications

cat > ~/.local/share/applications/xgps.desktop << 'EOF'
[Desktop Entry]
Name=xgps
NoDisplay=true
EOF

cat > ~/.local/share/applications/xgpsspeed.desktop << 'EOF'
[Desktop Entry]
Name=xgpsspeed
NoDisplay=true
EOF

update-desktop-database ~/.local/share/applications

# notification
sudo pacman -S --noconfirm --needed swaync 

# Wallpapers
sudo pacman -S --noconfirm --needed awww
QUERY=$(awww query -a)
if [ $QUERY='' ]; then
    hyprctl eval 'hl.exec_cmd("awww-daemon")'
fi
awww img $HOME/personal/.config/hypr/wallpapers/wallpaper2.jpg
echo "awww end"

# gtk
paru -S --noconfirm --needed rose-pine-gtk-theme-full rose-pine-cursor

