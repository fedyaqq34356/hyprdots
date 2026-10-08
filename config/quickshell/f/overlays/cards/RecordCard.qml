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
    property var demo: ({})
    readonly property var d: card.demo && card.demo.record ? card.demo.record : null

    Item {
        id: recDot
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: 40
        height: 40

        Repeater {
            model: 2
            Rectangle {
                id: halo
                required property int index
                anchors.centerIn: parent
                width: 18; height: 18
                radius: 9
                color: Colors.alpha(Colors.bad, 0.5)
                opacity: 0
                SequentialAnimation {
                    running: true
                    loops: Animation.Infinite
                    PauseAnimation { duration: halo.index * 700 }
                    ParallelAnimation {
                        NumberAnimation { target: halo; property: "scale"; from: 1; to: 2.4; duration: 1400; easing.type: Easing.OutCubic }
                        NumberAnimation { target: halo; property: "opacity"; from: 0.8; to: 0; duration: 1400 }
                    }
                    PauseAnimation { duration: (1 - halo.index) * 700 }
                }
            }
        }

        RectangularShadow {
            anchors.fill: core
            radius: core.radius
            blur: 10
            color: Colors.alpha(Colors.bad, 0.8)
        }

        Rectangle {
            id: core
            anchors.centerIn: parent
            width: 18; height: 18
            radius: 9
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(Colors.bad, 1.3) }
                GradientStop { position: 1.0; color: Qt.darker(Colors.bad, 1.3) }
            }
            SequentialAnimation on scale {
                running: true
                loops: Animation.Infinite
                NumberAnimation { to: 0.82; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
            }
        }
    }

    Column {
        anchors.left: recDot.right
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0

        Text {
            text: I18n.t("isle.src.record")
            color: Colors.bad
            font.family: Fonts.display
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

        RollText {
            text: card.d ? card.d.clock : Recorder.clock
            color: Colors.fg
            family: Fonts.display
            pixelSize: 26
            weight: Font.DemiBold
        }
    }

    RoundKey {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        glyph: "󰓛"
        tint: Colors.bad
        onActivated: if (!card.d) Recorder.stop()
    }
}
