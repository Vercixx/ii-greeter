hl.monitor({
    output = "",
    mode = "preferred",
    position = "auto",
    scale = "auto"
})

hl.config({
    general = {
        border_size = 0,
        gaps_in = 0,
        gaps_out = 0
    },
    decoration = {
        rounding = 0,
        blur = { enabled = false },
        shadow = { enabled = false }
    },
    animations = { enabled = false },
    input = {
        kb_layout = "us",
        numlock_by_default = true
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        disable_watchdog_warning = true,
        force_default_wallpaper = 0
    },
    ecosystem = {
        no_update_news = true,
        no_donation_nag = true
    }
})

hl.on("hyprland.start", function ()
    hl.exec_cmd("qs -p \"$II_GREETER_DIR/shell.qml\" && touch \"$II_GREETER_MARKER\"; hyprctl dispatch 'hl.dsp.exit()'")
end)
