import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/services"

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "qs-recording"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            readonly property bool watching:
                Recorder.active && Recorder.monitor !== ""
                && win.modelData.name !== Recorder.monitor

            visible: win.watching || badge.opacity > 0.01

            anchors {
                top: Prefs.barAtTop
                bottom: !Prefs.barAtTop
                right: true
            }

            implicitWidth: badge.width + 24
            implicitHeight: badge.height + 20
            exclusiveZone: 0
            color: "transparent"

            mask: Region { item: badge }

            Rectangle {
                id: badge

                anchors.centerIn: parent
                width: row.implicitWidth + 22
                height: 30
                radius: Shape.chip

                color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.16)
                border.width: 1
                border.color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.45)

                opacity: win.watching ? 1 : 0
                scale: win.watching ? 1 : 0.9

                Behavior on opacity {
                    NumberAnimation {
                        duration: Motion.base
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.decel
                    }
                }
                Behavior on scale {
                    SpringAnimation {
                        spring: Motion.panelSpring
                        damping: Motion.panelDamping
                        mass: Motion.panelMass
                        epsilon: 0.001
                    }
                }

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 8

                    Rectangle {
                        width: 9
                        height: 9
                        radius: 4.5
                        color: Colors.bad
                        anchors.verticalCenter: parent.verticalCenter

                        opacity: 0.25 + Phase.wave(1.4) * 0.75

                        PhaseHold { active: win.watching }
                    }

                    Text {
                        text: Recorder.clock
                        color: Colors.bad
                        font.family: Fonts.mono
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: Recorder.stop()
                }
            }
        }
    }
}
