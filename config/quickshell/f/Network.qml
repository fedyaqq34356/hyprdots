pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool radio: true
    property bool connected: false
    property string ssid: ""
    property int strength: 0
    property var networks: []
    property bool busy: false
    property string error: ""

    readonly property string glyph: {
        if (!radio) return "󰤮";
        if (!connected) return "󰤯";
        if (strength >= 75) return "󰤨";
        if (strength >= 50) return "󰤥";
        if (strength >= 25) return "󰤢";
        return "󰤟";
    }

    // nmcli -t escapes field separators as "\:", so a plain split would cut
    // SSIDs containing a colon in half.
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
        command: ["nmcli", "-t", "-f", "ACTIVE,SSID,SIGNAL,SECURITY", "device", "wifi"]
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
                    if (entry.active) active = entry;
                    // Same SSID can appear once per band or access point:
                    // keep the strongest reading, but never lose the fact
                    // that one of them is the connection we are on.
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
            }
        }
    }

    Process {
        id: radioState
        command: ["nmcli", "-t", "radio", "wifi"]
        stdout: StdioCollector {
            onStreamFinished: root.radio = text.trim() === "enabled"
        }
    }

    function refresh() {
        radioState.running = true;
        scan.running = true;
    }

    Component.onCompleted: refresh()

    Timer {
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    // NetworkManager reports every state change here, so the bar reacts to a
    // dropped link immediately instead of at the next poll.
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
