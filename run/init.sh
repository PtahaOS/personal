#!/usr/bin/env zsh

sudo pacman -S --noconfirm --needed pavucontrol man okular \
	zip unzip gcc git make cmake archlinux-xdg-menu \
	libreoffice rsync fzf

#Applications menu for dolfin
#
#Its don't needed anymore
#sudo ln -sf /etc/xdg/menus/arch-applications.menu /etc/xdg/menus/applications.menu
#rm -f \~/.cache/ksycoca6_*
#kbuildsycoca6 --noincremental

#Intel video drivers
sudo pacman -S --noconfirm --needed mesa lib32-mesa vulkan-intel lib32-vulkan-intel

#Notebook only
#
#Its not working
#sudo mkdir -p /etc/system/login.conf.d
#sudo tee /etc/system/login.conf.d/lid.conf << EOF
#[Login]
#HandLeLidSwitch=ignore
#HandLeLidSwitchExternalPower=ignore
#HandLeLidSwitchDocker=ignore
#EOF
#echo "For apply changes need reload"
