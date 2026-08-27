pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// Новые исходящие соединения. Опрашивается ss, из него берутся только
// пары «процесс → адрес», которых раньше не было. Ничего не пишется на диск:
// список живёт в памяти и стареет сам.
Singleton {
    id: root

    property var seen: ({})
    property var recent: []
    property bool ready: false

    readonly property int keep: 8
    readonly property int ttl: 20000

    readonly property bool active: root.recent.length > 0
    readonly property int count: root.recent.length

    readonly property string label: {
        if (root.recent.length === 0) return "";
        const last = root.recent[root.recent.length - 1];
        return last.proc + " → " + last.host;
    }

    readonly property string tooltip: {
        if (root.recent.length === 0) return "";
        let out = "новые исходящие соединения\n";
        for (let i = root.recent.length - 1; i >= 0; i--) {
            const e = root.recent[i];
            out += "\n" + e.proc + "  →  " + e.host + ":" + e.port;
        }
        return out;
    }

    Process {
        id: probe
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/outbound-scan.sh"]

        stdout: StdioCollector {
            onStreamFinished: {
                const now = Date.now();
                const lines = this.text.split("\n");
                const fresh = [];

                for (const line of lines) {
                    if (line.trim() === "") continue;
                    const parts = line.split("\t");
                    if (parts.length < 3) continue;

                    const key = parts[0] + "|" + parts[1];
                    if (root.seen[key] !== undefined) continue;
                    root.seen[key] = now;

                    // первый проход после старта — это весь уже открытый
                    // трафик, показывать его как «новое» смысла нет
                    if (!root.ready) continue;

                    fresh.push({ proc: parts[0], host: parts[1],
                                 port: parts[2], at: now });
                }

                root.ready = true;

                if (fresh.length > 0) {
                    let list = root.recent.concat(fresh);
                    if (list.length > root.keep)
                        list = list.slice(list.length - root.keep);
                    root.recent = list;
                }
            }
        }
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: probe.running = true
    }

    // запись держится в баре недолго и уходит сама
    Timer {
        interval: 1000
        running: root.recent.length > 0
        repeat: true
        onTriggered: {
            const now = Date.now();
            const list = root.recent.filter(e => now - e.at < root.ttl);
            if (list.length !== root.recent.length)
                root.recent = list;
        }
    }
}
