import Quickshell
import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: face

    property string variant: "full"

    readonly property bool bare: face.variant === "compact"
                              || face.variant === "hero"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Loader {
        id: loader
        sourceComponent: face.variant === "compact" ? compact
                       : face.variant === "hero" ? hero
                       : full
    }

    Component {
        id: hero

        Column {
            spacing: -10

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Weather.glyph
                color: Weather.tint
                font.family: face.mono
                font.pixelSize: 92
                Behavior on color { ColorAnimation { duration: Colors.morph } }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Weather.ready ? Math.round(Weather.temp) + "°" : "··"
                color: Colors.fg
                opacity: 0.94
                font.family: face.mono
                font.pixelSize: 76
                font.weight: Font.Thin
                font.letterSpacing: -2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Weather.text
                color: Colors.fgDim
                opacity: 0.7
                font.family: face.mono
                font.pixelSize: 12
                font.letterSpacing: 2
            }
        }
    }

    Component {
        id: compact

        Row {
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.glyph
                color: Weather.tint
                font.family: face.mono
                font.pixelSize: 40
                Behavior on color { ColorAnimation { duration: Colors.morph } }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.ready ? Math.round(Weather.temp) + "°" : "··"
                color: Colors.fg
                font.family: face.mono
                font.pixelSize: 44
                font.weight: Font.Light
            }
        }
    }

    Component {
        id: full

        Rectangle {
            implicitWidth: 250
            implicitHeight: column.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: column
                anchors.centerIn: parent
                width: parent.width - 36
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 14

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Weather.glyph
                        color: Weather.tint
                        font.family: face.mono
                        font.pixelSize: 44
                        Behavior on color { ColorAnimation { duration: Colors.morph } }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: Weather.ready ? Math.round(Weather.temp) + "°" : "··°"
                            color: Colors.fg
                            font.family: face.mono
                            font.pixelSize: 34
                            font.weight: Font.Light
                        }

                        Text {
                            text: Weather.city !== "" ? Weather.city.toLowerCase() : "…"
                            color: Colors.fgDim
                            opacity: 0.7
                            font.family: face.mono
                            font.pixelSize: 11
                            font.letterSpacing: 2
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: Weather.error !== "" ? Weather.error : Weather.text.toLowerCase()
                    color: Weather.error !== "" ? Colors.bad : Colors.fgDim
                    opacity: 0.8
                    elide: Text.ElideRight
                    font.family: face.mono
                    font.pixelSize: 12
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.16)
                }

                Row {
                    width: parent.width
                    spacing: 0
                    visible: Weather.forecast.length > 0

                    Repeater {
                        model: Weather.forecast

                        Column {
                            required property var modelData
                            required property int index

                            width: column.width / Math.max(1, Weather.forecast.length)
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(new Date(modelData.date), "ddd").toLowerCase()
                                color: Colors.fgDim
                                opacity: index === 0 ? 0.9 : 0.55
                                font.family: face.mono
                                font.pixelSize: 10
                                font.letterSpacing: 1
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.max + "°"
                                color: index === 0 ? Colors.accent : Colors.fg
                                opacity: index === 0 ? 1 : 0.75
                                font.family: face.mono
                                font.pixelSize: 14
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.min + "°"
                                color: Colors.fgDim
                                opacity: 0.45
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
