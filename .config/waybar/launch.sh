#!/bin/bash
# One bar. Hyprland login and Super+Shift+W both call this script.
pkill -x waybar 2>/dev/null || true
for _ in 1 2 3 4 5 6 7 8 9 10; do
    pgrep -x waybar >/dev/null || break
    sleep 0.1
done
# pam_systemd leaves cap_wake_alarm ambient. bubblewrap exits when it sees
# that capability, so glycin cannot decode the tray icons (nm-signal-75).
exec setpriv --ambient-caps -all --inh-caps -all -- waybar
