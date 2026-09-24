import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/services"

Item {
    id: control

    property var options: []
    property string current: ""
    property color tint: Colors.accent
    property string mono: Fonts.mono
    property bool auto: true

    signal picked(string value)

    readonly property bool apple: Prefs.apple
    readonly property int pad: control.apple ? 2 : 0

    implicitWidth: row.implicitWidth + control.pad * 2
    implicitHeight: row.implicitHeight + control.pad * 2

    Rectangle {
        anchors.fill: parent
        visible: control.apple
        radius: 9
        antialiasing: true
        color: Colors.alpha(Colors.fg, 0.10)
    }

    readonly property Item picked_: {
        for (let i = 0; i < pills.count; i++) {
            const p = pills.itemAt(i);
            if (p && p.active)
                return p;
        }
        return null;
    }

    Rectangle {
        id: puck
        visible: control.apple && control.picked_ !== null
        x: control.picked_ ? row.x + control.picked_.x : 0
        y: row.y
        width: control.picked_ ? control.picked_.width : 0
        height: row.height
        radius: 7
        antialiasing: true
        color: Colors.alpha(Colors.fg, 0.26)

        Behavior on x { SpringAnimation { spring: 4.5; damping: 0.42; mass: 0.8; epsilon: 0.2 } }
        Behavior on width { SpringAnimation { spring: 4.5; damping: 0.42; mass: 0.8; epsilon: 0.2 } }

        RectangularShadow {
            z: -1
            anchors.fill: parent
            radius: parent.radius
            blur: 6
            offset.y: 1.5
            color: Qt.rgba(0, 0, 0, 0.3)
        }
    }

    Row {
        id: row
        x: control.pad
        y: control.pad
        spacing: control.apple ? 0 : 6

        Repeater {
            id: pills
            model: control.options

            Rectangle {
                id: pill

                required property var modelData

                readonly property bool active: control.current === modelData.value

                width: label.implicitWidth + 22
                height: control.apple ? 24 : 26
                radius: Shape.chip
                antialiasing: true

                color: control.apple
                    ? (hover.hovered && !pill.active ? Colors.alpha(Colors.fg, 0.05) : "transparent")
                    : pill.active
                        ? Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.2)
                        : hover.hovered
                            ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.75)
                            : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.5)
                Behavior on color { ColorAnimation { duration: Motion.fast } }

                border.width: control.apple ? 0 : 1
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
                    color: control.apple ? (pill.active ? Colors.fg : Colors.alpha(Colors.fg, 0.7))
                                         : pill.active ? control.tint : Colors.fgDim
                    font.family: control.mono
                    font.pixelSize: control.apple ? 11 : 10
                    font.weight: control.apple && pill.active ? Font.DemiBold : Font.Normal
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
}
