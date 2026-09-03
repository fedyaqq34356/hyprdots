pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    property real t: 0

    readonly property double epoch: Date.now()

    property int holders: 0

    readonly property bool live: root.holders > 0

    FrameAnimation {
        running: root.live
        onTriggered: root.t = (Date.now() - root.epoch) / 1000
    }

    function angle(period, offset) {
        return root.ramp(period, offset) * 360;
    }

    function ramp(period, offset) {
        const o = offset === undefined ? 0 : offset;
        const f = (root.t / period + o) % 1;
        return f < 0 ? f + 1 : f;
    }

    function wave(period, offset) {
        return 0.5 - 0.5 * Math.cos(2 * Math.PI * root.ramp(period, offset));
    }

    function outCubic(f) {
        const g = 1 - f;
        return 1 - g * g * g;
    }
}
