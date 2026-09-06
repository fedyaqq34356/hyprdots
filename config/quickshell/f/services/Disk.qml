pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int users: 0

    property var mounts: []

    readonly property var skipTypes: [
        "tmpfs", "devtmpfs", "squashfs", "overlay", "ramfs", "efivarfs",
        "proc", "sysfs", "cgroup2", "fuse.portal", "fuseblk.snap"
    ]

    function acquire() { root.users++; }
    function release() { root.users = Math.max(0, root.users - 1); }

    function human(kb) {
        const units = ["K", "M", "G", "T"];
        let v = kb;
        let i = 0;
        while (v >= 1024 && i < units.length - 1) {
            v /= 1024;
            i++;
        }
        return (v >= 100 ? Math.round(v) : v.toFixed(1)) + units[i];
    }

    function label(path) {
        if (path === "/") return "root";
        const parts = path.split("/");
        return parts[parts.length - 1] || path;
    }

    Process {
        id: probe
        command: ["df", "-k", "--output=source,fstype,size,used,avail,target"]

        stdout: StdioCollector {
            onStreamFinished: {
                const rows = [];
                const lines = this.text.split("\n");

                for (let i = 1; i < lines.length; i++) {
                    const f = lines[i].trim().split(/\s+/);
                    if (f.length < 6)
                        continue;

                    const type = f[1];
                    if (root.skipTypes.indexOf(type) !== -1)
                        continue;
                    if (f[0].indexOf("/dev/") !== 0)
                        continue;

                    const total = parseInt(f[2], 10);
                    const used = parseInt(f[3], 10);
                    const free = parseInt(f[4], 10);
                    const target = f.slice(5).join(" ");
                    if (!isFinite(total) || total <= 0)
                        continue;
                    if (rows.some(r => r.path === target))
                        continue;

                    rows.push({
                        path: target,
                        label: root.label(target),
                        used: used,
                        total: total,
                        free: free,
                        percent: Math.max(0, Math.min(100, used / total * 100))
                    });
                }

                rows.sort((a, b) => a.path.length - b.path.length);
                root.mounts = rows.slice(0, 4);
            }
        }
    }

    function refresh() {
        if (root.users > 0)
            probe.running = true;
    }

    onUsersChanged: if (root.users > 0 && root.mounts.length === 0) root.refresh()

    Timer {
        running: root.users > 0
        interval: 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
