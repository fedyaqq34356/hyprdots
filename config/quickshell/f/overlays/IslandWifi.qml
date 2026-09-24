import QtQuick
import QtQuick.Shapes as Vec
import "root:/design"

Item {
    id: fan

    property real strength: 1
    property bool on: true
    property color tint: Colors.accent

    implicitWidth: 44
    implicitHeight: 36

    property real sweep: -1
    readonly property int level: fan.on ? Math.max(1, Math.ceil(fan.strength * 3)) : 0

    SequentialAnimation {
        running: true
        loops: fan.on ? 2 : Animation.Infinite
        NumberAnimation {
            target: fan; property: "sweep"
            from: -0.5; to: 3.5; duration: 720
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: 120 }
        onFinished: fan.sweep = -1
    }

    readonly property real cx: fan.width / 2
    readonly property real by: fan.height - 3
    readonly property real stroke: Math.max(3, fan.height * 0.11)

    function glow(i) {
        if (fan.sweep < 0)
            return 0;
        return Math.max(0, 1 - Math.abs(fan.sweep - i) * 1.3);
    }

    function lit(i) { return i <= fan.level; }

    Rectangle {
        width: fan.stroke * 1.5
        height: width
        radius: width / 2
        x: fan.cx - width / 2
        y: fan.by - height / 2 - 1
        antialiasing: true
        color: fan.on ? fan.tint : Colors.alpha(Colors.fg, 0.25)
        scale: 1 + fan.glow(0) * 0.35
    }

    Repeater {
        model: 3

        Vec.Shape {
            id: arc
            required property int index
            readonly property int n: arc.index + 1
            readonly property real r: fan.stroke * 1.2 + arc.n * (fan.height - fan.stroke * 2) / 3.3
            readonly property real g: fan.glow(arc.n)

            anchors.fill: parent
            preferredRendererType: Vec.Shape.CurveRenderer
            opacity: fan.lit(arc.n) ? 1 : (0.2 + 0.8 * arc.g)

            Behavior on opacity { NumberAnimation { duration: 200 } }

            Vec.ShapePath {
                strokeColor: fan.lit(arc.n) || arc.g > 0
                    ? Qt.lighter(fan.tint, 1 + arc.g * 0.5)
                    : Colors.alpha(Colors.fg, 1)
                strokeWidth: fan.stroke
                fillColor: "transparent"
                capStyle: Vec.ShapePath.RoundCap
                PathAngleArc {
                    centerX: fan.cx; centerY: fan.by
                    radiusX: arc.r; radiusY: arc.r
                    startAngle: -135; sweepAngle: 90
                }
            }
        }
    }
}
