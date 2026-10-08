import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: card
    readonly property Item hero: shield
    property color tint: Colors.accent

    IslandTile {
        id: shield
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        size: 50
        glyph: Vpn.up ? "󰦝" : "󰦞"
        tint: Vpn.up ? card.tint : Colors.fgDim
        sonar: Vpn.up
        implode: !Vpn.up
        sparks: Vpn.up
    }

    Column {
        anchors.left: shield.right
        anchors.leftMargin: 16
        anchors.right: country.visible ? country.left : parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        StatusLine {
            text: I18n.t(Vpn.up ? "isle.vpn.on" : "isle.vpn.off")
            tint: Vpn.up ? card.tint : Colors.alpha(Colors.fg, 0.5)
            ok: Vpn.up
        }

        Text {
            width: parent.width
            visible: Vpn.up
            text: Vpn.iface + (Vpn.exitIp !== "" ? "  ·  " + Vpn.exitIp : "")
            color: Colors.fg
            font.family: Fonts.display
            font.pixelSize: 15
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    Rectangle {
        id: country
        anchors.right: parent.right
        anchors.rightMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        visible: Vpn.up && Vpn.exitCountry !== ""
        width: cText.implicitWidth + 20
        height: 28
        radius: 14
        color: Colors.alpha(card.tint, 0.2)
        border.width: 1
        border.color: Colors.alpha(card.tint, 0.4)
        scale: 0.4
        Component.onCompleted: scale = 1
        Behavior on scale { Spring {} }

        Text {
            id: cText
            anchors.centerIn: parent
            text: Vpn.exitCountry
            color: Qt.lighter(card.tint, 1.2)
            font.family: Fonts.display
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }
}
