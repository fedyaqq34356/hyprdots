import QtQuick
import Quickshell.Widgets
import "root:/design"

Item {
    id: bat

    property real value: 0.5
    property bool charging: false
    property color tint: Colors.good
    property string glyph: ""
    property real lowAt: 0.2

    readonly property bool low: !bat.charging && bat.value <= bat.lowAt
    readonly property color ink: bat.low ? Colors.bad : bat.tint

    implicitWidth: 64
    implicitHeight: 32

    property real shown: 0
    Component.onCompleted: bat.shown = Math.max(0, Math.min(1, bat.value))
    onValueChanged: bat.shown = Math.max(0, Math.min(1, bat.value))
    Behavior on shown { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }

    property real phase: 0
    NumberAnimation on phase {
        from: 0; to: Math.PI * 2
        duration: bat.charging ? 1100 : 3400
        loops: Animation.Infinite
        running: bat.visible
    }

    readonly property real cap: Math.max(3, bat.height * 0.1)
    readonly property real bodyW: bat.width - bat.cap - 2

    Rectangle {
        id: shell
        width: bat.bodyW
        height: bat.height
        radius: bat.height * 0.3
        color: Colors.alpha(Colors.fg, 0.06)
        border.width: 1.6
        border.color: Colors.alpha(Colors.fg, 0.32)
        antialiasing: true
    }

    Rectangle {
        x: bat.bodyW + 1.5
        anchors.verticalCenter: shell.verticalCenter
        width: bat.cap
        height: bat.height * 0.36
        radius: width / 2
        color: Colors.alpha(Colors.fg, 0.32)
        antialiasing: true
    }

    ClippingRectangle {
        id: well
        x: 3.5
        y: 3.5
        width: shell.width - 7
        height: shell.height - 7
        radius: shell.radius - 3
        color: "transparent"

        Water {
            id: liquid
            anchors.fill: parent
            visible: bat.shown * width > 0.5
            axis: 1
            level: width * bat.shown
            phase1: bat.phase; amp1: bat.charging ? 2.2 : 1.0; waves1: 1
            amp2: 0
            nearColor: Qt.lighter(bat.ink, 1.3); nearAlpha: 1
            farColor: Qt.darker(bat.ink, 1.35); farAlpha: 1
            crestColor: Qt.lighter(bat.ink, 1.6); crestAlpha: 0.6
            crestWidth: 1.2
        }

        Repeater {
            model: bat.charging ? 5 : 0

            Rectangle {
                id: bub
                required property int index
                readonly property real lane: (bub.index + 0.5) / 5

                width: 2.5 + (bub.index % 2)
                height: width
                radius: width / 2
                color: Qt.rgba(1, 1, 1, 0.55)
                x: Math.min(well.width * bat.shown - 4, well.width * bat.shown * bub.lane)
                y: well.height
                visible: bat.shown > 0.08

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    PauseAnimation { duration: bub.index * 230 }
                    NumberAnimation {
                        from: well.height; to: -4
                        duration: 900 + bub.index * 90
                        easing.type: Easing.InQuad
                    }
                }
            }
        }

        Rectangle {
            id: glint
            width: well.width * 0.35
            height: well.height * 3
            anchors.verticalCenter: parent.verticalCenter
            rotation: 20
            visible: bat.charging
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.32) }
                GradientStop { position: 1.0; color: "transparent" }
            }

            SequentialAnimation on x {
                running: bat.charging
                loops: Animation.Infinite
                NumberAnimation {
                    from: -glint.width; to: well.width + glint.width
                    duration: 1300; easing.type: Easing.InOutCubic
                }
                PauseAnimation { duration: 900 }
            }
        }
    }

    Text {
        id: sign
        anchors.centerIn: shell
        text: bat.charging ? "󱐋" : bat.glyph
        visible: text !== ""
        color: "white"
        style: Text.Outline
        styleColor: Colors.alpha(Qt.darker(bat.ink, 2.2), 0.6)
        font.family: Fonts.glyph
        font.pixelSize: Math.round(bat.height * 0.52)

        SequentialAnimation on scale {
            running: bat.charging
            loops: Animation.Infinite
            NumberAnimation { to: 1.18; duration: 520; easing.type: Easing.OutQuad }
            NumberAnimation { to: 1.0;  duration: 680; easing.type: Easing.InOutSine }
        }
    }

    SequentialAnimation on opacity {
        running: bat.low
        loops: Animation.Infinite
        alwaysRunToEnd: true
        NumberAnimation { to: 0.55; duration: 620; easing.type: Easing.InOutSine }
        NumberAnimation { to: 1.0;  duration: 620; easing.type: Easing.InOutSine }
    }
}
