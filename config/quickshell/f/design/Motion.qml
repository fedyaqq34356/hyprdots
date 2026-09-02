pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property int instant: 90
    readonly property int fast:    140
    readonly property int base:    220
    readonly property int slow:    360
    readonly property int lazy:    560

    readonly property var standard: [0.20, 0.00, 0.00, 1.00, 1, 1]
    readonly property var decel:    [0.05, 0.70, 0.10, 1.00, 1, 1]
    readonly property var accel:    [0.30, 0.00, 0.80, 0.15, 1, 1]
    readonly property var expo:     [0.16, 1.00, 0.30, 1.00, 1, 1]
    readonly property var glide:    [0.10, 0.90, 0.15, 1.00, 1, 1]
    readonly property var quick:    [0.40, 0.00, 0.90, 0.30, 1, 1]
    readonly property var snap:     [0.20, 1.28, 0.30, 1.00, 1, 1]
    readonly property var pop:      [0.16, 1.20, 0.28, 1.00, 1, 1]
    readonly property var elastic:  [0.12, 1.45, 0.35, 1.00, 1, 1]

    readonly property real tapSpring:  5.0
    readonly property real tapDamping: 0.34
    readonly property real tapMass:    0.55

    readonly property real panelSpring:  3.2
    readonly property real panelDamping: 0.42
    readonly property real panelMass:    0.9

    readonly property real heavySpring:  2.2
    readonly property real heavyDamping: 0.62
    readonly property real heavyMass:    1.4

    readonly property int stagger: 28

    function delay(index) {
        return Math.min(index, 12) * root.stagger;
    }
}
