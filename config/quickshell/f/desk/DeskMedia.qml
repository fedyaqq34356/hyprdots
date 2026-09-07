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
                              || face.variant === "pulse"
                              || face.variant === "stack"

    readonly property string mono: Fonts.mono

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
                       : face.variant === "poster" ? poster
                       : face.variant === "tile" ? tile
                       : face.variant === "stack" ? stacked
                       : face.variant === "pulse" ? pulse
                       : face.variant === "strip" ? strip
                       : face.variant === "frame" ? framed
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

    Component {
        id: poster

        ClippingRectangle {
            id: sleeve

            implicitWidth: 260
            implicitHeight: 260
            radius: Shape.card
            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.75)

            Image {
                anchors.fill: parent
                source: Media.art
                fillMode: Image.PreserveAspectCrop
                visible: Media.art !== "" && status === Image.Ready
                asynchronous: true
                sourceSize.width: 520
                cache: false
            }

            Vinyl {
                anchors.centerIn: parent
                width: parent.width * 0.7
                height: width
                visible: Media.art === ""
                spinning: Media.playing
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * 0.55
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.55
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.72) }
                    GradientStop { position: 1.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96) }
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 18
                spacing: 5

                Marquee {
                    width: parent.width
                    height: 22
                    text: Media.title
                    color: Colors.fg
                    family: face.mono
                    pixelSize: 17
                }

                Text {
                    width: parent.width
                    text: Media.artist
                    color: Colors.accent
                    opacity: 0.85
                    elide: Text.ElideRight
                    font.family: face.mono
                    font.pixelSize: 12
                }

                Rectangle {
                    width: parent.width
                    height: 3
                    radius: 2
                    visible: Media.hasPosition
                    color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.22)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, Media.progress))
                        height: parent.height
                        radius: parent.radius
                        color: Colors.accent
                        Behavior on width { NumberAnimation { duration: Motion.base } }
                    }
                }
            }

            Sheen {
                anchors.fill: parent
                radius: sleeve.radius
                edgeOpacity: 0.18
                grain: false
            }
        }
    }

    Component {
        id: tile

        Rectangle {
            implicitWidth: 380
            implicitHeight: 72
            radius: Shape.field + 6
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.14
            }

            Row {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 12

                ClippingRectangle {
                    width: 52
                    height: 52
                    radius: Shape.chip
                    anchors.verticalCenter: parent.verticalCenter
                    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.7)

                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        visible: Media.art !== "" && status === Image.Ready
                        asynchronous: true
                        sourceSize.width: 160
                        cache: false
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: Media.art === ""
                        text: "󰎈"
                        color: Colors.accent
                        font.family: face.mono
                        font.pixelSize: 20
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 52 - 84 - 24
                    spacing: 3

                    Marquee {
                        width: parent.width
                        height: 18
                        text: Media.title
                        color: Colors.fg
                        family: face.mono
                        pixelSize: 13
                    }

                    Text {
                        width: parent.width
                        text: Media.artist
                        color: Colors.fgDim
                        opacity: 0.7
                        elide: Text.ElideRight
                        font.family: face.mono
                        font.pixelSize: 11
                    }
                }

                Spectrum {
                    width: 84
                    height: 34
                    anchors.verticalCenter: parent.verticalCenter
                    mode: "bars"
                    resolution: 14
                    tint: Colors.accent
                    opacity: Media.playing ? 0.9 : 0.2
                    Behavior on opacity { NumberAnimation { duration: Motion.slow } }
                }
            }
        }
    }

    Component {
        id: stacked

        Item {
            implicitWidth: 220
            implicitHeight: column.implicitHeight

            Column {
                id: column

                width: parent.width
                spacing: 14

                ClippingRectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 200
                    height: 200
                    radius: Shape.card
                    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.6)

                    Image {
                        anchors.fill: parent
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        visible: Media.art !== "" && status === Image.Ready
                        asynchronous: true
                        sourceSize.width: 400
                        cache: false
                    }

                    Vinyl {
                        anchors.centerIn: parent
                        width: parent.width
                        height: width
                        visible: Media.art === ""
                        spinning: Media.playing
                    }

                    scale: (Media.playing ? 1 : 0.97) + Beat.bass * 0.03
                    Behavior on scale { NumberAnimation { duration: Motion.fast } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Media.title
                    color: Colors.fg
                    elide: Text.ElideRight
                    font.family: face.mono
                    font.pixelSize: 15
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Media.artist
                    color: Colors.accent
                    opacity: 0.8
                    elide: Text.ElideRight
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }

    Component {
        id: pulse

        Item {
            implicitWidth: 240
            implicitHeight: 260

            Item {
                id: halo
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                width: 180
                height: 180

                Repeater {
                    model: 3

                    Rectangle {
                        required property int index

                        anchors.centerIn: parent
                        width: parent.width * (0.55 + index * 0.2)
                        height: width
                        radius: width / 2
                        antialiasing: true
                        color: "transparent"
                        border.width: 3 - index
                        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                              Colors.accent.b,
                                              0.55 - index * 0.15)

                        scale: 1 + Beat.bass * (0.10 + index * 0.05)
                        Behavior on scale {
                            NumberAnimation { duration: Motion.fast }
                        }
                    }
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.36
                    height: width
                    radius: width / 2
                    antialiasing: true
                    color: Colors.accent
                    opacity: Media.playing ? 0.9 : 0.35
                    scale: 1 + Beat.level * 0.14
                    Behavior on scale { NumberAnimation { duration: Motion.fast } }
                    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

                    Text {
                        anchors.centerIn: parent
                        text: Media.playing ? "󰐊" : "󰏤"
                        color: Colors.accentText
                        font.family: face.mono
                        font.pixelSize: 22
                    }
                }
            }

            Column {
                anchors.top: halo.bottom
                anchors.topMargin: 16
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width
                spacing: 4

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Media.title
                    color: Colors.fg
                    elide: Text.ElideRight
                    font.family: face.mono
                    font.pixelSize: 14
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: Media.artist
                    color: Colors.fgDim
                    opacity: 0.7
                    elide: Text.ElideRight
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }

    Component {
        id: strip

        Item {
            implicitWidth: 460
            implicitHeight: 54

            Spectrum {
                anchors.fill: parent
                mode: "mirror"
                resolution: 64
                tint: Colors.accent
                opacity: Media.playing ? 0.35 : 0.12
                Behavior on opacity { NumberAnimation { duration: Motion.slow } }
            }

            Row {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.playing ? "󰝚" : "󰏤"
                    color: Colors.accent
                    font.family: face.mono
                    font.pixelSize: 15
                }

                Marquee {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 380
                    height: 26
                    text: Media.title
                        + (Media.artist !== "" ? "   ·   " + Media.artist : "")
                    color: Colors.fg
                    family: face.mono
                    pixelSize: 17
                }
            }
        }
    }

    Component {
        id: framed

        Rectangle {
            implicitWidth: 224
            implicitHeight: 268
            radius: 6
            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.90)

            ClippingRectangle {
                x: 14
                y: 14
                width: parent.width - 28
                height: parent.width - 28
                radius: 2
                color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.8)

                Image {
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    visible: Media.art !== "" && status === Image.Ready
                    asynchronous: true
                    sourceSize.width: 420
                    cache: false
                }

                Vinyl {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: width
                    visible: Media.art === ""
                    spinning: Media.playing
                    grooves: 8
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 14
                spacing: 2

                Text {
                    width: parent.width
                    text: Media.title
                    color: Colors.bg
                    elide: Text.ElideRight
                    font.family: Fonts.display
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: Media.artist
                    color: Colors.bg
                    opacity: 0.6
                    elide: Text.ElideRight
                    font.family: Fonts.display
                    font.pixelSize: 11
                }
            }
        }
    }
}
