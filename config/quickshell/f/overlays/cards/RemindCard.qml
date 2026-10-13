import Quickshell
import QtQuick
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: card
    property color tint: Colors.warn
    readonly property var item: Reminders.ringing
    readonly property Item hero: bell

    IslandTile {
        id: bell
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        size: 50
        round: true
        glyph: "󰂞"
        tint: card.tint
        sonar: true

        transform: Rotation {
            origin.x: bell.width / 2
            origin.y: 6
            angle: 0
            SequentialAnimation on angle {
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 12;  duration: 160; easing.type: Easing.InOutSine }
                NumberAnimation { to: -12; duration: 300; easing.type: Easing.InOutSine }
                NumberAnimation { to: 6;   duration: 220; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0;   duration: 180; easing.type: Easing.InOutSine }
                PauseAnimation  { duration: 1600 }
            }
        }
    }

    Column {
        anchors.left: bell.right
        anchors.leftMargin: 16
        anchors.right: acts.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: card.item ? card.item.title : ""
            color: Colors.fg
            font.family: Fonts.display
            font.features: { "tnum": 1 }
            font.pixelSize: 17
            font.weight: Font.DemiBold
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: card.item ? Qt.formatDateTime(new Date(card.item.at), "HH:mm") + "  ·  " + I18n.t("isle.remind") : ""
            color: Colors.alpha(card.tint, 0.85)
            font.family: Fonts.display
            font.features: { "tnum": 1 }
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    Row {
        id: acts
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        RoundKey {
            glyph: "󰒲"
            tint: Colors.fgDim
            onActivated: Reminders.snoozeRing(10)
        }

        RoundKey {
            glyph: "󰄬"
            tint: Colors.good
            onActivated: Reminders.finishRing()
        }
    }
}
