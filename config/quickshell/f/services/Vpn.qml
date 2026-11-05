pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    property bool up: false
    property string iface: ""

    property string exitIp: ""
    property string exitCountry: ""
    property bool checking: false

    readonly property string label: {
        if (!root.up) return I18n.t("net.noTunnel");
        let out = root.iface;
        if (root.checking) return out + I18n.t("net.addrLooking");
        if (root.exitIp === "") return out + I18n.t("net.addrUnknown");
        return out + "\n" + root.exitIp
             + (root.exitCountry === "" ? "" : "  ·  " + root.exitCountry);
    }

    readonly property string linkIface: Islandd.vpnIface

    onLinkIfaceChanged: {
        const found = root.linkIface;
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
        if (root.up)
            root.lookup();
    }
}
