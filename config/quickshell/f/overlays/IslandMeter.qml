import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/services"

Item {
    id: meter

    property real value: 0
    property color tint: Colors.accent
    property real live: -1
    property bool active: true

    implicitWidth: 64
    implicitHeight: 8

    property real shown: 0
    Component.onCompleted: meter.shown = Math.max(0, Math.min(1, meter.value))
    onValueChanged: meter.shown = Math.max(0, Math.min(1, meter.value))
    Behavior on shown {
        SpringAnimation { spring: 4.0; damping: 0.36; mass: 0.7; epsilon: 0.0008 }
    }

    property real puff: 0
    function kick() { puffRun.restart(); }
    SequentialAnimation {
        id: puffRun
        NumberAnimation { target: meter; property: "puff"; to: 1; duration: 90; easing.type: Easing.OutCubic }
        NumberAnimation { target: meter; property: "puff"; to: 0; duration: 420; easing.type: Easing.OutBack; easing.overshoot: 1.8 }
    }

    readonly property real thick: Math.round(meter.height * (0.62 + 0.38 * meter.puff) * 2) / 2

    Item {
        id: bar
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: meter.thick

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Colors.alpha(Colors.fg, 0.16)
        }

        RectangularShadow {
            anchors.fill: fill
            radius: fill.radius
            blur: 6 + 6 * meter.puff
            color: Colors.alpha(meter.tint, 0.55 + 0.3 * meter.puff)
            visible: meter.shown > 0.01
        }

        Rectangle {
            id: fill
            width: Math.max(bar.height, bar.width * meter.shown)
            height: bar.height
            radius: height / 2
            antialiasing: true
            visible: meter.shown > 0.005
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.darker(meter.tint, 1.15) }
                GradientStop { position: 1.0; color: Qt.lighter(meter.tint, 1.35) }
            }
        }

        Rectangle {
            visible: meter.live >= 0
            width: fill.width * Math.max(0, Math.min(1, meter.live))
            height: bar.height
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.55)
        }

        Rectangle {
            width: bar.height + 2
            height: width
            radius: width / 2
            anchors.verticalCenter: parent.verticalCenter
            x: fill.width - width + 1
            visible: meter.shown > 0.02
            color: Qt.lighter(meter.tint, 1.8)
            opacity: 0.85
        }
    }
}
