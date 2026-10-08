import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: bc
    readonly property Item hero: btTile
    property var demo: ({})
    property string glyph: ""
    property string headline: ""
    property color tint: Colors.accent

    readonly property var d: bc.demo && bc.demo.bt ? bc.demo.bt : null
    readonly property var dev: Bt.primary
    readonly property bool gone: bc.d ? !bc.d.on : Bt.connectedCount <= 0
    readonly property string name: bc.d ? bc.d.name : bc.headline
    readonly property real charge: bc.d ? bc.d.battery
        : (bc.dev && bc.dev.batteryAvailable ? bc.dev.battery : -1)
    readonly property color hue: bc.gone ? Colors.fgDim : bc.tint

    IslandTile {
        id: btTile
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        size: 52
        round: true
        glyph: bc.gone ? "󰂲" : (bc.d ? "󰋋" : bc.glyph)
        tint: bc.hue
        sonar: !bc.gone
        implode: bc.gone
        sparks: !bc.gone

        transform: Translate {
            id: shake
            SequentialAnimation on x {
                running: bc.gone
                NumberAnimation { to: -4; duration: 50 }
                NumberAnimation { to: 4;  duration: 70 }
                NumberAnimation { to: -3; duration: 60 }
                NumberAnimation { to: 2;  duration: 60 }
                NumberAnimation { to: 0;  duration: 60 }
            }
        }
    }

    Column {
        anchors.left: btTile.right
        anchors.leftMargin: 16
        anchors.right: btGauge.visible ? btGauge.left : parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        StatusLine {
            text: bc.gone ? I18n.t("isle.bt.gone") : I18n.t("isle.bt.on")
            tint: bc.gone ? Colors.alpha(Colors.fg, 0.5) : bc.hue
            ok: !bc.gone
        }

        Marquee {
            width: parent.width
            text: bc.name
            color: Colors.fg
            family: Fonts.display
            pixelSize: 16
            weight: Font.DemiBold
        }
    }

    IslandGauge {
        id: btGauge
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 56
        height: 56
        visible: bc.charge >= 0 && !bc.gone
        value: bc.charge
        tint: bc.charge <= 0.2 ? Colors.bad : Colors.good
        glyph: "󰋋"
    }
}
