pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/islandd"

    property bool found: false
    property bool online: false
    property string name: ""
    property string error: ""
    property bool charging: false
    property string source: ""
    property int liveBattery: -1

    readonly property bool coarse: root.source === "status"
    readonly property string shortName: (root.name || "").replace(/ Lightspeed| Wireless| Gaming| Mouse/g, "").trim() || "Mouse"

    readonly property int battery: root.liveBattery >= 0 ? root.liveBattery : store.batLast
    readonly property bool batteryStale: root.liveBattery < 0 && store.batLast >= 0
    readonly property double batteryAt: store.batLastAt
    readonly property var batHist: store.batHist || []
    readonly property bool known: root.battery >= 0

    function noteBattery(v) {
        if (v < 0)
            return;
        const now = Math.round(Date.now() / 1000);
        let h = (store.batHist || []).slice();
        const last = h.length ? h[h.length - 1] : null;
        if (root.charging || (last && v > last[1] + 8)) {
            h = [[now, v]];
            store.batWarned = 101;
        } else if (!last || last[1] !== v) {
            h.push([now, v]);
            while (h.length > 400)
                h.shift();
        }
        store.batHist = h;
        store.batLast = v;
        store.batLastAt = now;
        file.writeAdapter();
        root.warnLow(v);
    }

    function warnLow(v) {
        if (root.charging)
            return;
        for (const lvl of [5, 20]) {
            if (v <= lvl && store.batWarned > lvl) {
                store.batWarned = lvl;
                file.writeAdapter();
                notifier.command = ["notify-send", "-a", root.name || "Mouse", "-i", "input-mouse",
                                    "-u", lvl <= 5 ? "critical" : "normal",
                                    I18n.t("mouse.lowTitle").replace("%1", v),
                                    I18n.t("mouse.lowBody")];
                notifier.running = true;
                return;
            }
        }
    }

    Process { id: notifier }

    onLiveBatteryChanged: root.noteBattery(root.liveBattery)

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/mouse-battery.json"
        printErrors: false
        blockLoading: true
        property bool done: false
        onLoaded: file.done = true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                file.writeAdapter();
            file.done = true;
        }

        JsonAdapter {
            id: store
            property int batLast: -1
            property real batLastAt: 0
            property var batHist: []
            property int batWarned: 101
        }
    }

    Process {
        id: watcher
        running: file.done
        command: [root.bin, "mouse", "watch"]
        stdout: SplitParser {
            onRead: line => {
                let ev;
                try { ev = JSON.parse(line); } catch (e) { return; }
                root.found = !!ev.found;
                root.online = !!ev.online;
                root.error = ev.ok ? "" : (ev.error || "io");
                if (ev.name)
                    root.name = ev.name;
                if (ev.source)
                    root.source = ev.source;
                root.charging = !!ev.charging;
                root.liveBattery = ev.online && ev.percent !== undefined && ev.percent !== null ? ev.percent : -1;
            }
        }
        onExited: restartWatch.start()
    }

    Timer {
        id: restartWatch
        interval: 10000
        onTriggered: watcher.running = true
    }
}
