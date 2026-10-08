import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: pw
    property var demo: ({})
    property color tint: Colors.accent

    readonly property var d: pw.demo && pw.demo.power ? pw.demo.power : null
    readonly property int pct: pw.d ? pw.d.pct : Power.percent
    readonly property bool charging: pw.d ? pw.d.charging : Power.plugged
    readonly property bool topped: !pw.d && Power.plugged && !Power.charging
    readonly property bool low: !pw.charging && pw.pct <= 15
    readonly property color hue: pw.charging ? Colors.good
                               : pw.low ? Colors.bad : pw.tint

    property real counted: 0
    Component.onCompleted: pw.counted = pw.pct
    onPctChanged: pw.counted = pw.pct
    Behavior on counted { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    IslandBattery {
        id: cell
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 74
        height: 36
        value: pw.pct / 100
        charging: pw.charging
        tint: pw.hue
        lowAt: 0.15
    }

    IslandBurst {
        x: cell.x + (cell.width - 4) / 2
        y: cell.y + cell.height / 2
        visible: pw.charging
        tint: Colors.good
        reach: 46
        delay: 380
    }

    Column {
        anchors.left: cell.right
        anchors.leftMargin: 16
        anchors.right: big.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: I18n.t(pw.topped ? "isle.power.plugged"
                       : pw.charging ? "isle.power.on"
                       : pw.low ? "isle.power.low" : "isle.power.off")
            color: pw.hue
            font.family: Fonts.display
            font.pixelSize: 16
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            visible: Power.timeLabel !== "" && !pw.d
            text: I18n.t(pw.charging ? "isle.power.till"
                                     : "isle.power.left")
                  + Power.timeLabel
            color: Colors.alpha(Colors.fg, 0.55)
            font.family: Fonts.display
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    RollText {
        id: big
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(pw.counted) + "%"
        color: Colors.fg
        family: Fonts.display
        pixelSize: 28
        weight: Font.DemiBold
        rollDuration: 180
        overshoot: 0.8
    }
}
