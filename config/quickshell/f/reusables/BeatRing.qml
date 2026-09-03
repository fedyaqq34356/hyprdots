import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: ring

    property real progress: 0
    property bool showProgress: true
    property real thickness: 3
    property color tint: Colors.accent

    implicitWidth: 168
    implicitHeight: 168

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        antialiasing: true
        border.width: ring.thickness
        border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                              Colors.outline.b, 0.2)
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: width / 2
        color: "transparent"
        antialiasing: true

        border.width: ring.thickness + Beat.pulse * 4
        border.color: Qt.rgba(ring.tint.r, ring.tint.g, ring.tint.b,
                              0.12 + Beat.pulse * 0.55)
        scale: 1 + Beat.pulse * 0.035
    }

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: width / 2
        color: "transparent"
        antialiasing: true
        visible: Beat.pulse > 0.02

        border.width: 1.5
        border.color: Qt.rgba(ring.tint.r, ring.tint.g, ring.tint.b,
                              Beat.pulse * 0.45)
        scale: 1 + (1 - Beat.pulse) * 0.17
    }

    Canvas {
        id: arc

        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        antialiasing: true

        readonly property real p: Math.max(0, Math.min(1, ring.progress))
        readonly property color c: ring.tint

        onPChanged: arc.maybePaint()
        onCChanged: arc.requestPaint()
        onWidthChanged: arc.requestPaint()

        property real paintedAt: -1

        function maybePaint() {
            const span = Math.PI * width;
            if (arc.paintedAt >= 0 && Math.abs(arc.p - arc.paintedAt) * span < 0.5)
                return;
            arc.paintedAt = arc.p;
            arc.requestPaint();
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (!ring.showProgress)
                return;

            const r = width / 2 - ring.thickness / 2 - 1;
            ctx.lineWidth = ring.thickness;
            ctx.lineCap = "round";
            ctx.strokeStyle = arc.c;
            ctx.beginPath();
            ctx.arc(width / 2, height / 2, r,
                    -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * arc.p);
            ctx.stroke();
        }
    }
}
