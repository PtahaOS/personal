#!/usr/bin/env bash

sudo pacman -S --noconfirm --needed waybar 
sudo pacman -S --noconfirm --needed rofi
sudo pacman -S --noconfirm --needed swaync 

# Wallpapers
sudo pacman -S --noconfirm --needed awww
awww-daemon & disown
awww img $HOME/personal/.config/hypr/wallpapers/wallpaper2.jpg
