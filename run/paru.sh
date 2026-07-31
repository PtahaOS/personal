#!/usr/bin/env zsh

# paru
git clone https://aur.archlinux.org/paru.git
cd paru
makepkg -si
cd ..
rm -r paru
