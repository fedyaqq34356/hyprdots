pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property int morph: 650

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

    property color bg: srcBg
    Behavior on bg { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color bgAlt: srcBgAlt
    Behavior on bgAlt { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color fg: srcFg
    Behavior on fg { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color fgDim: srcFgDim
    Behavior on fgDim { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color outline: srcOutline
    Behavior on outline { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    property color outlineFaint: srcOutlineFaint
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

    property color bad: srcBad
    Behavior on bad { ColorAnimation { duration: root.morph; easing.type: Easing.InOutCubic } }

    readonly property real statusSat:
        Math.max(0.45, Math.min(0.85, bad.hslSaturation))
    readonly property real statusLight:
        Math.max(0.55, Math.min(0.80, bad.hslLightness))

    readonly property color warn: Qt.hsla(0.11, statusSat, statusLight, 1)
    readonly property color good: Qt.hsla(0.36, statusSat, statusLight, 1)
}
