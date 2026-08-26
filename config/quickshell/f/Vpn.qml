pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

// VPN state for the bar.
//
// Detection is local and cheap: a WireGuard, OpenVPN or Tailscale interface
// that is up means a tunnel exists. The exit address is a separate, much more
// expensive question, so it is only asked when the tunnel state actually
// changes rather than on every poll.
Singleton {
    id: root

    property bool up: false
    property string iface: ""

    property string exitIp: ""
    property string exitCountry: ""
    property bool checking: false

    // Interface name prefixes that mean "tunnel".
    readonly property var prefixes: ["wg", "tun", "tailscale", "proton", "nordlynx"]

    readonly property string label: {
        if (!root.up) return "нет туннеля";
        let out = root.iface;
        if (root.checking) return out + "\nвыясняю адрес…";
        if (root.exitIp === "") return out + "\nадрес неизвестен";
        return out + "\n" + root.exitIp
             + (root.exitCountry === "" ? "" : "  ·  " + root.exitCountry);
    }

    // --- local detection --------------------------------------------------

    Process {
        id: probe
        command: ["ip", "-json", "link", "show", "up"]

        stdout: StdioCollector {
            onStreamFinished: {
                let links;
                try {
                    links = JSON.parse(text);
                } catch (e) {
                    return;
                }

                let found = "";
                for (const link of links) {
                    const name = link.ifname || "";
                    for (const p of root.prefixes) {
                        if (name.startsWith(p)) {
                            found = name;
                            break;
                        }
                    }
                    if (found !== "") break;
                }

                const wasUp = root.up;
                root.up = found !== "";
                root.iface = found;

                if (root.up !== wasUp) {
                    root.exitIp = "";
                    root.exitCountry = "";
                    if (root.up)
                        root.lookup();
                }
            }
        }
    }

    Timer {
        interval: 4000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: probe.running = true
    }

    // --- exit address -----------------------------------------------------
    //
    // This is the only part that leaves the machine, so it runs when the
    // tunnel comes up and when the user asks, never on a timer.

    Process {
        id: lookupProc
        command: ["curl", "-fsS", "--max-time", "6", "https://ifconfig.co/json"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.checking = false;
                let info;
                try {
                    info = JSON.parse(text);
                } catch (e) {
                    return;
                }
                root.exitIp = info.ip || "";
                root.exitCountry = info.country || "";
            }
        }

        onExited: root.checking = false
    }

    function lookup() {
        if (root.checking)
            return;
        root.checking = true;
        lookupProc.running = true;
    }

    function refresh() {
        probe.running = true;
        if (root.up)
            root.lookup();
    }
}
