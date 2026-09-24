pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var ignore: /cava|quickshell|peak|easyeffects|pavucontrol|pwvucontrol/i

    readonly property bool mic: {
        const list = Pipewire.nodes ? Pipewire.nodes.values : [];
        for (const n of list) {
            if (!n || !n.isStream || !n.audio)
                continue;
            if ((n.type & PwNodeType.AudioInStream) !== PwNodeType.AudioInStream)
                continue;
            if (root.ignore.test(n.name || ""))
                continue;
            return true;
        }
        return false;
    }

    property bool camera: false
    property bool watching: false

    Timer {
        interval: 4000
        repeat: true
        running: root.watching
        triggeredOnStart: true
        onTriggered: if (!probe.running) probe.running = true
    }

    Process {
        id: probe
        command: ["sh", "-c", "fuser -s /dev/video* 2>/dev/null"]
        onExited: (code) => root.camera = code === 0
    }
}
