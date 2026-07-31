#!/usr/bin/env zsh

sudo pacman -S --noconfirm --needed pavucontrol man okular 
sudo pacman -S --noconfirm --needed zip unzip gcc make cmake archlinux-xdg-menu
sudo pacman -S --noconfirm --needed libreoffice rsync fzf base-devel
sudo pacman -S --noconfirm --needed python npm go clang

#Applications menu for dolfin
#
#Its don't needed anymore
#sudo ln -sf /etc/xdg/menus/arch-applications.menu /etc/xdg/menus/applications.menu
#rm -f \~/.cache/ksycoca6_*
#kbuildsycoca6 --noincremental

#Intel video drivers
sudo pacman -S --noconfirm --needed mesa  vulkan-intel 
