import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "ring"

    readonly property bool bare: face.variant === "ring"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    opacity: Timers.items.length > 0 ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    readonly property var soon: Timers.soonest

    Loader {
        id: loader
        sourceComponent: face.variant === "list" ? list : ring
    }

    Component {
        id: ring

        TimerDial {
            id: dial

            implicitWidth: 190
            implicitHeight: 190
            width: 190
            height: 190

            readonly property int secs: face.soon ? Timers.left(face.soon) : 0

            progress: Timers.progress(face.soon)
            running: face.soon ? face.soon.running : false
            ringing: face.soon ? face.soon.ringing : false
            remaining: secs
            urgentAt: Math.max(3, Prefs.timerTickSec)
            thickness: 5

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Timers.clock(dial.secs)
                    color: dial.live
                    font.family: face.mono
                    font.pixelSize: 30
                    font.weight: Font.Medium
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 140
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: face.soon && face.soon.label !== ""
                        ? face.soon.label
                        : (Timers.running > 1
                            ? I18n.count("timer.running", Timers.running) : "")
                    color: Colors.fgDim
                    opacity: 0.7
                    font.family: Fonts.display
                    font.pixelSize: 12
                }
            }
        }
    }

    Component {
        id: list

        Rectangle {
            implicitWidth: 260
            implicitHeight: rows.implicitHeight + 28
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: rows

                anchors.centerIn: parent
                width: parent.width - 28
                spacing: 8

                Repeater {
                    model: Timers.items

                    Item {
                        required property var modelData

                        width: rows.width
                        height: 30

                        Rectangle {
                            anchors.fill: parent
                            radius: Shape.chip
                            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                           Colors.bgAlt.b, 0.35)
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Timers.progress(modelData)
                            radius: Shape.chip
                            color: modelData.ringing
                                ? Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.35)
                                : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b,
                                          modelData.running ? 0.22 : 0.08)
                            Behavior on width {
                                NumberAnimation { duration: 950; easing.type: Easing.Linear }
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 90
                            elide: Text.ElideRight
                            text: modelData.label !== ""
                                ? modelData.label
                                : Timers.human(modelData.total)
                            color: Colors.fg
                            opacity: 0.85
                            font.family: Fonts.display
                            font.pixelSize: 12
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: Timers.clock(Timers.left(modelData))
                            color: modelData.ringing ? Colors.bad : Colors.fg
                            font.family: face.mono
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
