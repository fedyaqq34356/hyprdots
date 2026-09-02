import QtQuick

Item {
    id: sheen

    property real radius: 24
    property color edge: Colors.outline
    property real edgeOpacity: 0.18
    property bool border: true
    property bool grain: true
    property real grainOpacity: 0.03
    property bool depth: true

    z: 5

    Rectangle {
        anchors.fill: parent
        visible: sheen.depth
        radius: sheen.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.06) }
            GradientStop { position: 0.4; color: Qt.rgba(1, 1, 1, 0.01) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.09) }
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
        width: Math.max(0, parent.width - sheen.radius * 1.6)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.20) }
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
        border.color: Qt.rgba(sheen.edge.r, sheen.edge.g, sheen.edge.b, sheen.edgeOpacity)
        Behavior on border.color { ColorAnimation { duration: Motion.base } }
    }
}
