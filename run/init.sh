#!/usr/bin/env bash

sudo pacman -S --noconfirm --needed pavucontrol man okular \
	zip unzip gcc git make cmake archlinux-xdg-menu \
	libreoffice keyd

#Applications menu for dolfin
sudo ln -sf /etc/xdg/menus/arch-applications.menu /etc/xdg/menus/applications.menu
rm -f \~/.cache/ksycoca6_*
kbuildsycoca6 --noincremental

#Intel video drivers
sudo pacman -S --noconfirm --needed mesa lib32-mesa vulkan-intel lib32-vulkan-intel

#Bind CapsLock -> Ctrl
mkdir /etc/keyd
sudo cp -r ~/personal/.config/keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable --now keyd
sudo keyd reload


hyprctl reload
