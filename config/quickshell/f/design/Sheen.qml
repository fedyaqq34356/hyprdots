import QtQuick
import "root:/design"

Item {
    id: sheen

    property real radius: 24
    property color edge: Colors.outline
    property real edgeOpacity: 0.18
    property bool border: true
    property bool grain: true
    property real grainOpacity: 0.03
    property bool depth: true
    property bool bevel: true
    property real strength: 1.0

    z: 5

    Rectangle {
        anchors.fill: parent
        visible: sheen.depth
        radius: sheen.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Colors.light(0.070 * sheen.strength) }
            GradientStop { position: 0.40; color: Colors.light(0.012 * sheen.strength) }
            GradientStop { position: 0.72; color: Colors.shadow(0.030 * sheen.strength) }
            GradientStop { position: 1.0; color: Colors.shadow(0.110 * sheen.strength) }
        }
    }

    Grain {
        anchors.fill: parent
        visible: sheen.grain
        amount: sheen.grainOpacity
    }

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        visible: sheen.bevel
        width: Math.max(0, parent.width - sheen.radius * 1.6)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Colors.light(0.24 * sheen.strength) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 1
        anchors.horizontalCenter: parent.horizontalCenter
        visible: sheen.bevel
        width: Math.max(0, parent.width - sheen.radius * 1.6)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Colors.shadow(0.30 * sheen.strength) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: sheen.border
        radius: sheen.radius
        color: "transparent"
        antialiasing: true
        border.width: 1
        border.color: Colors.alpha(sheen.edge, sheen.edgeOpacity)
        Behavior on border.color { ColorAnimation { duration: Motion.base } }
    }
}
