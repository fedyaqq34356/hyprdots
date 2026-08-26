import QtQuick

// A thin arc drawn around whatever it is placed over. Used in the bar to show
// track position around the album cover, so the position reads without giving
// up space for a number or a separate bar.
//
// Deliberately minimal compared to Ring.qml: no label, no colour ramp, no
// head dot. At 22 pixels across, anything more turns into noise.
Item {
    id: ring

    property real value: 0
    property color color: "#ffffff"
    property color trackColor: "transparent"
    property real thickness: 1.6

    // Gap left between the arc and the edge of the item.
    property real inset: 1

    property int animationDuration: 400

    // The drawn value trails the real one, so a seek sweeps rather than jumps.
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
