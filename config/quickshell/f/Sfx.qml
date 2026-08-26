pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string dir:
        Quickshell.env("HOME") + "/.local/share/sounds/f/"

    property var lastPlayed: ({})

    Process { id: player }

    function play(file, volume, minGapMs) {
        const now = Date.now();
        const gap = minGapMs === undefined ? 300 : minGapMs;
        if (now - (root.lastPlayed[file] || 0) < gap)
            return;

        const stamps = root.lastPlayed;
        stamps[file] = now;
        root.lastPlayed = stamps;

        player.running = false;
        player.command = ["pw-play",
                          "--volume=" + (volume === undefined ? 0.5 : volume),
                          root.dir + file];
        player.running = true;
    }

    function notify()   { root.play("notify.wav", 0.5, 350); }
    function critical() { root.play("critical.wav", 0.5, 350); }

    function limit()    { root.play("limit.wav", 0.45, 220); }
}
