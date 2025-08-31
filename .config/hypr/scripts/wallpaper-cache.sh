#!/bin/bash
generated_versions="$HOME/.cache/ml4w/hyprland-dotfiles/current_wallpaper"
rm $generated_versions/*
echo ":: Wallpaper cache cleared"
notify-send "Wallpaper cache cleared"
