---@module 'hl'
package.path = package.path .. ";/home/dexmachina/.config/hypr/conf/?.lua;/home/dexmachina/.config/hypr/conf/keybindings/?.lua"

--  _   _                  _                 _
-- | | | |_   _ _ __  _ __| | __ _ _ __   __| |
-- | |_| | | | | '_ \| '__| |/ _` | '_ \ / _` |
-- |  _  | |_| | |_) | |  | | (_| | | | | (_| |
-- |_| |_|\__, | .__/|_|  |_|\__,_|_| |_|\__,_|
--        |___/|_|
--

-- -----------------------------------------------------
-- Monitor
-- -----------------------------------------------------

local monitor = require("monitor")

-- -----------------------------------------------------
-- Cursor
-- -----------------------------------------------------

local cursor = require("cursor")

-- -----------------------------------------------------
-- Environment
-- -----------------------------------------------------

-- source = ~/.config/hypr/conf/environment.conf -> requires manual conversion
local environment = require("environment")

-- -----------------------------------------------------
-- Keyboard
-- -----------------------------------------------------

-- source = ~/.config/hypr/conf/keyboard.conf -> requires manual conversion
local keyboard = require("keyboard")

-- -----------------------------------------------------

-- Load pywal color file

-- -----------------------------------------------------

-- source = ~/.config/hypr/colors.conf -> requires manual conversion
local colors = require("colors")

local color8 = colors.on_primary_fixed

local color11 = colors.background

-- -----------------------------------------------------
-- Autostart
-- -----------------------------------------------------

-- source = ~/.config/hypr/conf/autostart.conf -> requires manual conversion
local autostart = require("autostart")

-- -----------------------------------------------------
-- Load configuration files
-- -----------------------------------------------------

-- source = ~/.config/hypr/conf/window.conf -> requires manual conversion
local window = require("window")

-- source = ~/.config/hypr/conf/decoration.conf -> requires manual conversion
local decoration = require("decoration")

-- source = ~/.config/hypr/conf/layout.conf -> requires manual conversion
local layout = require("layout")

-- source = ~/.config/hypr/conf/workspace.conf -> requires manual conversion
local workspace = require("workspace")

-- source = ~/.config/hypr/conf/misc.conf -> requires manual conversion
local misc = require("misc")

-- source = ~/.config/hypr/conf/keybinding.conf -> requires manual conversion
local keybinding = require("keybinding")

-- source = ~/.config/hypr/conf/windowrule.conf -> requires manual conversion
local windowrule = require("windowrule")

-- -----------------------------------------------------
-- Animation
-- -----------------------------------------------------

-- source = ~/.config/hypr/conf/animation.conf -> requires manual conversion
local animation = require("animation")

-- -----------------------------------------------------
-- Environment for xdg-desktop-portal-hyprland
-- -----------------------------------------------------

-- -----------------------------------------------------
-- Custom
-- -----------------------------------------------------

-- source = ~/.config/hypr/conf/custom.conf -> requires manual conversion
local custom = require("custom")

hl.env("WLR_NO_HARDWARE_CURSORS", 1)

-- Autostart
hl.on("hyprland.start", function()
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
end)
