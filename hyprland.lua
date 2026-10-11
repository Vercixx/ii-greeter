local function read(path)
    local f = io.open(path)
    if not f then return "" end
    local text = f:read("a")
    f:close()
    return text
end

local eonos = ("\n" .. read("/etc/os-release")):match("\nID=eonos\n")

local xkb = eonos and read("/etc/X11/xorg.conf.d/00-keyboard.conf") or ""

-- VMware/VirtualBox fix for eonOS
if eonos and ("\n" .. read("/proc/modules")):find("\nvmwgfx ") then
    hl.env("LIBGL_ALWAYS_SOFTWARE", "1")
end

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
        kb_layout = xkb:match('"XkbLayout"%s+"([^"]+)"') or "us",
        kb_options = xkb:match('"XkbOptions"%s+"([^"]+)"') or "",
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
