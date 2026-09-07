import QtQuick
import QtQuick.Effects
import "root:/design"

Item {
    id: bloom

    property Item target: null

    property color tint: Colors.accent
    property real amount: 0.22
    property real radius: Shape.modal
    property real inset: 40
    property int blurMax: 56

    z: -2
    anchors.centerIn: bloom.target
    width: bloom.target ? Math.max(0, bloom.target.width - bloom.inset) : 0
    height: bloom.target ? Math.max(0, bloom.target.height - bloom.inset) : 0

    visible: bloom.amount > 0.001

    Rectangle {
        anchors.fill: parent
        radius: bloom.radius
        color: bloom.tint
        opacity: bloom.amount

        Behavior on color { ColorAnimation { duration: Motion.slow } }
        Behavior on opacity { NumberAnimation { duration: Motion.slow } }

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: bloom.blurMax
        }
    }
}
