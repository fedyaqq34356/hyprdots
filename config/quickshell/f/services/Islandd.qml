pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/islandd"

    property int downloading: 0
    property string vpnIface: ""
    property var conns: []
    property bool connsReady: false
    property bool camera: false
    property bool cameraReady: false

    readonly property bool alive: proc.running

    signal downloadDone(string path)
    signal clip(string line)

    Process {
        id: proc
        running: true
        command: [root.bin, "watch"]
        stdout: SplitParser {
            onRead: line => {
                let ev;
                try { ev = JSON.parse(line); } catch (e) { return; }
                if (ev.t === "dl") {
                    root.downloading = ev.n || 0;
                    if (ev.done !== undefined)
                        root.downloadDone(ev.done);
                } else if (ev.t === "vpn") {
                    root.vpnIface = ev.iface || "";
                } else if (ev.t === "cam") {
                    root.camera = ev.on === true;
                    root.cameraReady = true;
                } else if (ev.t === "clip") {
                    root.clip(ev.line || "");
                } else if (ev.t === "out") {
                    root.conns = ev.conns || [];
                    root.connsReady = true;
                }
            }
        }
        onExited: {
            root.cameraReady = false;
            restart.start();
        }
    }

    Timer {
        id: restart
        interval: 5000
        onTriggered: proc.running = true
    }
}
