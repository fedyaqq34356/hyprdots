import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: tc
    property color tint: Colors.accent

    property var demo: ({})

    readonly property var d: tc.demo && tc.demo.timer ? tc.demo.timer : null
    readonly property var t: tc.d ? null : Timers.soonest

    IslandGauge {
        id: dial
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 60
        height: 60
        value: tc.d ? tc.d.progress : (tc.t ? Timers.progress(tc.t) : 0)
        tint: tc.tint
        showPct: false
        glyph: "󰔛"
        fillMs: 700
    }

    Column {
        anchors.left: dial.right
        anchors.leftMargin: 14
        anchors.right: timerActs.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            width: parent.width
            text: tc.d ? tc.d.label : (tc.t && tc.t.label ? tc.t.label : I18n.t("isle.src.timer"))
            color: Colors.alpha(Colors.fg, 0.55)
            font.family: Fonts.display
            font.pixelSize: 12
            elide: Text.ElideRight
        }

        RollText {
            text: tc.d ? Timers.clock(tc.d.left) : (tc.t ? Timers.clock(Timers.left(tc.t)) : "")
            color: Qt.lighter(tc.tint, 1.1)
            family: Fonts.display
            pixelSize: 28
            weight: Font.DemiBold
            rollDuration: 300
        }
    }

    Row {
        id: timerActs
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        RoundKey {
            glyph: tc.d || (tc.t && tc.t.running) ? "󰏤" : "󰐊"
            tint: tc.tint
            onActivated: if (tc.t) Timers.toggle(tc.t.id)
        }

        RoundKey {
            glyph: "󰅖"
            tint: Colors.fgDim
            onActivated: if (tc.t) Timers.cancel(tc.t.id)
        }
    }
}
