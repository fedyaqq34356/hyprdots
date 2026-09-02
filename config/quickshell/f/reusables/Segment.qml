import QtQuick
import "root:/design"
import "root:/services"

Row {
    id: control

    property var options: []
    property string current: ""
    property color tint: Colors.accent
    property string mono: "JetBrainsMono Nerd Font"
    property bool auto: true

    signal picked(string value)

    spacing: 6

    Repeater {
        model: control.options

        Rectangle {
            id: pill

            required property var modelData

            readonly property bool active: control.current === modelData.value

            width: label.implicitWidth + 22
            height: 26
            radius: Shape.chip
            antialiasing: true

            color: pill.active
                ? Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.2)
                : hover.hovered
                    ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.75)
                    : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.5)
            Behavior on color { ColorAnimation { duration: Motion.fast } }

            border.width: 1
            border.color: pill.active
                ? Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.5)
                : "transparent"
            Behavior on border.color { ColorAnimation { duration: Motion.fast } }

            scale: tap.pressed ? 0.95 : 1
            Behavior on scale { Spring {} }

            HoverHandler { id: hover }

            Text {
                id: label
                anchors.centerIn: parent
                text: pill.modelData.label
                color: pill.active ? control.tint : Colors.fgDim
                font.family: control.mono
                font.pixelSize: 10
                Behavior on color { ColorAnimation { duration: Motion.fast } }
            }

            TapHandler {
                id: tap
                onTapped: {
                    Sfx.pick();
                    if (control.auto)
                        control.current = pill.modelData.value;
                    control.picked(pill.modelData.value);
                }
            }
        }
    }
}
