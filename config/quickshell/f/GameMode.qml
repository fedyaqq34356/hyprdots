pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Singleton {
    id: root

    property bool manual: false

    readonly property bool fullscreenApp: {
        const list = ToplevelManager.toplevels
            ? ToplevelManager.toplevels.values : [];
        for (const t of list) {
            if (t && t.fullscreen) return true;
        }
        return false;
    }

    readonly property bool active: manual || fullscreenApp

    function toggle() { root.manual = !root.manual; }

    readonly property string enterCmd: [
        "keyword decoration:blur:enabled false",
        "keyword animations:enabled 0",
        "keyword decoration:shadow:enabled false",
        "keyword decoration:dim_inactive false",
        "keyword decoration:active_opacity 1.0",
        "keyword decoration:inactive_opacity 1.0"
    ].join(" ; ")

    Process { id: proc }

    function run(args) {
        proc.command = args;
        proc.running = true;
    }

    onActiveChanged: {
        if (active) run(["hyprctl", "--batch", root.enterCmd]);
        else        run(["hyprctl", "reload"]);
    }
}
