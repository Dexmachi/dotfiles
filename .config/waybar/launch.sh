#!/bin/bash
# -----------------------------------------------------
# Quickshell macOS Bar Launcher (replaces Waybar)
# Original backup saved at ~/.config/waybar/launch.sh.bak
# -----------------------------------------------------

killall waybar 2>/dev/null
pkill waybar 2>/dev/null

if [ ! -f "$HOME/.config/ml4w/settings/waybar-disabled" ]; then
    if ! pgrep -x "quickshell" >/dev/null; then
        nohup quickshell >/dev/null 2>&1 &
    fi
else
    pkill -x quickshell 2>/dev/null
    echo ":: Quickshell bar disabled"
fi
