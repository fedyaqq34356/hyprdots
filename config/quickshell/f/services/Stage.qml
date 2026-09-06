pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property var freeByMonitor: ({})

    property int freeCount: 0

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
        "activespecial", "activespecialv2", "moveworkspace", "moveworkspacev2"
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

        const monitors = Hyprland.monitors.values;
        for (let i = 0; i < monitors.length; i++) {
            const mon = monitors[i];
            if (!mon || !mon.name)
                continue;

            const isFree = root.monitorFree(mon);
            out[mon.name] = isFree;
            if (isFree)
                free++;
        }

        root.freeByMonitor = out;
        root.freeCount = free;
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
