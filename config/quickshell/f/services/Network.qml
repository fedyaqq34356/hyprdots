pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    property bool radio: true
    property bool connected: false
    property string ssid: ""
    property int strength: 0
    property var networks: []
    property bool busy: false
    property string error: ""

    property string linkRate: ""

    property bool primedLink: false
    property bool primedRadio: false

    onConnectedChanged: {
        if (!root.primedLink)
            return;
        if (root.connected) Sfx.netConnect();
        else Sfx.netDisconnect();
    }

    onRadioChanged: {
        if (!root.primedRadio)
            return;
        if (root.radio) Sfx.radioOn();
        else Sfx.radioOff();
    }

    property string iface: ""
    property bool sampling: false
    property real rxRate: 0
    property real txRate: 0

    function human(bytes) {
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(1) + I18n.t("unit.mbps");
        if (bytes >= 1024)    return Math.round(bytes / 1024) + I18n.t("unit.kbps");
        return Math.round(bytes) + I18n.t("unit.bps");
    }

    readonly property string glyph: {
        if (!radio) return "󰤮";
        if (!connected) return "󰤯";
        if (strength >= 75) return "󰤨";
        if (strength >= 50) return "󰤥";
        if (strength >= 25) return "󰤢";
        return "󰤟";
    }

    function fields(line) {
        const out = [];
        let cur = "";
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) { cur += line[++i]; continue; }
            if (line[i] === ":") { out.push(cur); cur = ""; continue; }
            cur += line[i];
        }
        out.push(cur);
        return out;
    }

    Process {
        id: scan
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY,RATE", "device", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                const seen = {};
                const list = [];
                let active = null;

                for (const line of text.trim().split("\n")) {
                    if (line === "") continue;
                    const f = root.fields(line);
                    if (f.length < 4) continue;
                    const entry = {
                        active: f[0] === "yes",
                        ssid: f[1],
                        strength: parseInt(f[2]) || 0,
                        secured: f[3].trim() !== ""
                    };
                    if (entry.ssid === "") continue;
                    if (entry.active) {
                        active = entry;
                        root.linkRate = f.length > 4 ? f[4].trim() : "";
                    }
                    if (seen[entry.ssid] !== undefined) {
                        const prev = list[seen[entry.ssid]];
                        const wasActive = prev.active || entry.active;
                        if (entry.strength > prev.strength) list[seen[entry.ssid]] = entry;
                        list[seen[entry.ssid]].active = wasActive;
                        continue;
                    }
                    seen[entry.ssid] = list.length;
                    list.push(entry);
                }

                list.sort((a, b) => (b.active ? 1 : 0) - (a.active ? 1 : 0)
                                    || b.strength - a.strength);
                root.networks = list;
                root.connected = active !== null;
                root.ssid = active ? active.ssid : "";
                root.strength = active ? active.strength : 0;
                if (!root.connected) root.linkRate = "";
                root.primedLink = true;
            }
        }
    }

    Process {
        id: radioState
        command: ["nmcli", "-t", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.radio = text.trim() === "enabled";
                root.primedRadio = true;
            }
        }
    }

    function refresh() {
        radioState.running = true;
        scan.running = true;
        ifaceProc.running = true;
    }

    Process {
        id: ifaceProc
        command: ["nmcli", "-t", "-f", "DEVICE,TYPE,STATE", "device", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                for (const line of text.trim().split("\n")) {
                    const f = root.fields(line);
                    if (f.length >= 3 && f[1] === "wifi" && f[2] === "connected") {
                        root.iface = f[0];
                        return;
                    }
                }
                root.iface = "";
            }
        }
    }

    property real lastRx: -1
    property real lastTx: -1

    Process {
        id: traffic
        stdout: StdioCollector {
            onStreamFinished: {
                const n = text.trim().split("\n").map(v => parseFloat(v));
                if (n.length < 2 || isNaN(n[0])) return;
                if (root.lastRx >= 0) {
                    root.rxRate = Math.max(0, n[0] - root.lastRx);
                    root.txRate = Math.max(0, n[1] - root.lastTx);
                }
                root.lastRx = n[0];
                root.lastTx = n[1];
            }
        }
    }

    Timer {
        running: root.sampling && root.iface !== ""
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            traffic.command = ["cat",
                "/sys/class/net/" + root.iface + "/statistics/rx_bytes",
                "/sys/class/net/" + root.iface + "/statistics/tx_bytes"];
            traffic.running = true;
        }
    }

    onSamplingChanged: {
        if (!sampling) {
            lastRx = -1;
            lastTx = -1;
            rxRate = 0;
            txRate = 0;
        }
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Process {
        id: monitor
        command: ["nmcli", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: debounce.restart()
        }
    }

    Timer {
        id: debounce
        interval: 700
        onTriggered: root.refresh()
    }

    Process {
        id: action
        onExited: code => {
            root.busy = false;
            root.refresh();
        }
        stderr: StdioCollector {
            onStreamFinished: root.error = text.trim()
        }
    }

    function run(cmd) {
        if (root.busy) return;
        root.error = "";
        root.busy = true;
        action.command = cmd;
        action.running = true;
    }

    function connect(ssid, password) {
        if (password && password !== "")
            root.run(["nmcli", "device", "wifi", "connect", ssid, "password", password]);
        else
            root.run(["nmcli", "device", "wifi", "connect", ssid]);
    }

    function disconnect() {
        if (root.ssid === "") return;
        root.run(["nmcli", "connection", "down", "id", root.ssid]);
    }

    function toggleRadio() {
        root.run(["nmcli", "radio", "wifi", root.radio ? "off" : "on"]);
    }

    function rescan() {
        root.run(["nmcli", "device", "wifi", "rescan"]);
    }
}
