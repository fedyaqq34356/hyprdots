import QtQuick
import QtQuick.Window
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

    readonly property bool onScreen:
        view.visible && view.Window.window !== null && view.Window.window.visible

    Connections {
        target: Cava
        enabled: view.onScreen
        function onLevelsChanged() { view.requestPaint(); }
    }

    property bool holding: false

    function sync() {
        const want = view.onScreen;
        if (want === view.holding)
            return;
        view.holding = want;
        if (want) Cava.hold();
        else Cava.release();
    }

    Component.onCompleted: view.sync()
    Component.onDestruction: if (view.holding) Cava.release()

    onOnScreenChanged: {
        view.sync();
        if (view.onScreen)
            view.requestPaint();
    }

    Connections {
        target: Colors
        function onAccentChanged() { view.requestPaint(); }
    }

    onModeChanged: view.requestPaint()
    onWidthChanged: view.requestPaint()
    onHeightChanged: view.requestPaint()
    onTintChanged: view.requestPaint()

    function sampleFrom(l, n, pos) {
        if (n === 0)
            return 0;

        const x = pos * (n - 1);
        const i = Math.floor(x);
        const t = x - i;

        const p0 = l[i > 0 ? i - 1 : 0];
        const p1 = l[i];
        const p2 = l[i + 1 < n ? i + 1 : n - 1];
        const p3 = l[i + 2 < n ? i + 2 : n - 1];

        const v = 0.5 * ((2 * p1)
            + (-p0 + p2) * t
            + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
            + (-p0 + 3 * p1 - 3 * p2 + p3) * t * t * t);
        return v < 0 ? 0 : (v > 1 ? 1 : v);
    }

    onPaint: {
        if (width <= 0 || height <= 0)
            return;

        const ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.globalAlpha = 1;

        const src = Cava.levels;
        const n = src ? src.length : 0;
        if (n === 0)
            return;

        const l = new Array(n);
        for (let i = 0; i < n; i++)
            l[i] = src[i];

        const c = view.tint;

        if (view.mode === "radial")
            view.paintRadial(ctx, l, n, c);
        else if (view.mode === "wave")
            view.paintWave(ctx, l, n, c);
        else
            view.paintBars(ctx, l, n, c);
    }

    function paintBars(ctx, l, n, c) {
        const w = view.width;
        const h = view.height;
        const count = Math.max(4, Math.round(view.resolution / 2));
        const step = w / count;
        const bw = step * (1 - view.gap);

        const top = Qt.rgba(c.r, c.g, c.b, 0.95);
        const bottom = Qt.rgba(c.r, c.g, c.b, 0.35);
        const r = Math.min(bw / 2, 3);

        for (let i = 0; i < count; i++) {
            const v = view.sampleFrom(l, n, i / (count - 1));
            const bh = Math.max(2, v * h);
            const x = i * step + (step - bw) / 2;
            const y = h - bh;

            const grad = ctx.createLinearGradient(0, y, 0, h);
            grad.addColorStop(0.0, top);
            grad.addColorStop(1.0, bottom);
            ctx.fillStyle = grad;

            ctx.beginPath();
            ctx.moveTo(x, h);
            ctx.lineTo(x, y + r);
            ctx.quadraticCurveTo(x, y, x + r, y);
            ctx.lineTo(x + bw - r, y);
            ctx.quadraticCurveTo(x + bw, y, x + bw, y + r);
            ctx.lineTo(x + bw, h);
            ctx.closePath();
            ctx.fill();
        }
    }

    function paintWave(ctx, l, n, c) {
        const w = view.width;
        const h = view.height;
        const count = view.resolution;
        const mid = h / 2;
        const amp = (view.mirror ? mid : h) * 0.92;

        const xs = new Array(count + 1);
        const ys = new Array(count + 1);
        for (let i = 0; i <= count; i++) {
            const v = view.sampleFrom(l, n, i / count);
            xs[i] = (i / count) * w;
            ys[i] = view.mirror ? mid - v * amp : h - v * amp;
        }

        ctx.beginPath();
        ctx.moveTo(xs[0], view.mirror ? mid : h);
        for (let i = 0; i <= count; i++)
            ctx.lineTo(xs[i], ys[i]);
        if (view.mirror) {
            for (let i = count; i >= 0; i--)
                ctx.lineTo(xs[i], mid + (mid - ys[i]));
        } else {
            ctx.lineTo(w, h);
        }
        ctx.closePath();

        const grad = ctx.createLinearGradient(0, 0, 0, h);
        grad.addColorStop(0.0, Qt.rgba(c.r, c.g, c.b, 0.45));
        grad.addColorStop(0.5, Qt.rgba(c.r, c.g, c.b, 0.14));
        grad.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, 0.45));
        ctx.fillStyle = grad;
        ctx.fill();

        ctx.beginPath();
        ctx.moveTo(xs[0], ys[0]);
        for (let i = 0; i <= count; i++)
            ctx.lineTo(xs[i], ys[i]);
        ctx.lineWidth = 2;
        ctx.lineJoin = "round";
        ctx.lineCap = "butt";
        ctx.strokeStyle = Qt.rgba(c.r, c.g, c.b, 0.95);
        ctx.stroke();
    }

    function paintRadial(ctx, l, n, c) {
        const w = view.width;
        const h = view.height;
        const cx = w / 2;
        const cy = h / 2;
        const outer = Math.min(cx, cy);
        const inner = outer * view.hole;
        const span = outer - inner;
        const count = view.resolution;
        const half = count / 2;

        const cr = c.r;
        const cg = c.g;
        const cb = c.b;

        ctx.lineCap = "round";
        ctx.lineJoin = "miter";
        ctx.lineWidth = Math.max(1.5, (Math.PI * 2 * inner) / count * (1 - view.gap));

        const start = -Math.PI / 2;
        const stepA = (Math.PI * 2) / count;

        for (let i = 0; i < count; i++) {
            const pos = i < half ? i / half : (count - i) / half;
            const v = view.sampleFrom(l, n, pos);
            const a = start + stepA * i;
            const ca = Math.cos(a);
            const sa = Math.sin(a);
            const len = span * v;

            ctx.beginPath();
            ctx.moveTo(cx + ca * inner, cy + sa * inner);
            ctx.lineTo(cx + ca * (inner + len), cy + sa * (inner + len));
            ctx.strokeStyle = Qt.rgba(cr, cg, cb, 0.35 + v * 0.6);
            ctx.stroke();
        }
    }
}
