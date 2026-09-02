import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/services"

Rectangle {
    id: button

    property string glyph: ""
    property color tint: "#ffffff"
    property string mono: "JetBrainsMono Nerd Font"
    property string tip: ""
    property bool spinning: false

    signal activated()

    width: 36
    height: 36
    radius: Shape.chip
    antialiasing: true

    color: hover.hovered ? Qt.rgba(button.tint.r, button.tint.g, button.tint.b, 0.22)
                         : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.6)
    Behavior on color { ColorAnimation { duration: Motion.fast } }

    border.width: 1
    border.color: hover.hovered
        ? Qt.rgba(button.tint.r, button.tint.g, button.tint.b, 0.4)
        : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.16)
    Behavior on border.color { ColorAnimation { duration: Motion.fast } }

    scale: tap.pressed ? 0.90 : (hover.hovered ? 1.06 : 1)
    Behavior on scale { Spring {} }

    HoverHandler { id: hover }
    TapHandler {
        id: tap
        onTapped: (point) => {
            ripple.x = point.position.x;
            ripple.y = point.position.y;
            rippleAnim.restart();
            Sfx.icon();
            button.activated();
        }
    }

    Rectangle {
        z: -1
        anchors.centerIn: parent
        width: parent.width + 14
        height: parent.height + 14
        radius: parent.radius + 7
        color: Qt.rgba(button.tint.r, button.tint.g, button.tint.b, 0.55)
        opacity: hover.hovered ? (tap.pressed ? 0.55 : 0.32) : 0
        Behavior on opacity { NumberAnimation { duration: Motion.base } }

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: 32
        }
    }

    Rectangle {
        id: rippleMask
        anchors.fill: parent
        radius: button.radius
        color: "black"
        visible: false
        layer.enabled: true
    }

    Item {
        anchors.fill: parent

        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: rippleMask
        }

        Rectangle {
            id: ripple
            width: 0
            height: 0
            radius: width / 2
            color: Qt.rgba(button.tint.r, button.tint.g, button.tint.b, 0.45)
            opacity: 0
            transform: Translate { x: -ripple.width / 2; y: -ripple.height / 2 }

            ParallelAnimation {
                id: rippleAnim

                NumberAnimation {
                    target: ripple
                    properties: "width,height"
                    from: 0
                    to: button.width * 2.2
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.decel
                }
                SequentialAnimation {
                    NumberAnimation {
                        target: ripple; property: "opacity"
                        from: 0; to: 1; duration: Motion.instant
                    }
                    NumberAnimation {
                        target: ripple; property: "opacity"
                        to: 0; duration: Motion.slow
                    }
                }
            }
        }
    }

    Text {
        anchors.centerIn: parent
        text: button.glyph
        color: hover.hovered ? button.tint : Colors.fgDim
        opacity: hover.hovered ? 1 : 0.7
        font.family: button.mono
        font.pixelSize: 14

        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }

        RotationAnimation on rotation {
            running: button.spinning
            loops: Animation.Infinite
            from: 0; to: 360; duration: 1100
        }
    }

    Rectangle {
        id: tipBox

        readonly property bool active: hover.hovered && button.tip !== ""

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 6
        width: tipText.implicitWidth + 16
        height: 22
        radius: 8
        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
        border.width: 1
        border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)
        z: 10
        antialiasing: true

        visible: opacity > 0.01
        opacity: active ? 1 : 0
        scale: active ? 1 : 0.88
        transformOrigin: Item.Top

        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.base
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.snap
            }
        }

        Text {
            id: tipText
            anchors.centerIn: parent
            text: button.tip
            color: Colors.fgDim
            font.family: button.mono
            font.pixelSize: 10
        }
    }
}
