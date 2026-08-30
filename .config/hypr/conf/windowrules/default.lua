---@module 'hl'

-- -----------------------------------------------------
-- Window rules
-- -----------------------------------------------------

-- Tile rules
hl.window_rule({
	match = {
		title = "Microsoft-edge",
	},
	float = false,
})

hl.window_rule({
	match = {
		title = "^(Brave-browser)$",
	},
	float = false,
})

hl.window_rule({
	match = {
		title = "^(Chromium)$",
	},
	float = false,
})

-- Picture in Picture
hl.window_rule({
	match = {
		title = "^(Picture-in-Picture)$",
	},
	float = true,
	pin = true,
	move = "69.5% 4%",
})

-- Pavucontrol floating
hl.window_rule({
	match = {
		class = ".*org.pulseaudio.pavucontrol.*",
	},
	float = true,
	size = "700 600",
	center = true,
	pin = true,
})

hl.window_rule({
	match = {
		title = "^(pavucontrol)$",
	},
	float = true,
})

-- Waypaper
hl.window_rule({
	match = {
		class = ".*waypaper.*",
	},
	float = true,
	size = "900 700",
	center = true,
	pin = true,
})

-- ML4W Calendar floating
hl.window_rule({
	match = {
		class = ".*calendario.*",
	},
	float = true,
	size = "60% 70%",
	move = { "(monitor_w-window_w)-16", "65" },
	pin = true,
})

-- ML4W Sidebar floating
hl.window_rule({
	match = {
		class = "com.ml4w.sidebar",
	},
	float = true,
	size = "400 740",
	move = "100%-w-16 66",
	pin = true,
})

-- Blueman Manager
hl.window_rule({
	match = {
		class = "blueman-manager",
	},
	float = true,
	size = "800 600",
	center = true,
})

hl.window_rule({
	match = {
		title = "^(blueman-manager)$",
	},
	float = true,
})

-- Network Manager
hl.window_rule({
	match = {
		title = "^(nm-connection-editor)$",
	},
	float = true,
})

-- Qalculate
hl.window_rule({
	match = {
		title = "^(qalculate-gtk)$",
	},
	float = true,
})

-- nwg-look
hl.window_rule({
	match = {
		class = "nwg-look",
	},
	float = true,
	size = "700 600",
	move = "10% 20%",
	pin = true,
})

-- nwg-displays
hl.window_rule({
	match = {
		class = "nwg-displays",
	},
	float = true,
	size = "900 600",
	move = "10% 20%",
	pin = true,
})

-- System Mission Center
hl.window_rule({
	match = {
		class = "io.missioncenter.MissionCenter",
	},
	float = true,
	size = "900 600",
	center = true,
	pin = true,
})

hl.window_rule({
	match = {
		title = "^(Preferences)$",
	},
	float = true,
	center = true,
	pin = true,
})

-- Gnome Calculator
hl.window_rule({
	match = {
		class = "org.gnome.Calculator",
	},
	float = true,
	size = "700 600",
	center = true,
})

-- General floating
hl.window_rule({
	match = {
		class = "dotfiles-floating",
	},
	float = true,
	size = "1000 700",
	center = true,
})

-- Floating for Ghostty
hl.window_rule({
	match = {
		class = "ml4w.dotfiles.floating",
	},
	float = true,
	size = "1000 700",
	center = true,
	pin = true,
})

-- Dotfiles Sidepad
hl.window_rule({
	match = {
		class = "dotfiles-sidepad",
	},
	float = true,
	size = "85% 70%",
	center = true,
	pin = true,
})

hl.window_rule({
	match = {
		initial_title = "dotfiles-sidepad",
	},
	float = true,
	size = "85% 70%",
	center = true,
	pin = true,
})

-- Applications floating
hl.window_rule({
	match = {
		class = "org.gnome.Nautilus",
	},
	float = true,
})

hl.window_rule({
	match = {
		class = "org.telegram.desktop",
	},
	float = true,
})

hl.window_rule({
	match = {
		class = "org.gnome.TextEditor",
	},
	float = true,
})

hl.window_rule({
	match = {
		class = "org.kde.kdeconnect.app",
	},
	float = true,
})

hl.window_rule({
	match = {
		class = "localsend",
	},
	float = true,
})

hl.window_rule({
	match = {
		class = "vesktop",
	},
	float = true,
})

hl.window_rule({
	match = {
		class = "Spotify",
	},
	float = true,
})

hl.window_rule({
	match = {
		class = "heroic",
	},
	float = true,
})

hl.window_rule({
	match = {
		class = "modrinth-app",
	},
	float = true,
})

hl.window_rule({
	match = {
		class = "com.usebottles.bottles",
	},
	float = true,
})

hl.window_rule({
	match = {
		class = "com.rafaelmardojai.Blanket",
	},
	float = true,
})

-- Layer rules
hl.layer_rule({
	match = {
		namespace = "waybar",
	},
	blur = true,
})

hl.layer_rule({
	match = {
		namespace = "swaync-control-center",
	},
	blur = true,
	ignore_alpha = 0.5,
})

hl.layer_rule({
	match = {
		namespace = "swaync-notification-window",
	},
	blur = true,
	ignore_alpha = 0.5,
})

-- Environment variables
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("QT_QPA_PLATFORMTHEME", "qt6ct")
hl.env("QT_QPA_PLATFORMTHEME", "qt5ct")
hl.env("QT_WAYLAND_DISABLE_WINDOWDECORATION", 1)
hl.env("QT_AUTO_SCREEN_SCALE_FACTOR", 1)
hl.env("GDK_SCALE", 1)
hl.env("GDK_BACKEND", "wayland,x11,*")
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("MOZ_ENABLE_WAYLAND", 1)
hl.env("XCURSOR_SIZE", 24)
hl.env("OZONE_PLATFORM", "wayland")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "wayland")
