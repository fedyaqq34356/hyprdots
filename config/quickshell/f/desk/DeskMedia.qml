import Quickshell
import Quickshell.Widgets
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "cover"
    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    opacity: Media.has ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    Loader {
        id: loader
        sourceComponent: face.variant === "round" ? round : cover
    }

    Component {
        id: cover

        Rectangle {
            implicitWidth: 300
            implicitHeight: 108
            radius: 22
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
                    radius: 16
                    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.7)
                    anchors.verticalCenter: parent.verticalCenter

                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        visible: Media.art !== "" && status === Image.Ready
                        asynchronous: true
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

            Canvas {
                id: arc
                anchors.fill: parent
                antialiasing: true

                readonly property real p: Math.max(0, Math.min(1, Media.progress))
                onPChanged: arc.requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    const r = width / 2 - 4;
                    ctx.lineWidth = 3;
                    ctx.lineCap = "round";

                    ctx.strokeStyle = Qt.rgba(Colors.outline.r, Colors.outline.g,
                                              Colors.outline.b, 0.2);
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, r, 0, Math.PI * 2);
                    ctx.stroke();

                    if (!Media.hasPosition)
                        return;
                    ctx.strokeStyle = Colors.accent;
                    ctx.beginPath();
                    ctx.arc(width / 2, height / 2, r,
                            -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * arc.p);
                    ctx.stroke();
                }
            }

            Vinyl {
                anchors.centerIn: parent
                width: parent.width - 26
                height: width
                art: Media.art
                spinning: Media.playing
            }
        }
    }
}
