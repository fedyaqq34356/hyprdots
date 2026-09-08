import QtQuick
import QtQuick.Effects
import "root:/design"

Item {
    id: bloom

    property Item target: null

    property color tint: Colors.accentGlow
    property color tintAlt: bloom.tint === Colors.accentGlow ? Colors.accentAlt : bloom.tint
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
        id: halo
        anchors.fill: parent
        radius: bloom.radius
        color: "transparent"
        opacity: bloom.amount

        gradient: Gradient {
            GradientStop { position: 0.0; color: bloom.tint }
            GradientStop { position: 1.0; color: bloom.tintAlt }
        }

        Behavior on opacity { NumberAnimation { duration: Motion.slow } }

        layer.enabled: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blur: 1.0
            blurMax: bloom.blurMax
        }
    }
}
