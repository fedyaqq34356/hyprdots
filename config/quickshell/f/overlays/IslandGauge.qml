import QtQuick
import QtQuick.Shapes as Vec
import "root:/design"

Item {
    id: g

    property real value: 0
    property color tint: Colors.accent
    property real thick: Math.max(3, g.width * 0.085)
    property bool showPct: true
    property string glyph: ""
    property string centerText: ""
    property int fillMs: 1100

    property real shown: 0
    Component.onCompleted: g.shown = Math.max(0, Math.min(1, g.value))
    onValueChanged: g.shown = Math.max(0, Math.min(1, g.value))
    Behavior on shown {
        NumberAnimation { duration: g.fillMs; easing.type: Easing.OutCubic }
    }

    readonly property real r: (Math.min(g.width, g.height) - g.thick * 2.2) / 2
    readonly property real cx: g.width / 2
    readonly property real cy: g.height / 2

    Vec.Shape {
        anchors.fill: parent
        preferredRendererType: Vec.Shape.CurveRenderer

        Vec.ShapePath {
            strokeColor: Colors.alpha(Colors.fg, 0.12)
            strokeWidth: g.thick
            fillColor: "transparent"
            capStyle: Vec.ShapePath.RoundCap
            PathAngleArc {
                centerX: g.cx; centerY: g.cy
                radiusX: g.r; radiusY: g.r
                startAngle: -90; sweepAngle: 360
            }
        }

        Vec.ShapePath {
            strokeColor: Colors.alpha(g.tint, 0.22)
            strokeWidth: g.thick * 2.8
            fillColor: "transparent"
            capStyle: Vec.ShapePath.RoundCap
            PathAngleArc {
                centerX: g.cx; centerY: g.cy
                radiusX: g.r; radiusY: g.r
                startAngle: -90; sweepAngle: Math.max(0.1, 360 * g.shown)
            }
        }

        Vec.ShapePath {
            strokeColor: g.tint
            strokeWidth: g.thick
            fillColor: "transparent"
            capStyle: Vec.ShapePath.RoundCap
            PathAngleArc {
                centerX: g.cx; centerY: g.cy
                radiusX: g.r; radiusY: g.r
                startAngle: -90; sweepAngle: Math.max(0.1, 360 * g.shown)
            }
        }
    }

    Rectangle {
        readonly property real a: (-90 + 360 * g.shown) * Math.PI / 180
        width: g.thick * 0.9
        height: width
        radius: width / 2
        antialiasing: true
        color: Qt.lighter(g.tint, 1.7)
        x: g.cx + Math.cos(a) * g.r - width / 2
        y: g.cy + Math.sin(a) * g.r - height / 2
        visible: g.shown > 0.02
    }

    Column {
        anchors.centerIn: parent
        spacing: -1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: g.glyph !== ""
            text: g.glyph
            color: g.tint
            font.family: Fonts.glyph
            font.pixelSize: Math.round(g.width * (g.showPct ? 0.26 : 0.36))
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: g.showPct || g.centerText !== ""
            text: g.centerText !== "" ? g.centerText : Math.round(g.shown * 100) + "%"
            color: Colors.fg
            font.family: Fonts.display
            font.pixelSize: Math.round(g.width * (g.glyph !== "" ? 0.2 : 0.26))
            font.weight: Font.DemiBold
        }
    }
}
