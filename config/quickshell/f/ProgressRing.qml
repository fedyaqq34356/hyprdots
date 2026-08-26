import QtQuick

Item {
    id: ring

    property real value: 0
    property color color: "#ffffff"
    property color trackColor: "transparent"
    property real thickness: 1.6

    property real inset: 1

    property int animationDuration: 400

    property real shown: 0
    onValueChanged: shown = Math.max(0, Math.min(1, value))

    Behavior on shown {
        NumberAnimation {
            duration: ring.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    onShownChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const cx = width / 2;
            const cy = height / 2;
            const r = Math.min(cx, cy) - ring.thickness / 2 - ring.inset;
            if (r <= 0)
                return;

            const start = -Math.PI / 2;

            if (ring.trackColor.a > 0) {
                ctx.beginPath();
                ctx.arc(cx, cy, r, 0, Math.PI * 2);
                ctx.strokeStyle = ring.trackColor;
                ctx.lineWidth = ring.thickness;
                ctx.stroke();
            }

            if (ring.shown <= 0.001)
                return;

            ctx.beginPath();
            ctx.arc(cx, cy, r, start, start + Math.PI * 2 * ring.shown);
            ctx.strokeStyle = ring.color;
            ctx.lineWidth = ring.thickness;
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }
}
