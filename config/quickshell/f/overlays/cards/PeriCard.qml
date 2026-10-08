import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: pc
    property var demo: ({})
    property string glyph: ""
    property string headline: ""

    readonly property var d: pc.demo && pc.demo.peri ? pc.demo.peri : null
    readonly property int charge: pc.d ? pc.d.pct : Peripherals.percent
    readonly property bool bad: pc.d ? pc.d.pct <= 10 : Peripherals.critical

    IslandBattery {
        id: cell
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        width: 66
        height: 32
        value: pc.charge / 100
        tint: pc.bad ? Colors.bad : Colors.warn
        lowAt: 0.3
        glyph: pc.glyph
    }

    Column {
        anchors.left: cell.right
        anchors.leftMargin: 16
        anchors.right: pct.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: I18n.t(pc.bad ? "isle.peri.dying" : "isle.peri.low")
            color: pc.bad ? Colors.bad : Colors.warn
            font.family: Fonts.display
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: pc.d ? pc.d.model : pc.headline
            color: Colors.fg
            font.family: Fonts.display
            font.pixelSize: 16
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    property real counted: 0
    Component.onCompleted: pc.counted = pc.charge
    onChargeChanged: pc.counted = pc.charge
    Behavior on counted { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }

    RollText {
        id: pct
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        text: Math.round(pc.counted) + "%"
        color: pc.bad ? Colors.bad : Colors.warn
        family: Fonts.display
        pixelSize: 28
        weight: Font.DemiBold
        rollDuration: 180
        overshoot: 0.8
    }
}
