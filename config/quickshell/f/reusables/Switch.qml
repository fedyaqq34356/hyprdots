import QtQuick
import QtQuick.Effects
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

    color: Prefs.apple
        ? (control.checked ? Colors.good : Colors.alpha(Colors.fg, 0.16))
        : control.checked
            ? Qt.rgba(control.tint.r, control.tint.g, control.tint.b, 0.85)
            : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.8)
    Behavior on color { ColorAnimation { duration: Motion.base } }

    scale: Prefs.apple ? 1 : tap.pressed ? 0.94 : (hover.hovered ? 1.04 : 1)
    Behavior on scale { Spring {} }

    HoverHandler { id: hover; enabled: control.enabled }

    Rectangle {
        id: handle

        readonly property int inset: Prefs.apple ? 2 : 3
        height: parent.height - handle.inset * 2
        width: Prefs.apple && tap.pressed ? handle.height + 7 : handle.height
        radius: height / 2
        anchors.verticalCenter: parent.verticalCenter
        x: control.checked ? parent.width - width - handle.inset : handle.inset
        color: Prefs.apple ? "white" : control.checked ? Colors.accentText : Colors.fgDim
        Behavior on width { NumberAnimation { duration: Motion.fast; easing.type: Easing.OutCubic } }

        RectangularShadow {
            z: -1
            anchors.fill: parent
            visible: Prefs.apple
            radius: parent.radius
            blur: 5
            offset.y: 1.5
            color: Qt.rgba(0, 0, 0, 0.35)
        }

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
