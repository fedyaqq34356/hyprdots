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
    property string headline: ""
    property color tint: Colors.accent

    Item {
        id: fanBox
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 52
        height: 52

        RectangularShadow {
            anchors.centerIn: parent
            width: 34; height: 34
            radius: 17
            blur: 22
            color: Colors.alpha(card.tint, Network.connected ? 0.45 : 0)
        }

        IslandWifi {
            anchors.centerIn: parent
            width: 46
            height: 38
            on: Network.connected
            strength: Network.strength / 100
            tint: card.tint
        }
    }

    Column {
        anchors.left: fanBox.right
        anchors.leftMargin: 16
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        StatusLine {
            text: Network.connected
                  ? (Network.linkRate !== "" ? Network.linkRate
                                             : Network.strength + "%")
                  : I18n.t("isle.net.searching")
            tint: Network.connected ? card.tint : Colors.alpha(Colors.fg, 0.5)
            ok: Network.connected
        }

        Text {
            width: parent.width
            text: card.headline
            color: Colors.fg
            font.family: Fonts.display
            font.pixelSize: 16
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }
}
