pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property var freeByMonitor: ({})

    property int freeCount: 0

    property bool gaming: false

    readonly property var gameClass: /^(steam_app_\d+|arma3(_x64)?(\.exe)?|gamescope|hoi4|cities2(\.exe)?|.+\.exe)$/i

    function isGame(raw) {
        if (!raw || !raw.fullscreen)
            return false;
        if (raw.contentType === "game")
            return true;
        return root.gameClass.test(raw.class || "") || root.gameClass.test(raw.initialClass || "");
    }

    function free(monitorName) {
        if (!monitorName)
            return true;
        const v = root.freeByMonitor[monitorName];
        return v === undefined ? true : v;
    }

    readonly property var triggers: [
        "openwindow", "closewindow", "movewindow", "movewindowv2",
        "changefloatingmode", "fullscreen", "workspace", "workspacev2",
        "focusedmon", "focusedmonv2", "monitoradded", "monitorremoved",
        "activespecial", "activespecialv2", "moveworkspace", "moveworkspacev2",
        "activewindow", "activewindowv2", "windowtitle", "windowtitlev2"
    ]

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (root.triggers.indexOf(event.name) !== -1)
                settle.restart();
        }
    }

    Timer {
        id: settle
        interval: 120
        onTriggered: root.recompute()
    }

    Connections {
        target: Hyprland.monitors
        function onValuesChanged() { settle.restart(); }
    }

    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() { settle.restart(); }
        function onFocusedMonitorChanged() { settle.restart(); }
    }

    Component.onCompleted: settle.restart()

    function recompute() {
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();

        const out = {};
        let free = 0;
        let game = false;

        const monitors = Hyprland.monitors.values;
        for (let i = 0; i < monitors.length; i++) {
            const mon = monitors[i];
            if (!mon || !mon.name)
                continue;

            if (root.monitorGaming(mon))
                game = true;
            const isFree = root.monitorFree(mon);
            out[mon.name] = isFree;
            if (isFree)
                free++;
        }

        root.freeByMonitor = out;
        root.freeCount = free;
        root.gaming = game;
    }

    function monitorGaming(mon) {
        const ws = mon.activeWorkspace;
        if (!ws || !ws.hasFullscreen)
            return false;
        const wins = ws.toplevels ? ws.toplevels.values : [];
        for (let i = 0; i < wins.length; i++) {
            if (root.isGame(wins[i] ? wins[i].lastIpcObject : null))
                return true;
        }
        return false;
    }

    function monitorFree(mon) {
        const ws = mon.activeWorkspace;
        if (!ws)
            return true;
        if (ws.hasFullscreen)
            return false;

        const wins = ws.toplevels ? ws.toplevels.values : [];
        for (let i = 0; i < wins.length; i++) {
            const raw = wins[i] ? wins[i].lastIpcObject : null;
            if (!raw)
                continue;
            if (raw.hidden === true)
                continue;
            if (raw.mapped === false)
                continue;
            if (raw.floating !== true)
                return false;
        }

        return true;
    }
}
