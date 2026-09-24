import QtQuick
import QtQuick.Shapes as Vec
import "root:/design"

Item {
    id: rim

    property real value: -1
    property bool busy: false

    property color tint: Colors.accent
    property real thickness: 2
    property real radius: 12
    property real trackAlpha: 0.12

    readonly property bool active: rim.busy || rim.value >= 0

    readonly property real inset: rim.thickness / 2 + 0.5
    readonly property real boxW: Math.max(0, rim.width - rim.inset * 2)
    readonly property real boxH: Math.max(0, rim.height - rim.inset * 2)
    readonly property real r: Math.max(
        0.01, Math.min(rim.radius - rim.inset,
                       Math.min(rim.boxW, rim.boxH) / 2))

    readonly property real straightX: Math.max(0, rim.boxW - rim.r * 2)
    readonly property real straightY: Math.max(0, rim.boxH - rim.r * 2)
    readonly property real perim:
        rim.straightX * 2 + rim.straightY * 2 + 2 * Math.PI * rim.r

    readonly property real span: rim.busy
        ? rim.perim * 0.22
        : rim.perim * Math.max(0, Math.min(1, rim.shown))

    property real shown: 0
    onValueChanged: if (rim.value >= 0) rim.shown = rim.value

    Behavior on shown {
        NumberAnimation {
            duration: Motion.isleContentMs
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.isleContent
        }
    }

    property bool alive: false
    onActiveChanged: {
        if (rim.active) {
            drop.stop();
            rim.alive = true;
        } else {
            drop.restart();
        }
    }
    Component.onCompleted: rim.alive = rim.active

    Timer {
        id: drop
        interval: Motion.isleHideMs + 120
        onTriggered: rim.alive = false
    }

    Loader {
        id: draw

        anchors.fill: parent
        active: rim.alive

        opacity: rim.active ? 1 : 0
        Behavior on opacity {
            NumberAnimation {
                duration: rim.active ? Motion.isleRevealMs : Motion.isleHideMs
            }
        }

        sourceComponent: Vec.Shape {

            asynchronous: false
            preferredRendererType: Vec.Shape.GeometryRenderer

            Vec.ShapePath {
                strokeColor: Colors.alpha(rim.tint, rim.trackAlpha)
                strokeWidth: rim.thickness
                fillColor: "transparent"
                capStyle: Vec.ShapePath.FlatCap
                joinStyle: Vec.ShapePath.RoundJoin

                startX: rim.inset
                startY: rim.height / 2

                PathLine { x: rim.inset; y: rim.inset + rim.r }
                PathArc {
                    x: rim.inset + rim.r; y: rim.inset
                    radiusX: rim.r; radiusY: rim.r
                    direction: PathArc.Clockwise
                }
                PathLine { x: rim.inset + rim.r + rim.straightX; y: rim.inset }
                PathArc {
                    x: rim.inset + rim.boxW; y: rim.inset + rim.r
                    radiusX: rim.r; radiusY: rim.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: rim.inset + rim.boxW
                    y: rim.inset + rim.r + rim.straightY
                }
                PathArc {
                    x: rim.inset + rim.boxW - rim.r; y: rim.inset + rim.boxH
                    radiusX: rim.r; radiusY: rim.r
                    direction: PathArc.Clockwise
                }
                PathLine { x: rim.inset + rim.r; y: rim.inset + rim.boxH }
                PathArc {
                    x: rim.inset; y: rim.inset + rim.boxH - rim.r
                    radiusX: rim.r; radiusY: rim.r
                    direction: PathArc.Clockwise
                }
                PathLine { x: rim.inset; y: rim.height / 2 }
            }

            Vec.ShapePath {
                id: arc

                strokeColor: rim.tint
                strokeWidth: rim.thickness
                fillColor: "transparent"
                capStyle: Vec.ShapePath.RoundCap
                joinStyle: Vec.ShapePath.RoundJoin

                strokeStyle: Vec.ShapePath.DashLine
                dashPattern: [
                    Math.max(0.001, rim.span / rim.thickness),
                    Math.max(0.001, (rim.perim - rim.span) / rim.thickness)
                ]

                property real runner: 0
                dashOffset: -arc.runner / rim.thickness

                NumberAnimation on runner {
                    running: rim.busy && draw.active
                    loops: Animation.Infinite
                    from: 0
                    to: rim.perim
                    duration: 1700
                }

                startX: rim.inset
                startY: rim.height / 2

                PathLine { x: rim.inset; y: rim.inset + rim.r }
                PathArc {
                    x: rim.inset + rim.r; y: rim.inset
                    radiusX: rim.r; radiusY: rim.r
                    direction: PathArc.Clockwise
                }
                PathLine { x: rim.inset + rim.r + rim.straightX; y: rim.inset }
                PathArc {
                    x: rim.inset + rim.boxW; y: rim.inset + rim.r
                    radiusX: rim.r; radiusY: rim.r
                    direction: PathArc.Clockwise
                }
                PathLine {
                    x: rim.inset + rim.boxW
                    y: rim.inset + rim.r + rim.straightY
                }
                PathArc {
                    x: rim.inset + rim.boxW - rim.r; y: rim.inset + rim.boxH
                    radiusX: rim.r; radiusY: rim.r
                    direction: PathArc.Clockwise
                }
                PathLine { x: rim.inset + rim.r; y: rim.inset + rim.boxH }
                PathArc {
                    x: rim.inset; y: rim.inset + rim.boxH - rim.r
                    radiusX: rim.r; radiusY: rim.r
                    direction: PathArc.Clockwise
                }
                PathLine { x: rim.inset; y: rim.height / 2 }
            }
        }
    }
}
