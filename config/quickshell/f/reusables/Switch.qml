import QtQuick
import "root:/design"
import "root:/services"

Rectangle {
    id: control

    property bool checked: false
    property bool enabled: true
    property color tint: Colors.accent

    signal toggled(bool value)

    width: 46
    height: 26
    radius: height / 2
    antialiasing: true

    opacity: control.enabled ? 1 : 0.4
    Behavior on opacity { NumberAnimation { duration: Motion.fast } }

    color: control.checked
        ? Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.85)
        : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.8)
    Behavior on color { ColorAnimation { duration: Motion.base } }

    scale: tap.pressed ? 0.94 : (hover.hovered ? 1.04 : 1)
    Behavior on scale { Spring {} }

    HoverHandler { id: hover; enabled: control.enabled }

    Rectangle {
        id: handle

        width: parent.height - 6
        height: width
        radius: width / 2
        anchors.verticalCenter: parent.verticalCenter
        x: control.checked ? parent.width - width - 3 : 3
        color: control.checked ? Colors.accentText : Colors.fgDim

        Behavior on x {
            NumberAnimation {
                duration: Motion.base
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.snap
            }
        }
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    TapHandler {
        id: tap
        enabled: control.enabled
        onTapped: {
            control.checked = !control.checked;
            Sfx.flip(control.checked);
            control.toggled(control.checked);
        }
    }
}
