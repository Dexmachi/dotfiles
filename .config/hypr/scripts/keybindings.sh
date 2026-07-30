#!/bin/bash
#  _              _     _           _ _
# | | _____ _   _| |__ (_)_ __   __| (_)_ __   __ _ ___
# | |/ / _ \ | | | '_ \| | '_ \ / _` | | '_ \ / _` / __|
# |   <  __/ |_| | |_) | | | | | (_| | | | | | (_| \__ \
# |_|\_\___|\__, |_.__/|_|_| |_|\__,_|_|_| |_|\__, |___/
#           |___/                             |___/
#
# -----------------------------------------------------
# Get keybindings location based on variation
# -----------------------------------------------------
config_file="$HOME/.config/hypr/conf/keybindings/default.lua"

# -----------------------------------------------------
# Path to keybindings config file
# -----------------------------------------------------
echo "Reading from: $config_file"

keybinds=$(awk '
/hl\.bind\(/ {
    match($0, /hl\.bind\(([^,]+),/)
    keys = substr($0, RSTART+8, RLENGTH-9)
    gsub(/mainMod/, "󰘳", keys)
    gsub(/SHIFT/, "󰘶", keys)
    gsub(/CTRL/, "󰘴", keys)
    gsub(/ALT/, "󰘵", keys)
    gsub(/RETURN/, "󰌑", keys)
    gsub(/"/, "", keys)
    gsub(/[ .]/, "", keys)
    gsub(/\+/, " + ", keys)
    current_keys = keys
}
/^-- / {
    if (current_keys != "" && !match($0, /^-- TODO/)) {
        desc = substr($0, 4)
        print current_keys " \r " desc
        current_keys = ""
    }
}
' "$config_file")

sleep 0.2
rofi -dmenu -i -markup -eh 2 -replace -p "Keybinds" -config ~/.config/rofi/config-compact.rasi <<<"$keybinds"
