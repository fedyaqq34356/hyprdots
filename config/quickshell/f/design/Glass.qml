import QtQuick
import QtQuick.Effects

Item {
    id: glass

    default property alias content: inner.data

    property real radius: 18
    property int elevation: 1
    property color tint: Colors.bg
    property real tintOpacity: 0.72
    property color edge: Colors.outline
    property bool specular: true
    property bool grain: true
    property real grainOpacity: 0.035

    readonly property real shadowBlur: [0, 0.45, 0.65, 0.85][Math.max(0, Math.min(3, elevation))]
    readonly property real shadowAlpha: [0, 0.28, 0.40, 0.52][Math.max(0, Math.min(3, elevation))]
    readonly property int shadowDrop: [0, 3, 6, 10][Math.max(0, Math.min(3, elevation))]

    HoverHandler {
        id: pointer
        enabled: glass.specular
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: glass.radius
        color: Qt.rgba(glass.tint.r, glass.tint.g, glass.tint.b, glass.tintOpacity)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: Motion.slow } }

        layer.enabled: glass.elevation > 0
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, glass.shadowAlpha)
            shadowBlur: glass.shadowBlur
            shadowVerticalOffset: glass.shadowDrop
        }
    }

    Rectangle {
        anchors.fill: body
        radius: glass.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.07) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.012) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.10) }
        }
    }

    Item {
        anchors.fill: body
        clip: true
        visible: glass.specular

        Canvas {
            id: blob
            width: Math.max(glass.width, glass.height) * 0.9
            height: width
            opacity: pointer.hovered ? 1 : 0

            x: (pointer.hovered ? pointer.point.position.x : glass.width / 2) - width / 2
            y: (pointer.hovered ? pointer.point.position.y : glass.height / 2) - height / 2

            Behavior on opacity { NumberAnimation { duration: Motion.slow } }
            Behavior on x { NumberAnimation { duration: Motion.base; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: Motion.base; easing.type: Easing.OutQuad } }

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const r = width / 2;
                const g = ctx.createRadialGradient(r, r, r * 0.05, r, r, r);
                g.addColorStop(0.0, Qt.rgba(1, 1, 1, 0.075));
                g.addColorStop(0.45, Qt.rgba(1, 1, 1, 0.030));
                g.addColorStop(1.0, Qt.rgba(1, 1, 1, 0.0));
                ctx.fillStyle = g;
                ctx.fillRect(0, 0, width, height);
            }
        }
    }

    Grain {
        anchors.fill: body
        visible: glass.grain
        amount: glass.grainOpacity
    }

    Rectangle {
        anchors.top: body.top
        anchors.topMargin: 1
        anchors.horizontalCenter: body.horizontalCenter
        width: body.width - glass.radius * 1.6
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.22) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors.fill: body
        radius: glass.radius
        color: "transparent"
        antialiasing: true
        border.width: 1
        border.color: Qt.rgba(glass.edge.r, glass.edge.g, glass.edge.b,
                              pointer.hovered ? 0.30 : 0.16)
        Behavior on border.color { ColorAnimation { duration: Motion.base } }
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
