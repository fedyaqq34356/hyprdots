import QtQuick

Item {
    id: ring

    property real value: 0
    property real radius: 12
    property real thickness: 2
    property color color: "#ffffff"
    property color trackColor: "transparent"

    property real inset: 0

    Canvas {
        id: canvas
        anchors.fill: parent
        anchors.margins: ring.inset
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const w = width;
            const h = height;
            const r = Math.min(ring.radius, Math.min(w, h) / 2);
            if (w <= 0 || h <= 0 || r <= 0)
                return;

            const straightH = Math.max(0, w - 2 * r);
            const straightV = Math.max(0, h - 2 * r);
            const arc = (Math.PI / 2) * r;

            if (ring.trackColor.a > 0) {
                ctx.beginPath();
                ctx.moveTo(r, 0);
                ctx.lineTo(w - r, 0);
                ctx.arc(w - r, r, r, -Math.PI / 2, 0);
                ctx.lineTo(w, h - r);
                ctx.arc(w - r, h - r, r, 0, Math.PI / 2);
                ctx.lineTo(r, h);
                ctx.arc(r, h - r, r, Math.PI / 2, Math.PI);
                ctx.lineTo(0, r);
                ctx.arc(r, r, r, Math.PI, Math.PI * 1.5);
                ctx.strokeStyle = ring.trackColor;
                ctx.lineWidth = ring.thickness;
                ctx.stroke();
            }

            const frac = Math.max(0, Math.min(1, ring.value));
            if (frac <= 0)
                return;

            const total = 2 * straightH + 2 * straightV + 4 * arc;
            let budget = total * frac;

            ctx.beginPath();
            ctx.moveTo(w / 2, 0);

            function line(x1, y1, x2, y2, len) {
                if (budget <= 0) return false;
                const t = len > 0 ? Math.min(1, budget / len) : 1;
                ctx.lineTo(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t);
                budget -= len;
                return budget > 0;
            }

            function corner(cx, cy, from, to) {
                if (budget <= 0) return false;
                const t = Math.min(1, budget / arc);
                ctx.arc(cx, cy, r, from, from + (to - from) * t);
                budget -= arc;
                return budget > 0;
            }

            line(w / 2, 0, w - r, 0, straightH / 2)
                && corner(w - r, r, -Math.PI / 2, 0)
                && line(w, r, w, h - r, straightV)
                && corner(w - r, h - r, 0, Math.PI / 2)
                && line(w - r, h, r, h, straightH)
                && corner(r, h - r, Math.PI / 2, Math.PI)
                && line(0, h - r, 0, r, straightV)
                && corner(r, r, Math.PI, Math.PI * 1.5)
                && line(r, 0, w / 2, 0, straightH / 2);

            ctx.strokeStyle = ring.color;
            ctx.lineWidth = ring.thickness;
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }

    onValueChanged: canvas.requestPaint()
    onColorChanged: canvas.requestPaint()
    onTrackColorChanged: canvas.requestPaint()
    onThicknessChanged: canvas.requestPaint()
    onRadiusChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
}
