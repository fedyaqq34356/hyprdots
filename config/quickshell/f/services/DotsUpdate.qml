pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool available: false
    property int commits: 0
    property real bytes: 0
    property int files: 0
    property bool busy: false

    readonly property string script: Quickshell.env("HOME") + "/.local/bin/hyprdots-update"

    function refresh() {
        if (root.busy)
            return;
        root.busy = true;
        check.running = true;
    }

    function open() {
        Quickshell.execDetached(["env", "HYPRDOTS_LANG=" + Prefs.language,
                                 "kitty", "--class", "hyprdots-update",
                                 "--title", "hyprdots", root.script]);
    }

    function size() {
        const b = root.bytes;
        if (b >= 1048576)
            return (b / 1048576).toFixed(1) + " MB";
        if (b >= 1024)
            return Math.round(b / 1024) + " KB";
        return Math.round(b) + " B";
    }

    Process {
        id: check
        command: [root.script, "--check"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(text);
                    root.commits = r.commits || 0;
                    root.bytes = r.bytes || 0;
                    root.files = r.files || 0;
                    root.available = !!r.available;
                } catch (e) {
                    root.available = false;
                }
            }
        }
        onExited: root.busy = false
    }

    Timer {
        interval: 20 * 1000
        running: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 30 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    IpcHandler {
        target: "dotsUpdate"
        function refresh(): void { root.refresh(); }
        function open(): void { root.open(); }
        function status(): string {
            return root.available ? root.commits + " " + root.size() : "none";
        }
    }
}
