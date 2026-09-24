import QtQuick
import QtQuick.Effects
import "root:/design"

Item {
    id: tile

    property string glyph: ""
    property color tint: Colors.accent
    property real size: 46
    property bool round: false
    property bool sonar: false
    property bool implode: false
    property bool sparks: false
    property real glyphScale: 0.46
    property color ink: "white"
    property bool drift: true

    width: tile.size
    height: tile.size

    readonly property real rad: tile.round ? tile.size / 2 : tile.size * 0.28

    Repeater {
        model: tile.sonar || tile.implode ? 3 : 0

        Rectangle {
            id: wave
            required property int index

            anchors.centerIn: face
            width: tile.size
            height: tile.size
            radius: tile.rad
            color: "transparent"
            border.width: 1.6
            border.color: tile.tint
            antialiasing: true
            opacity: 0

            SequentialAnimation {
                running: true
                loops: Animation.Infinite
                PauseAnimation { duration: wave.index * 520 }
                ParallelAnimation {
                    NumberAnimation {
                        target: wave; property: "scale"
                        from: tile.implode ? 2.0 : 1.0
                        to: tile.implode ? 1.0 : 2.1
                        duration: 1560
                        easing.type: tile.implode ? Easing.InCubic : Easing.OutCubic
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: wave; property: "opacity"
                            from: 0; to: tile.implode ? 0.15 : 0.6
                            duration: tile.implode ? 900 : 180
                        }
                        NumberAnimation {
                            target: wave; property: "opacity"
                            to: 0; duration: tile.implode ? 660 : 1380
                            easing.type: Easing.InCubic
                        }
                    }
                }
                PauseAnimation { duration: (2 - wave.index) * 520 }
            }
        }
    }

    RectangularShadow {
        anchors.fill: face
        radius: tile.rad
        blur: tile.size * 0.42
        spread: 0
        offset.y: tile.size * 0.08
        color: Colors.alpha(tile.tint, 0.55)
        scale: face.scale
        opacity: face.opacity
    }

    Rectangle {
        id: face

        anchors.fill: parent
        radius: tile.rad
        antialiasing: true
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(tile.tint, 1.22) }
            GradientStop { position: 1.0; color: Qt.darker(tile.tint, 1.55) }
        }

        scale: 0.3
        rotation: -14
        opacity: 0
        Component.onCompleted: {
            face.scale = 1;
            face.rotation = 0;
            face.opacity = 1;
        }
        Behavior on scale {
            SpringAnimation { spring: 4.2; damping: 0.28; mass: 0.7; epsilon: 0.002 }
        }
        Behavior on rotation {
            SpringAnimation { spring: 3.4; damping: 0.3; mass: 0.8; epsilon: 0.05 }
        }
        Behavior on opacity { NumberAnimation { duration: 160 } }

        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: 1
            height: parent.height * 0.52
            radius: tile.rad - 1
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.34) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: tile.rad
            color: "transparent"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.22)
            antialiasing: true
        }

        Text {
            id: sign
            anchors.centerIn: parent
            text: tile.glyph
            color: tile.ink
            font.family: Fonts.glyph
            font.pixelSize: Math.round(tile.size * tile.glyphScale)

            Behavior on text {
                SequentialAnimation {
                    NumberAnimation { target: sign; property: "scale"; to: 0.3; duration: 110 }
                    PropertyAction {}
                    NumberAnimation {
                        target: sign; property: "scale"; to: 1; duration: 320
                        easing.type: Easing.OutBack; easing.overshoot: 2.4
                    }
                }
            }
        }

        transform: Translate {
            id: bob
            y: 0
            SequentialAnimation on y {
                running: tile.drift
                loops: Animation.Infinite
                NumberAnimation { to: -1.6; duration: 1400; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0.6;  duration: 1400; easing.type: Easing.InOutSine }
            }
        }
    }

    IslandBurst {
        anchors.centerIn: face
        visible: tile.sparks
        tint: Qt.lighter(tile.tint, 1.15)
        reach: tile.size * 0.95
    }
}
