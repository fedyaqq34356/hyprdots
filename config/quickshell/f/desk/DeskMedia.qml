import Quickshell
import Quickshell.Widgets
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "cover"

    readonly property bool bare: face.variant === "round"
                              || face.variant === "wave"
                              || face.variant === "line"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    opacity: Media.has ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    Loader {
        id: loader
        sourceComponent: face.variant === "round" ? round
                       : face.variant === "wave" ? wave
                       : face.variant === "line" ? line
                       : cover
    }

    Component {
        id: cover

        Rectangle {
            implicitWidth: 300
            implicitHeight: 108
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Row {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 14

                ClippingRectangle {
                    width: 80
                    height: 80
                    radius: Shape.field
                    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.7)
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        visible: Media.art !== "" && status === Image.Ready
                        asynchronous: true
                        sourceSize.width: 240
                        cache: false
                    }

                    Vinyl {
                        anchors.centerIn: parent
                        width: parent.width
                        height: width
                        visible: Media.art === ""
                        spinning: Media.playing
                        grooves: 6
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 94
                    spacing: 6

                    Marquee {
                        width: parent.width
                        height: 20
                        text: Media.title
                        color: Colors.fg
                        family: face.mono
                        pixelSize: 15
                    }

                    Text {
                        width: parent.width
                        text: Media.artist
                        color: Colors.fgDim
                        opacity: 0.75
                        elide: Text.ElideRight
                        font.family: face.mono
                        font.pixelSize: 12
                    }

                    Rectangle {
                        width: parent.width
                        height: 3
                        radius: 2
                        color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.22)
                        visible: Media.hasPosition

                        Rectangle {
                            width: parent.width * Math.max(0, Math.min(1, Media.progress))
                            height: parent.height
                            radius: parent.radius
                            color: Colors.accent
                            Behavior on width { NumberAnimation { duration: Motion.base } }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: round

        Item {
            implicitWidth: 168
            implicitHeight: 168

            BeatRing {
                anchors.fill: parent
                progress: Media.progress
                showProgress: Media.hasPosition
            }

            Vinyl {
                anchors.centerIn: parent
                width: parent.width - 26
                height: width
                art: Media.art
                spinning: Media.playing
                scale: (Media.playing ? 1 : 0.965) + Beat.bass * 0.05
            }
        }
    }

    Component {
        id: wave

        Item {
            implicitWidth: 240
            implicitHeight: 240

            Spectrum {
                anchors.fill: parent
                mode: "radial"
                tint: Colors.accent
                hole: 0.62
                resolution: 56
                opacity: Media.playing ? 1 : 0.25
                Behavior on opacity { NumberAnimation { duration: Motion.slow } }
            }

            BeatRing {
                anchors.centerIn: parent
                width: parent.width * 0.6
                height: width
                progress: Media.progress
                showProgress: Media.hasPosition
                thickness: 2
            }

            Vinyl {
                anchors.centerIn: parent
                width: parent.width * 0.52
                height: width
                art: Media.art
                spinning: Media.playing
                grooves: 7
                scale: (Media.playing ? 1 : 0.965) + Beat.bass * 0.05
            }
        }
    }

    Component {
        id: line

        Item {
            implicitWidth: 320
            implicitHeight: stack.implicitHeight

            Column {
                id: stack

                width: parent.width
                spacing: 8

            Row {
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.playing ? "󰐊" : "󰏤"
                    color: Colors.accent
                    opacity: 0.8
                    font.family: face.mono
                    font.pixelSize: 14
                }

                Marquee {
                    width: 290
                    height: 24
                    text: Media.title + (Media.artist !== "" ? "  ·  " + Media.artist : "")
                    color: Colors.fg
                    family: face.mono
                    pixelSize: 16
                }
            }

                Spectrum {
                    width: stack.width
                    height: 26
                    mode: "wave"
                    mirror: true
                    tint: Colors.accent
                    opacity: Media.playing ? 0.9 : 0.2
                    Behavior on opacity { NumberAnimation { duration: Motion.slow } }
                }
            }
        }
    }
}
