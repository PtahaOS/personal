#!/usr/bin/env bash

sudo pacman -S --noconfirm --needed keyd

#Binds 
mkdir /etc/keyd
sudo cp -r ~/personal/.config/keyd/default.conf /etc/keyd/default.conf
sudo systemctl enable --now keyd
sudo keyd reload

