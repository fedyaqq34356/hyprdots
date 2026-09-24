pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property int morph: 650

    readonly property bool apple: Prefs.apple

    property color srcBg:           "#18120e"
    property color srcBgAlt:        "#51443a"
    property color srcFg:           "#ece0d9"
    property color srcFgDim:        "#d6c3b5"
    property color srcOutline:      "#9f8e81"
    property color srcOutlineFaint: "#51443a"
    property color srcAccent:       "#feb879"
    property color srcAccentAlt:    "#c8cc7a"
    property color srcAccentText:   "#4b2700"
    property color srcBad:          "#ffb4ab"

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.cache/matugen/colors.json"
        watchChanges: true

        onFileChanged: reload()
        onLoaded: {
            let p;
            try {
                p = JSON.parse(file.text());
            } catch (e) {
                return;
            }

            if (p.bg)           root.srcBg = p.bg;
            if (p.bgAlt)        root.srcBgAlt = p.bgAlt;
            if (p.fg)           root.srcFg = p.fg;
            if (p.fgDim)        root.srcFgDim = p.fgDim;
            if (p.outline)      root.srcOutline = p.outline;
            if (p.outlineFaint) root.srcOutlineFaint = p.outlineFaint;
            if (p.accent)       root.srcAccent = p.accent;
            if (p.accentAlt)    root.srcAccentAlt = p.accentAlt;
            if (p.accentText)   root.srcAccentText = p.accentText;
            if (p.bad)          root.srcBad = p.bad;
        }
    }

    property color bg: root.apple ? "#000000" : srcBg
    Behavior on bg { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color bgAlt: root.apple ? "#2c2c2e" : srcBgAlt
    Behavior on bgAlt { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color fg: root.apple ? "#f5f5f7" : srcFg
    Behavior on fg { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color fgDim: root.apple ? "#aeaeb2" : srcFgDim
    Behavior on fgDim { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color outline: root.apple ? "#636366" : srcOutline
    Behavior on outline { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color outlineFaint: root.apple ? "#38383a" : srcOutlineFaint
    Behavior on outlineFaint { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color accent: srcAccent
    Behavior on accent {
        SequentialAnimation {
            PauseAnimation { duration: 90 }
            ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic }
        }
    }

    property color accentAlt: srcAccentAlt
    Behavior on accentAlt {
        SequentialAnimation {
            PauseAnimation { duration: 140 }
            ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic }
        }
    }

    property color accentText: srcAccentText
    Behavior on accentText { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color bad: root.apple ? "#ff453a" : srcBad
    Behavior on bad { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    function step(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t,
                       a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t,
                       1);
    }

    function mix(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t,
                       a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t,
                       a.a + (b.a - a.a) * t);
    }

    function alpha(c, a) {
        return Qt.rgba(c.r, c.g, c.b, a);
    }

    readonly property color surface1: root.step(root.bg, root.bgAlt, 0.34)
    readonly property color surface2: root.step(root.bg, root.bgAlt, 0.67)
    readonly property color surface3: root.bgAlt

    function surfaceFor(level) {
        switch (Math.max(0, Math.min(3, level))) {
        case 1:  return root.surface1;
        case 2:  return root.surface2;
        case 3:  return root.surface3;
        default: return root.bg;
        }
    }

    readonly property real statusSat:
        Math.max(0.45, Math.min(0.85, bad.hslSaturation))
    readonly property real statusLight:
        Math.max(0.55, Math.min(0.80, bad.hslLightness))

    readonly property color warn: root.apple ? "#ff9f0a" : Qt.hsla(0.11, statusSat, statusLight, 1)
    readonly property color good: root.apple ? "#30d158" : Qt.hsla(0.36, statusSat, statusLight, 1)

    readonly property color selection:
        Qt.hsla(Math.max(0, root.accent.hslHue),
                Math.min(0.72, Math.max(0.5, root.accent.hslSaturation)),
                0.52, 1)

    readonly property color accentWash: root.step(root.bg, root.accent, 0.10)
    readonly property color accentSoft: root.step(root.bg, root.accent, 0.22)
    readonly property color accentDim:  root.step(root.bg, root.accent, 0.48)

    readonly property color accentGlow:
        Qt.hsla(root.accent.hslHue,
                Math.min(1.0, root.accent.hslSaturation * 1.15),
                Math.max(0.62, root.accent.hslLightness),
                1)

    readonly property color shadowTone:
        Qt.hsla(root.bg.hslHue,
                Math.min(0.55, root.bg.hslSaturation * 1.4),
                0.035,
                1)

    function shadow(a) {
        return root.alpha(root.shadowTone, a);
    }

    readonly property color lightTone: root.step("#ffffff", root.accentGlow, 0.22)

    function light(a) {
        return root.alpha(root.lightTone, a);
    }
}
