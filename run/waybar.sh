#!/usr/bin/env zsh

#Waybar things
pacman -S --asdeps --noconfirm --needed \
  gtkmm3 jsoncpp libsigc++ fmt wayland chrono-date spdlog gtk3 \
  gobject-introspection libgirepository libpulse libnl libappindicator-gtk3 \
  libdbusmenu-gtk3 libmpdclient sndio libevdev libxkbcommon upower meson \
  cmake scdoc wayland-protocols glib2-devel ttf-nerd-fonts-symbols
