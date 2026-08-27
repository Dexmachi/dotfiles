#!/usr/bin/env bash
hyprctl eval "hl.monitor({ output = 'eDP-1', mode = 'preferred', position = 'auto', scale = 1, transform = 1 }); hl.config({ input = { touchdevice = { transform = 1 } } })"
