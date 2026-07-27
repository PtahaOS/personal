#!/usr/bin/env bash

sudo pacman -S flatpak
flatpak -y install flathub org.wezfurlong.wezterm

mkdir ~/.config/wezterm
