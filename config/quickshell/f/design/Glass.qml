import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/services"

Item {
    id: glass

    default property alias content: inner.data

    property real radius: Shape.field
    property int elevation: 1
    property color tint: Colors.surfaceFor(glass.elevation)
    property real tintOpacity: 0.72
    property color edge: Colors.outline
    property bool specular: true
    property bool grain: true
    property real grainOpacity: 0.035

    readonly property real shadowBlur: [0, 0.55, 0.80, 1.00][Math.max(0, Math.min(3, elevation))]
    readonly property real shadowAlpha: [0, 0.22, 0.32, 0.42][Math.max(0, Math.min(3, elevation))]
    readonly property int shadowDrop: [0, 5, 10, 18][Math.max(0, Math.min(3, elevation))]

    readonly property int contactDrop: [0, 2, 3, 4][Math.max(0, Math.min(3, elevation))]
    readonly property real contactAlpha: [0, 0.30, 0.40, 0.50][Math.max(0, Math.min(3, elevation))]

    HoverHandler {
        id: pointer
        enabled: glass.specular
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: glass.contactDrop
        anchors.bottomMargin: -glass.contactDrop
        visible: glass.elevation > 0 && !Prefs.apple
        radius: glass.radius
        color: Colors.shadow(glass.contactAlpha)
        antialiasing: true
    }

    Rectangle {
        id: body
        anchors.fill: parent
        radius: glass.radius
        color: Prefs.apple ? Qt.rgba(0, 0, 0, 0.9)
                           : Colors.alpha(glass.tint, glass.tintOpacity)
        antialiasing: true

        Behavior on color { ColorAnimation { duration: Motion.slow } }

        layer.enabled: glass.elevation > 0
            && !(glass.parent && glass.parent.layer && glass.parent.layer.enabled)
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Prefs.apple ? Qt.rgba(0, 0, 0, 0.5) : Colors.shadow(glass.shadowAlpha)
            shadowBlur: Prefs.apple ? 1.0 : glass.shadowBlur
            shadowVerticalOffset: Prefs.apple ? glass.shadowDrop + 8 : glass.shadowDrop
        }
    }

    Rectangle {
        anchors.fill: body
        radius: glass.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Prefs.apple ? Qt.rgba(1, 1, 1, 0.045) : Colors.light(0.080) }
            GradientStop { position: 0.42; color: Prefs.apple ? Qt.rgba(1, 1, 1, 0.0) : Colors.light(0.014) }
            GradientStop { position: 0.75; color: Prefs.apple ? Qt.rgba(0, 0, 0, 0.0) : Colors.shadow(0.035) }
            GradientStop { position: 1.0; color: Prefs.apple ? Qt.rgba(0, 0, 0, 0.0) : Colors.shadow(0.120) }
        }
    }

    Item {
        id: blobHost

        anchors.fill: body
        clip: true
        property bool armed: false
        visible: glass.specular && armed && !Prefs.apple

        Connections {
            target: pointer
            enabled: glass.specular && !blobHost.armed
            function onHoveredChanged() {
                if (pointer.hovered)
                    blobHost.armed = true;
            }
        }

        Canvas {
            id: blob
            width: Math.max(glass.width, glass.height) * 0.9
            height: width
            opacity: pointer.hovered ? 1 : 0

            x: (pointer.hovered ? pointer.point.position.x : glass.width / 2) - width / 2
            y: (pointer.hovered ? pointer.point.position.y : glass.height / 2) - height / 2

            property color tone: Colors.lightTone
            onToneChanged: blob.requestPaint()

            Behavior on opacity { NumberAnimation { duration: Motion.slow } }
            Behavior on x { NumberAnimation { duration: Motion.base; easing.type: Easing.OutQuad } }
            Behavior on y { NumberAnimation { duration: Motion.base; easing.type: Easing.OutQuad } }

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                const r = width / 2;

                if (!isFinite(r) || r <= 0)
                    return;

                const g = ctx.createRadialGradient(r, r, r * 0.05, r, r, r);
                g.addColorStop(0.0, Colors.light(0.090));
                g.addColorStop(0.40, Colors.light(0.034));
                g.addColorStop(1.0, Colors.light(0.0));
                ctx.fillStyle = g;
                ctx.fillRect(0, 0, width, height);
            }
        }
    }

    Grain {
        anchors.fill: body
        visible: glass.grain && !Prefs.apple
        amount: glass.grainOpacity
    }

    Rectangle {
        anchors.top: body.top
        anchors.topMargin: 1
        anchors.horizontalCenter: body.horizontalCenter
        width: Math.max(0, body.width - glass.radius * 1.6)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Colors.light(0.26) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors.bottom: body.bottom
        anchors.bottomMargin: 1
        anchors.horizontalCenter: body.horizontalCenter
        width: Math.max(0, body.width - glass.radius * 1.6)
        height: 1
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Prefs.apple ? "transparent" : Colors.shadow(0.34) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Rectangle {
        anchors.fill: body
        radius: glass.radius
        color: "transparent"
        antialiasing: true
        border.width: 1
        border.color: Prefs.apple ? Qt.rgba(1, 1, 1, 0.07)
                                  : Colors.alpha(glass.edge, pointer.hovered ? 0.32 : 0.16)
        Behavior on border.color { ColorAnimation { duration: Motion.base } }
    }

    Rectangle {
        anchors.fill: body
        anchors.margins: -1
        visible: false
        radius: glass.radius + 1
        color: "transparent"
        antialiasing: true
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.45)
    }

    Item {
        id: inner
        anchors.fill: parent
    }
}
