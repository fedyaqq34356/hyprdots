pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property int bars: 12

    property var levels: root.zeros()

    property var smooth: root.zeros()

    readonly property real follow: 0.42

    function zeros() {
        const out = [];
        for (let i = 0; i < root.bars; i++) out.push(0);
        return out;
    }

    property int watchers: 0

    function hold()    { root.watchers++; }
    function release() { root.watchers = Math.max(0, root.watchers - 1); }

    property bool active: Media.has && Media.playing && root.watchers > 0

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
                const n = root.bars;
                const out = new Array(n);
                for (let i = 0; i < n; i++) {
                    const v = +parts[i] / 100;
                    out[i] = v > 0 ? (v < 1 ? v : 1) : 0;
                }
                const prev = root.smooth;
                const eased = new Array(n);
                for (let i = 0; i < n; i++) {
                    const p = prev[i] === undefined ? 0 : prev[i];
                    eased[i] = p + (out[i] - p) * root.follow;
                }

                root.levels = out;
                root.smooth = eased;
            }
        }
    }

    onActiveChanged: {
        if (active)
            return;
        root.levels = root.zeros();
        root.smooth = root.zeros();
    }
}
