local v = require("cfg.vars")
local S = v.scripts

local once = {
    S .. "/system/monitor-flicker-fix.py",

    "gnome-keyring-daemon --start --components=secrets",
    "hyprpolkitagent",
    S .. "/system/automount.sh",
    "pipewire",
    "pipewire-pulse",
    S .. "/audio/start-wireplumber.sh",
    S .. "/notify/notify-trace.sh",
    S .. "/notify/notif-missed.sh",
    v.home .. "/.local/bin/shell-autostart",
    S .. "/system/fix-dbus.sh",

    "awww-daemon",
    S .. "/wallpaper/startup-wallpaper.sh",
    S .. "/wallpaper/wallpaper-rotate.sh",
    "xdg-user-dirs-update",
    "wl-clip-persist --clipboard regular -f '^([^i]|i[^m]|im[^a]|ima[^g]|imag[^e]|image[^/])'",
    S .. "/clipboard/clipboard-guard.sh",
    "dbus-update-activation-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_RUNTIME_DIR HYPRLAND_INSTANCE_SIGNATURE",

    S .. "/audio/mic-lock.sh",

    S .. "/tools/downloads-sort.py",

    "hyprctl setcursor Matugen-Cursor 24",
    "[ -x ~/.local/bin/pulse-autoconnect ] && exec ~/.local/bin/pulse-autoconnect",
}

if v.backlight or v.battery then
    table.insert(once, 2, "brightnessctl -c backlight set 70%")
end

local sig = os.getenv("HYPRLAND_INSTANCE_SIGNATURE")
local runtime = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
local mark = sig and (runtime .. "/hypr-lua-started-" .. sig)

hl.on("hyprland.start", function()
    if mark then
        local f = io.open(mark)
        if f then
            f:close()
            return
        end
        f = io.open(mark, "w")
        if f then f:close() end
    end
    for _, cmd in ipairs(once) do
        hl.exec_cmd(cmd)
    end
end)
