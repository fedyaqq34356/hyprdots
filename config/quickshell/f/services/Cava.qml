pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property int bars: 12

    property var levels: root.zeros()

    function zeros() {
        const out = [];
        for (let i = 0; i < root.bars; i++) out.push(0);
        return out;
    }

    property bool active: Media.has && Media.playing

    readonly property string config:
        Quickshell.env("HOME") + "/.config/cava/config-bar"

    Process {
        id: proc
        running: root.active
        command: ["cava", "-p", root.config]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const parts = data.split(";");
                const out = [];
                for (let i = 0; i < root.bars; i++) {
                    const v = parseInt(parts[i]);
                    out.push(isNaN(v) ? 0 : Math.max(0, Math.min(1, v / 100)));
                }
                root.levels = out;
            }
        }
    }

    onActiveChanged: if (!active) root.levels = root.zeros();
}
