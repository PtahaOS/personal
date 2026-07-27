#!/usr/bin/env bash

sudo pacman -S --noconfirm --needed pavucontrol man okular \
	zip unzip gcc git make cmake archlinux-xdg-menu \
	libreoffice rsync

#Applications menu for dolfin
sudo ln -sf /etc/xdg/menus/arch-applications.menu /etc/xdg/menus/applications.menu
rm -f \~/.cache/ksycoca6_*
kbuildsycoca6 --noincremental

#Intel video drivers
sudo pacman -S --noconfirm --needed mesa lib32-mesa vulkan-intel lib32-vulkan-intel

#Notebook only
sudo mkdir -p /etc/system/login.conf.d
sudo tee /etc/system/login.conf.d/lid.conf << EOF
[Login]
HandLeLidSwitch=suspend
HandLeLidSwitchExternalPower=ignore
HandLeLidSwitchDocker=ignore
EOF
echo "For apply changes need reload"

hyprctl reload
