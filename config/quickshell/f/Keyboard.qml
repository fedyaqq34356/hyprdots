pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property string layout: ""

    readonly property string code: {
        const l = layout.toLowerCase();
        if (l.startsWith("english"))   return "EN";
        if (l.startsWith("russian"))   return "RU";
        if (l.startsWith("ukrainian")) return "UA";
        if (l.startsWith("german"))    return "DE";
        if (l.startsWith("french"))    return "FR";
        if (l.startsWith("polish"))    return "PL";
        return layout === "" ? "--" : layout.slice(0, 2).toUpperCase();
    }

    Process {
        id: query
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kb = JSON.parse(text).keyboards;
                    const main = kb.find(k => k.main) || kb[kb.length - 1];
                    if (main) root.layout = main.active_keymap;
                } catch (e) {}
            }
        }
    }

    Component.onCompleted: query.running = true

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "activelayout") return;
            const comma = event.data.indexOf(",");
            if (comma !== -1) root.layout = event.data.slice(comma + 1);
        }
    }

    function next() {
        Hyprland.dispatch("switchxkblayout all next");
    }
}
