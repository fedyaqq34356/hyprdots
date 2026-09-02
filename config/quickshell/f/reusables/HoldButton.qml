import QtQuick
import "root:/design"
import "root:/services"

Rectangle {
    id: control

    property string glyph: ""
    property string tip: ""
    property color tint: Colors.bad
    property int holdTime: 850
    property string mono: "JetBrainsMono Nerd Font"

    signal confirmed()

    readonly property real progress: charge.progress
    readonly property bool holding: press.pressed

    width: 36
    height: 36
    radius: 13
    antialiasing: true

    color: control.holding
        ? Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.28)
        : hover.hovered
            ? Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.18)
            : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.6)
    Behavior on color { ColorAnimation { duration: Motion.fast } }

    border.width: 1
    border.color: Qt.rgba(control.tint.r, control.tint.g, control.tint.b,
                          control.holding ? 0.5 : 0.16)

    scale: control.holding ? 0.94 : (hover.hovered ? 1.05 : 1)
    Behavior on scale { Spring {} }

    HoverHandler { id: hover }

    QtObject {
        id: charge
        property real progress: 0
        property int handle: -1
    }

    NumberAnimation {
        id: fill
        target: charge
        property: "progress"
        to: 1
        duration: control.holdTime
        easing.type: Easing.Linear
        onFinished: {
            Sfx.stop(charge.handle);
            charge.handle = -1;
            Sfx.tapAlt();
            control.confirmed();
            release.restart();
        }
    }

    NumberAnimation {
        id: release
        target: charge
        property: "progress"
        to: 0
        duration: Motion.base
        easing.type: Easing.OutCubic
    }

    Canvas {
        anchors.fill: parent
        anchors.margins: 1
        antialiasing: true

        readonly property real p: charge.progress
        onPChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (charge.progress <= 0)
                return;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.strokeStyle = control.tint;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, width / 2 - 2, -Math.PI / 2,
                    -Math.PI / 2 + Math.PI * 2 * charge.progress);
            ctx.stroke();
        }
    }

    Text {
        anchors.centerIn: parent
        text: control.glyph
        color: control.holding || hover.hovered ? control.tint : Colors.fgDim
        font.family: control.mono
        font.pixelSize: 14
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    TapHandler {
        id: press
        onPressedChanged: {
            if (press.pressed) {
                release.stop();
                charge.handle = Sfx.loop(
                    Sfx.serp + "reusables/fillbutton/charge_loop.wav", 0.4);
                fill.restart();
            } else if (fill.running) {
                fill.stop();
                Sfx.stop(charge.handle);
                charge.handle = -1;
                Sfx.toggleOff();
                release.restart();
            }
        }
    }

    Rectangle {
        id: tipBox

        readonly property bool active: hover.hovered && control.tip !== ""

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

        visible: opacity > 0.01
        opacity: tipBox.active ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }

        Text {
            id: tipText
            anchors.centerIn: parent
            text: control.holding ? "…" : control.tip
            color: Colors.fgDim
            font.family: control.mono
            font.pixelSize: 10
        }
    }
}
