pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool available: false
    property real value: 0
    property string device: ""

    function parse(line) {
        const f = line.trim().split(",");
        if (f.length < 5) return;
        root.device = f[0];
        root.value = parseInt(f[3]) / 100;
        root.available = true;
    }

    Process {
        id: probe
        command: ["brightnessctl", "-c", "backlight", "-m", "i"]
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
        onExited: code => { if (code !== 0) root.available = false; }
    }

    Process {
        id: apply
        stdout: StdioCollector {
            onStreamFinished: root.parse(text)
        }
    }

    Component.onCompleted: probe.running = true

    function change(delta) {
        if (!root.available) return;
        const pct = Math.max(1, Math.min(100, Math.round(root.value * 100 + delta * 100)));
        apply.command = ["brightnessctl", "-c", "backlight", "-m", "set", pct + "%"];
        apply.running = true;
    }

    function set(fraction) {
        if (!root.available) return;
        const pct = Math.max(1, Math.min(100, Math.round(fraction * 100)));
        apply.command = ["brightnessctl", "-c", "backlight", "-m", "set", pct + "%"];
        apply.running = true;
    }
}
