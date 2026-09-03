import QtQuick
import "root:/design"
import "root:/services"

Canvas {
    id: view

    property string mode: "bars"
    property color tint: Colors.accent
    property int resolution: 48
    property real gap: 0.28
    property real hole: 0.55
    property bool mirror: true

    renderStrategy: Canvas.Cooperative
    antialiasing: true

    Connections {
        target: Cava
        function onLevelsChanged() { view.requestPaint(); }
    }

    Connections {
        target: Colors
        function onAccentChanged() { view.requestPaint(); }
    }

    onModeChanged: view.requestPaint()
    onWidthChanged: view.requestPaint()
    onHeightChanged: view.requestPaint()

    function sample(pos) {
        const l = Cava.levels;
        const n = l.length;
        if (n === 0)
            return 0;

        const x = pos * (n - 1);
        const i = Math.floor(x);
        const t = x - i;

        const p0 = l[Math.max(0, i - 1)];
        const p1 = l[i];
        const p2 = l[Math.min(n - 1, i + 1)];
        const p3 = l[Math.min(n - 1, i + 2)];

        const v = 0.5 * ((2 * p1)
            + (-p0 + p2) * t
            + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
            + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t);
        return Math.max(0, Math.min(1, v));
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();

        if (view.mode === "radial")
            view.paintRadial(ctx);
        else if (view.mode === "wave")
            view.paintWave(ctx);
        else
            view.paintBars(ctx);
    }

    function paintBars(ctx) {
        const n = Math.max(4, Math.round(view.resolution / 2));
        const step = width / n;
        const w = step * (1 - view.gap);
        const c = view.tint;

        for (let i = 0; i < n; i++) {
            const v = view.sample(i / (n - 1));
            const h = Math.max(2, v * height);
            const x = i * step + (step - w) / 2;

            const grad = ctx.createLinearGradient(0, height - h, 0, height);
            grad.addColorStop(0.0, Qt.rgba(c.r, c.g, c.b, 0.95));
            grad.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, 0.35));
            ctx.fillStyle = grad;

            const r = Math.min(w / 2, 3);
            ctx.beginPath();
            ctx.moveTo(x, height);
            ctx.lineTo(x, height - h + r);
            ctx.quadraticCurveTo(x, height - h, x + r, height - h);
            ctx.lineTo(x + w - r, height - h);
            ctx.quadraticCurveTo(x + w, height - h, x + w, height - h + r);
            ctx.lineTo(x + w, height);
            ctx.closePath();
            ctx.fill();
        }
    }

    function paintWave(ctx) {
        const n = view.resolution;
        const mid = height / 2;
        const c = view.tint;
        const amp = view.mirror ? mid : height;

        const pts = [];
        for (let i = 0; i <= n; i++) {
            const v = view.sample(i / n);
            pts.push({
                x: (i / n) * width,
                y: view.mirror ? mid - v * amp * 0.92
                               : height - v * amp * 0.92
            });
        }

        ctx.beginPath();
        ctx.moveTo(pts[0].x, view.mirror ? mid : height);
        for (const p of pts)
            ctx.lineTo(p.x, p.y);
        if (view.mirror) {
            for (let i = pts.length - 1; i >= 0; i--)
                ctx.lineTo(pts[i].x, mid + (mid - pts[i].y));
        } else {
            ctx.lineTo(width, height);
        }
        ctx.closePath();

        const grad = ctx.createLinearGradient(0, 0, 0, height);
        grad.addColorStop(0.0, Qt.rgba(c.r, c.g, c.b, 0.45));
        grad.addColorStop(0.5, Qt.rgba(c.r, c.g, c.b, 0.14));
        grad.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, 0.45));
        ctx.fillStyle = grad;
        ctx.fill();

        ctx.beginPath();
        ctx.moveTo(pts[0].x, pts[0].y);
        for (const p of pts)
            ctx.lineTo(p.x, p.y);
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.95);
        ctx.stroke();
    }

    function paintRadial(ctx) {
        const cx = width / 2;
        const cy = height / 2;
        const outer = Math.min(cx, cy);
        const inner = outer * view.hole;
        const n = view.resolution;
        const c = view.tint;

        ctx.lineCap = "round";
        ctx.lineWidth = Math.max(1.5, (Math.PI * 2 * inner) / n * (1 - view.gap));

        for (let i = 0; i < n; i++) {
            const half = i < n / 2 ? i / (n / 2) : (n - i) / (n / 2);
            const v = view.sample(half);
            const a = -Math.PI / 2 + (Math.PI * 2 * i) / n;
            const len = (outer - inner) * v;

            ctx.beginPath();
            ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner);
            ctx.lineTo(cx + Math.cos(a) * (inner + len),
                       cy + Math.sin(a) * (inner + len));
            ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.35 + v * 0.6);
            ctx.stroke();
        }
    }
}
