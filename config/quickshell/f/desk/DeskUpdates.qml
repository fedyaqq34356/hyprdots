import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "count"

    readonly property bool bare: face.variant === "count"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    opacity: Updates.ready && Updates.count > 0 ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    Loader {
        id: loader
        sourceComponent: face.variant === "list" ? list : count
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
                    color: Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                   Colors.accentAlt.b, 0.16)
                }

                Text {
                    anchors.centerIn: parent
                    text: Updates.busy ? "󰇚" : "󰏗"
                    color: Colors.accentAlt
                    font.family: face.mono
                    font.pixelSize: 24
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: -4

                Text {
                    text: Updates.count
                    color: Colors.fg
                    opacity: 0.92
                    font.family: face.mono
                    font.pixelSize: 46
                    font.weight: Font.Thin
                }

                Text {
                    text: I18n.t("desk.updates")
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
            implicitWidth: 280
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
                spacing: 9

                Row {
                    width: stack.width

                    Text {
                        text: "󰏗"
                        color: Colors.accentAlt
                        font.family: face.mono
                        font.pixelSize: 13
                    }

                    Item { width: 8; height: 1 }

                    Text {
                        text: Updates.count + "  " + I18n.t("desk.updates")
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: face.mono
                        font.pixelSize: 11
                        font.letterSpacing: 1
                    }
                }

                Repeater {
                    model: Updates.all.slice(0, 6)

                    Row {
                        required property var modelData

                        width: stack.width
                        spacing: 8

                        Text {
                            width: parent.width - 90
                            text: modelData.name
                            color: Colors.fg
                            elide: Text.ElideRight
                            font.family: face.mono
                            font.pixelSize: 12
                        }

                        Text {
                            width: 82
                            horizontalAlignment: Text.AlignRight
                            text: modelData.to
                            color: Colors.accentAlt
                            opacity: 0.8
                            elide: Text.ElideLeft
                            font.family: face.mono
                            font.pixelSize: 11
                        }
                    }
                }

                Text {
                    visible: Updates.count > 6
                    text: "+" + (Updates.count - 6)
                    color: Colors.fgDim
                    opacity: 0.5
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }
}
