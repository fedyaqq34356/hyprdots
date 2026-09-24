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

    readonly property real isleOpenResponse:  0.46
    readonly property real isleOpenDamping:   0.72
    readonly property int  isleCloseMs:       300

    readonly property real isleWidthResponse: 0.38
    readonly property real isleWidthDamping:  0.86

    readonly property real isleHoverResponse: 0.38
    readonly property real isleHoverDamping:  0.80
    readonly property real isleHoverScale:    1.028
    readonly property real islePeekResponse:  0.30
    readonly property real islePeekDamping:   0.50
    readonly property real islePeekScale:     1.04
    readonly property int  islePeekHoldMs:    90

    readonly property int  isleRevealDelay:   80
    readonly property int  isleRevealMs:      280
    readonly property int  isleHideMs:        150

    readonly property var  isleContent:       [0.22, 1.00, 0.36, 1.00, 1, 1]
    readonly property int  isleContentMs:     340

    readonly property real isleJelly:      0.052
    readonly property real isleJellyCap:   0.070
    readonly property real isleJellyCross: 0.62

    readonly property real isleTapScale:    0.965
    readonly property real isleTapResponse: 0.22
    readonly property real isleTapDamping:  0.70

    readonly property int  isleGlossMs:    760
    readonly property real isleGlossAlpha: 0.16

    readonly property int  isleThrobMs:    1100
    readonly property real isleThrobScale: 1.022

    readonly property int stagger: 28

    function mix(a, b, t) { return a + (b - a) * t; }

    function delay(index) {
        return Math.min(index, 12) * root.stagger;
    }
}
