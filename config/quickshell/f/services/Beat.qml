pragma Singleton

import Quickshell
import QtQuick
import "root:/services"

Singleton {
    id: root

    property real level: 0
    property real bass: 0
    property real treble: 0
    property real pulse: 0

    readonly property bool active: Cava.active

    signal hit()

    readonly property real sensitivity: 1.28
    readonly property int minGapMs: 110

    property real floorLevel: 0
    property double lastHit: 0

    Connections {
        target: Cava
        enabled: root.active

        function onLevelsChanged() { root.absorb(); }
    }

    function absorb() {
        const l = Cava.levels;
        const n = l.length;
        if (n === 0)
            return;

        let sum = 0;
        for (let i = 0; i < n; i++)
            sum += l[i];

        const low = (l[0] + l[1] + l[2]) / 3;
        const high = (l[n - 1] + l[n - 2] + l[n - 3]) / 3;
        const avg = sum / n;

        root.level = root.follow(root.level, avg);
        root.bass = root.follow(root.bass, low);
        root.treble = root.follow(root.treble, high);

        const now = Date.now();
        const over = low > root.floorLevel * root.sensitivity + 0.04;
        if (over && now - root.lastHit > root.minGapMs) {
            root.lastHit = now;
            root.pulse = 1;
            root.hit();
        } else {
            root.pulse = Math.max(0, root.pulse * 0.9 - 0.005);
        }

        root.floorLevel = root.floorLevel * 0.94 + low * 0.06;
    }

    function follow(current, target) {
        const k = target > current ? 0.45 : 0.12;
        return current + (target - current) * k;
    }

    onActiveChanged: {
        if (root.active)
            return;
        root.level = 0;
        root.bass = 0;
        root.treble = 0;
        root.pulse = 0;
        root.floorLevel = 0;
    }
}
