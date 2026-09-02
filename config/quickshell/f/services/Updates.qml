pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var repo: []
    property var aur: []
    property bool busy: false
    property bool ready: false

    readonly property int count: root.repo.length + root.aur.length
    readonly property var all: root.repo.concat(root.aur)

    signal appeared(int count)

    function refresh() {
        if (root.busy)
            return;
        root.busy = true;
        repoCheck.running = true;
    }

    function parse(text) {
        const list = [];
        for (const line of text.trim().split("\n")) {
            const t = line.trim();
            if (t === "")
                continue;
            const parts = t.split(/\s+/);
            list.push({
                name: parts[0],
                from: parts[1] || "",
                to: parts[3] || ""
            });
        }
        return list;
    }

    Process {
        id: repoCheck
        command: ["checkupdates"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.repo = root.parse(text);
                aurCheck.running = true;
            }
        }
        onExited: (code) => {
            if (code === 2)
                root.repo = [];
        }
    }

    Process {
        id: aurCheck
        command: ["sh", "-c",
                  "command -v paru >/dev/null && paru -Qua 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                const before = root.ready ? root.count : -1;
                root.aur = root.parse(text);
                root.busy = false;

                if (!root.ready) {
                    root.ready = true;
                    return;
                }
                if (root.count > before && root.count > 0)
                    root.appeared(root.count);
            }
        }
    }

    Component.onCompleted: root.refresh()

    Timer {
        interval: 45 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
