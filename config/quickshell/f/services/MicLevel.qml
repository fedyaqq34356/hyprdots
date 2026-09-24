pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    property real level: 0

    readonly property real follow: 0.38

    property int watchers: 0

    function hold()    { root.watchers++; }
    function release() { root.watchers = Math.max(0, root.watchers - 1); }

    readonly property var source: Pipewire.defaultAudioSource
    readonly property string node:
        root.source && root.source.name ? root.source.name : "auto"

    readonly property bool muted:
        root.source && root.source.audio ? root.source.audio.muted : false

    readonly property bool active: root.watchers > 0 && !root.muted

    readonly property string cfg:
        Quickshell.env("XDG_RUNTIME_DIR") + "/qs-mic-cava.conf"

    Process {
        id: proc
        running: root.active

        command: ["sh", "-c",
            "printf '%s\\n' "
            + "'[general]' 'framerate = 30' 'autosens = 1' 'bars = 2' "
            + "'channels = mono' 'mono_option = average' "
            + "'[input]' 'method = pipewire' 'source = " + root.node + "' "
            + "'[output]' 'method = raw' 'raw_target = /dev/stdout' "
            + "'data_format = ascii' 'ascii_max_range = 100' "
            + "'[smoothing]' 'noise_reduction = 30' "
            + "> \"$1\" && exec cava -p \"$1\"",
            "sh", root.cfg]

        stdout: SplitParser {
            splitMarker: "\n"
            onRead: data => {
                const v = +data.split(";")[0] / 100;
                const now = v > 0 ? (v < 1 ? v : 1) : 0;
                root.level = root.level + (now - root.level) * root.follow;
            }
        }
    }

    onActiveChanged: if (!root.active) root.level = 0
}
