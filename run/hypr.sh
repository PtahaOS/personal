#!/usr/bin/env bash

# status bar
sudo pacman -S --noconfirm --needed waybar 

# app menu
sudo pacman -S --noconfirm --needed rofi

# notification
sudo pacman -S --noconfirm --needed swaync 

# Wallpapers
sudo pacman -S --noconfirm --needed awww
awww-daemon & disown
awww img $HOME/personal/.config/hypr/wallpapers/wallpaper2.jpg
