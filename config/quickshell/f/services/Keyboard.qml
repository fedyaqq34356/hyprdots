pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property string layout: ""
    property var codes: []

    function short(x) {
        const m = { us: "EN", gb: "EN", ru: "RU", ua: "UA", de: "DE", fr: "FR", pl: "PL" };
        return m[x.toLowerCase()] || x.slice(0, 2).toUpperCase();
    }

    property bool caps: false
    property var capsLeds: []

    Process {
        running: true
        command: ["sh", "-c", "ls -d /sys/class/leds/*::capslock 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: root.capsLeds = this.text.split("\n").filter(l => l.trim() !== "")
        }
    }

    Instantiator {
        id: leds
        model: root.capsLeds
        delegate: FileView {
            required property string modelData
            path: modelData + "/brightness"
            blockLoading: true
        }
    }

    Timer {
        interval: 300
        repeat: true
        running: root.capsLeds.length > 0
        onTriggered: {
            let on = false;
            for (let i = 0; i < leds.count; i++) {
                const f = leds.objectAt(i);
                if (!f)
                    continue;
                f.reload();
                if (f.text().trim() !== "0" && f.text().trim() !== "")
                    on = true;
            }
            if (on !== root.caps)
                root.caps = on;
        }
    }

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
                    if (main) {
                        root.layout = main.active_keymap;
                        root.codes = (main.layout || "").split(",")
                            .filter(x => x !== "")
                            .map(x => root.short(x));
                    }
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
