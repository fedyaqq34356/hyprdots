import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "speed"

    readonly property bool bare: face.variant === "speed"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Component.onCompleted: Network.hold()
    Component.onDestruction: Network.release()

    function rate(bytes) {
        return Network.human(bytes);
    }

    Loader {
        id: loader
        sourceComponent: face.variant === "link" ? link : speed
    }

    Component {
        id: speed

        Column {
            spacing: 6

            Repeater {
                model: [
                    { glyph: "󰇚", value: Network.rxRate, tint: Colors.accent },
                    { glyph: "󰕒", value: Network.txRate, tint: Colors.accentAlt }
                ]

                Row {
                    required property var modelData
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.glyph
                        color: modelData.tint
                        opacity: 0.85
                        font.family: face.mono
                        font.pixelSize: 18
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: face.rate(modelData.value)
                        color: Colors.fg
                        opacity: 0.92
                        font.family: face.mono
                        font.pixelSize: 26
                        font.weight: Font.Light
                    }
                }
            }
        }
    }

    Component {
        id: link

        Rectangle {
            implicitWidth: 250
            implicitHeight: 96
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Row {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Item {
                    width: 46
                    height: 46
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        antialiasing: true
                        color: Network.connected
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                      Colors.accent.b, 0.16)
                            : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                      Colors.fgDim.b, 0.08)
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Network.glyph
                        color: Network.connected ? Colors.accent : Colors.fgDim
                        font.family: face.mono
                        font.pixelSize: 20
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 60
                    spacing: 5

                    Text {
                        width: parent.width
                        text: Network.connected && Network.ssid !== ""
                            ? Network.ssid : I18n.t("net.notConnected")
                        color: Colors.fg
                        elide: Text.ElideRight
                        font.family: face.mono
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: {
                            const parts = [];
                            if (Network.strength > 0)
                                parts.push(Network.strength + "%");
                            if (Network.linkRate !== "")
                                parts.push(Network.linkRate);
                            return parts.join("  ·  ");
                        }
                        visible: text !== ""
                        color: Colors.fgDim
                        opacity: 0.7
                        elide: Text.ElideRight
                        font.family: face.mono
                        font.pixelSize: 11
                    }

                    Row {
                        spacing: 12

                        Text {
                            text: "󰇚 " + face.rate(Network.rxRate)
                            color: Colors.accent
                            opacity: 0.85
                            font.family: face.mono
                            font.pixelSize: 11
                        }

                        Text {
                            text: "󰕒 " + face.rate(Network.txRate)
                            color: Colors.accentAlt
                            opacity: 0.85
                            font.family: face.mono
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
