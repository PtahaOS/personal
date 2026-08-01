#!/usr/bin/env bash

sudo pacman -S --noconfirm --needed man okular 
sudo pacman -S --noconfirm --needed zip unzip archlinux-xdg-menu
sudo pacman -S --noconfirm --needed libreoffice rsync fzf base-devel

# programing language
sudo pacman -S --noconfirm --needed python npm go clang
sudo pacman -S --noconfirm --needed gcc make cmake 

# bluetooth
sudo pacman -S --noconfirm --needed bluez bluez-utils blueman

# audio
sudo pacman -S --noconfirm --needed pavucontrol pipewire pipewire-pulse wireplumber

#Intel video drivers
sudo pacman -S --noconfirm --needed mesa  vulkan-intel 

# fonts
sudo pacman -S --noconfirm --needed ttf-jetbrains-mono-nerd ttf-font-awesome
