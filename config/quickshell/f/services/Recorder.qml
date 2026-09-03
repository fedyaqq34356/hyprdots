pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string statePath:
        (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/recording.state"

    property bool active: false
    property int startedAt: 0
    property string file: ""
    property int elapsed: 0

    property string monitor: ""

    readonly property string clock: {
        const m = Math.floor(elapsed / 60);
        const s = elapsed % 60;
        return (m < 10 ? "0" : "") + m + ":" + (s < 10 ? "0" : "") + s;
    }

    FileView {
        id: state
        path: root.statePath
        watchChanges: true
        preload: true
        printErrors: false

        onFileChanged: reload()
        onLoaded: {
            const parts = text().trim().split("\t");
            root.startedAt = parseInt(parts[0]) || 0;
            root.monitor = parts.length > 1 ? parts[1] : "";
            root.file = parts.length > 2 ? parts.slice(2).join("\t") : "";
            root.active = root.startedAt > 0;
            root.tick();
        }
        onLoadFailed: {
            root.active = false;
            root.startedAt = 0;
            root.file = "";
            root.monitor = "";
        }
    }

    function tick() {
        if (!active) return;
        elapsed = Math.max(0, Math.floor(Date.now() / 1000) - startedAt);
    }

    Timer {
        running: root.active
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    Process { id: toggle }

    function stop() {
        toggle.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/record-toggle.sh"];
        toggle.running = true;
    }
}
