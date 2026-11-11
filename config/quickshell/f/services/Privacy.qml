pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property var ignore: /cava|quickshell|peak|easyeffects|pavucontrol|pwvucontrol|^capture\.|_aec_|echo.?cancel/i

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

    property bool polled: false
    readonly property bool camera: Islandd.cameraReady ? Islandd.camera : root.polled
    property bool watching: false

    Timer {
        interval: 4000
        repeat: true
        running: root.watching && !Islandd.cameraReady
        triggeredOnStart: true
        onTriggered: if (!probe.running) probe.running = true
    }

    Process {
        id: probe
        command: ["sh", "-c", "fuser -s /dev/video* 2>/dev/null"]
        onExited: (code) => root.polled = code === 0
    }
}
