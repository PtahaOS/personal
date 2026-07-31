#!/usr/bin/env zsh

sudo pacman -S --noconfirm --needed waybar pipewire
sudo pacman -S --noconfirm --needed rofi
sudo pacman -S --noconfirm --needed hyprpaper

# rofi
#git clone https://github.com/rose-pine/rofi $HOME/personal/.temp/rofi
#cp $HOME/personal/.temp/rofi/rose-pine-moon.rasi $HOME/personal/.config/rofi/config.rasi 
#rm -rf $HOME/personal/.temp/rofi
#
## waybar
#git clone https://github.com/rose-pine/waybar $HOME/personal/.temp/waybar
#cp $HOME/personal/.temp/waybar/rose-pine-moon.css $HOME/personal/.config/waybar/style.css 
#rm -rf $HOME/personal/.temp/waybar
