pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

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
        let out = I18n.t("net.outbound");
        for (let i = root.recent.length - 1; i >= 0; i--) {
            const e = root.recent[i];
            out += "\n" + e.proc + "  →  " + e.host + ":" + e.port;
        }
        return out;
    }

    function ingest(conns) {
        const now = Date.now();
        const fresh = [];

        for (const c of conns) {
            if (c.length < 3) continue;
            const key = c[0] + "|" + c[1];
            if (root.seen[key] !== undefined) continue;
            root.seen[key] = now;

            if (!root.ready) continue;

            fresh.push({ proc: c[0], host: c[1], port: c[2], at: now });
        }

        root.ready = true;

        if (fresh.length > 0) {
            let list = root.recent.concat(fresh);
            if (list.length > root.keep)
                list = list.slice(list.length - root.keep);
            root.recent = list;
        }
    }

    Connections {
        target: Islandd
        function onConnsChanged() { root.ingest(Islandd.conns); }
    }

    Component.onCompleted: if (Islandd.connsReady) root.ingest(Islandd.conns)

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
