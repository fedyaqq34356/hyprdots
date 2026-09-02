import QtQuick
import "root:/design"
import "root:/services"

Rectangle {
    id: control

    property real value: 0
    property real step: 0.05
    property color tint: Colors.accent
    property bool silent: false

    signal moved(real value)
    signal released()

    readonly property bool dragging: area.pressed

    height: 6
    radius: height / 2
    color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)

    Rectangle {
        width: parent.width * Math.max(0, Math.min(1, control.value))
        height: parent.height
        radius: parent.radius
        color: control.tint

        Behavior on width {
            enabled: !control.dragging
            NumberAnimation { duration: Motion.fast }
        }
    }

    Rectangle {
        id: knob

        width: 14
        height: 14
        radius: 7
        anchors.verticalCenter: parent.verticalCenter
        x: parent.width * Math.max(0, Math.min(1, control.value)) - width / 2
        color: control.tint
        opacity: hover.hovered || control.dragging ? 1 : 0
        scale: control.dragging ? 1.15 : 1

        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        Behavior on scale { Spring {} }
        Behavior on x {
            enabled: !control.dragging
            NumberAnimation { duration: Motion.fast }
        }
    }

    HoverHandler { id: hover }

    MouseArea {
        id: area

        anchors.fill: parent
        anchors.margins: -10

        function apply(mouse) {
            const raw = Math.max(0, Math.min(1, mouse.x / control.width));
            const snapped = Math.round(raw / control.step) * control.step;
            if (Math.abs(snapped - control.value) < control.step / 2)
                return;
            control.value = snapped;
            if (!control.silent)
                Sfx.tick();
            control.moved(snapped);
        }

        onPressed: (mouse) => area.apply(mouse)
        onPositionChanged: (mouse) => {
            if (area.pressed)
                area.apply(mouse);
        }
        onReleased: {
            if (!control.silent)
                Sfx.tap();
            control.released();
        }
    }
}
