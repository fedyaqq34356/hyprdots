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
    readonly property Item hero: bell

    SystemClock { id: alarmNow; precision: SystemClock.Minutes }

    IslandTile {
        id: bell
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        size: 50
        round: true
        glyph: "󰀠"
        tint: Colors.bad
        sonar: true

        transform: Rotation {
            origin.x: bell.width / 2
            origin.y: 6
            angle: 0
            SequentialAnimation on angle {
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 16;  duration: 140; easing.type: Easing.InOutSine }
                NumberAnimation { to: -16; duration: 280; easing.type: Easing.InOutSine }
                NumberAnimation { to: 10;  duration: 220; easing.type: Easing.InOutSine }
                NumberAnimation { to: -6;  duration: 180; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0;   duration: 140; easing.type: Easing.InOutSine }
                PauseAnimation  { duration: 700 }
            }
        }
    }

    Column {
        anchors.left: bell.right
        anchors.leftMargin: 16
        anchors.right: alarmActs.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            width: parent.width
            text: I18n.t("isle.alarm")
            color: Colors.bad
            font.family: Fonts.display
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            text: Qt.formatDateTime(alarmNow.date, "HH:mm")
            color: Colors.fg
            font.family: Fonts.display
            font.pixelSize: 28
            font.weight: Font.DemiBold
        }
    }

    Row {
        id: alarmActs
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        RoundKey {
            glyph: "󰒲"
            tint: Colors.warn
            onActivated: {
                const t = Timers.items.find(x => x.ringing);
                if (t) Timers.snooze(t.id, 300);
            }
        }

        RoundKey {
            glyph: "󰅖"
            tint: Colors.bad
            onActivated: Timers.dismissAll()
        }
    }
}
