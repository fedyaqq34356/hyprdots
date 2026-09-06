import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "list"

    readonly property bool bare: face.variant === "count"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    readonly property var recent: NotifHistory.items.slice(0, 4)

    opacity: NotifHistory.count > 0 ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    Loader {
        id: loader
        sourceComponent: face.variant === "count" ? count : list
    }

    Component {
        id: count

        Row {
            spacing: 14

            Item {
                width: 58
                height: 58
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    antialiasing: true
                    color: NotifHistory.unseen > 0
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                  Colors.accent.b, 0.16)
                        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                  Colors.fgDim.b, 0.08)
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                }

                Text {
                    anchors.centerIn: parent
                    text: NotifHistory.unseen > 0 ? "󰂚" : "󰂜"
                    color: NotifHistory.unseen > 0 ? Colors.accent : Colors.fgDim
                    font.family: face.mono
                    font.pixelSize: 24
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: -4

                Text {
                    text: NotifHistory.unseen > 0
                        ? NotifHistory.unseen : NotifHistory.count
                    color: Colors.fg
                    opacity: 0.92
                    font.family: face.mono
                    font.pixelSize: 46
                    font.weight: Font.Thin
                }

                Text {
                    text: I18n.plural("plural.notification",
                                      NotifHistory.unseen > 0
                                      ? NotifHistory.unseen : NotifHistory.count)
                    color: Colors.fgDim
                    opacity: 0.55
                    font.family: face.mono
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
            }
        }
    }

    Component {
        id: list

        Rectangle {
            implicitWidth: 300
            implicitHeight: stack.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: stack
                anchors.centerIn: parent
                width: parent.width - 34
                spacing: 12

                Repeater {
                    model: face.recent

                    Row {
                        required property var modelData

                        width: stack.width
                        spacing: 11

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            height: 26
                            radius: Shape.detail + 2
                            antialiasing: true
                            color: Qt.rgba(
                                NotifHistory.appColor(modelData.app).r,
                                NotifHistory.appColor(modelData.app).g,
                                NotifHistory.appColor(modelData.app).b, 0.20)

                            Text {
                                anchors.centerIn: parent
                                text: NotifHistory.appLetter(modelData.app)
                                color: NotifHistory.appColor(modelData.app)
                                font.family: face.mono
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 37
                            spacing: 2

                            Text {
                                width: parent.width
                                text: modelData.summary
                                color: Colors.fg
                                elide: Text.ElideRight
                                font.family: face.mono
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: modelData.body
                                color: Colors.fgDim
                                opacity: 0.65
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                font.family: face.mono
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }
}
