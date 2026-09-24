import QtQuick
import "root:/design"

Canvas {
    id: tick

    property color tint: Colors.good
    property int delay: 260
    property int duration: 420
    property real line: Math.max(1.6, width * 0.14)

    property real t: 0
    onTChanged: requestPaint()
    onTintChanged: requestPaint()

    width: 14
    height: 14
    renderStrategy: Canvas.Cooperative
    antialiasing: true

    SequentialAnimation {
        running: true
        PauseAnimation { duration: tick.delay }
        NumberAnimation {
            target: tick; property: "t"
            from: 0; to: 1; duration: tick.duration
            easing.type: Easing.OutCubic
        }
    }

    onPaint: {
        const ctx = getContext("2d");
        const w = width, h = height;
        ctx.clearRect(0, 0, w, h);
        if (tick.t <= 0)
            return;
        const p0 = [w * 0.16, h * 0.54];
        const p1 = [w * 0.42, h * 0.78];
        const p2 = [w * 0.86, h * 0.24];
        const l1 = Math.hypot(p1[0] - p0[0], p1[1] - p0[1]);
        const l2 = Math.hypot(p2[0] - p1[0], p2[1] - p1[1]);
        let d = tick.t * (l1 + l2);

        ctx.lineWidth = tick.line;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.strokeStyle = tick.tint;
        ctx.beginPath();
        ctx.moveTo(p0[0], p0[1]);
        if (d <= l1) {
            const k = d / l1;
            ctx.lineTo(p0[0] + (p1[0] - p0[0]) * k, p0[1] + (p1[1] - p0[1]) * k);
        } else {
            ctx.lineTo(p1[0], p1[1]);
            const k = (d - l1) / l2;
            ctx.lineTo(p1[0] + (p2[0] - p1[0]) * k, p1[1] + (p2[1] - p1[1]) * k);
        }
        ctx.stroke();
    }
}
