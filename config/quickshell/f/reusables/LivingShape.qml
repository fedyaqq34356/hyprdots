import QtQuick
import "root:/design"

Item {
    id: shape

    property bool running: true
    property color tint: Colors.accent

    property real dwell: 1.15

    property real stroke: 1.5

    property real breath: 0.06

    implicitWidth: 44
    implicitHeight: 44

    opacity: running ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity {
        NumberAnimation { duration: Motion.base; easing.type: Easing.InOutQuad }
    }

    readonly property var forms: [
        { m: 3, n1: 7.0, n2: 6.0, n3: 6.0 },
        { m: 4, n1: 8.0, n2: 6.0, n3: 6.0 },
        { m: 6, n1: 7.0, n2: 5.0, n3: 5.0 },
        { m: 2, n1: 4.0, n2: 6.0, n3: 6.0 },
        { m: 5, n1: 6.0, n2: 5.5, n3: 5.5 },
        { m: 8, n1: 9.0, n2: 6.0, n3: 6.0 },
        { m: 3, n1: 10.0, n2: 8.0, n3: 8.0 }
    ]

    property real t: 0

    onRunningChanged: {
        if (!shape.running)
            return;
        shape.t = 0;
        shape.lastPaint = 0;
        canvas.requestPaint();
    }

    property real lastPaint: 0

    FrameAnimation {
        running: shape.running && shape.visible
        onTriggered: {
            shape.t += frameTime;
            if (shape.t - shape.lastPaint < 0.033)
                return;
            shape.lastPaint = shape.t;
            canvas.requestPaint();
        }
    }

    function sf(th, m, n1, n2, n3) {
        const c = Math.pow(Math.abs(Math.cos(m * th / 4)), n2);
        const s = Math.pow(Math.abs(Math.sin(m * th / 4)), n3);
        return Math.pow(c + s, -1 / n1);
    }

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        readonly property int samples: 120

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const forms = shape.forms;
            const n = forms.length;
            const pos = shape.t / shape.dwell;
            const i = Math.floor(pos) % n;
            const j = (i + 1) % n;

            const f = pos - Math.floor(pos);
            const e = f < 0.35 ? 0
                    : f > 0.9 ? 1
                    : (function (u) {
                        return u * u * (3 - 2 * u);
                    })((f - 0.35) / 0.55);

            const a = forms[i];
            const b = forms[j];
            const m  = a.m  + (b.m  - a.m)  * e;
            const n1 = a.n1 + (b.n1 - a.n1) * e;
            const n2 = a.n2 + (b.n2 - a.n2) * e;
            const n3 = a.n3 + (b.n3 - a.n3) * e;

            const cx = width / 2;
            const cy = height / 2;
            const pad = shape.stroke + 1;

            const pts = [];
            let peak = 0;
            for (let k = 0; k < canvas.samples; k++) {
                const th = k / canvas.samples * Math.PI * 2;
                const r = shape.sf(th, m, n1, n2, n3);
                pts.push(r);
                if (r > peak)
                    peak = r;
            }
            if (peak <= 0)
                return;

            const breathe = 1 - shape.breath
                          + shape.breath * Math.cos(shape.t * 2.0);
            const base = (Math.min(cx, cy) - pad) / peak * breathe;

            const spin = shape.t * 0.35;

            ctx.beginPath();
            for (let k = 0; k <= canvas.samples; k++) {
                const idx = k % canvas.samples;
                const th = idx / canvas.samples * Math.PI * 2;
                const r = pts[idx] * base;
                const x = cx + Math.cos(th + spin) * r;
                const y = cy + Math.sin(th + spin) * r;
                if (k === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.closePath();

            const g = ctx.createRadialGradient(cx, cy, 0, cx, cy,
                                               Math.min(cx, cy));
            g.addColorStop(0, Qt.rgba(shape.tint.r, shape.tint.g,
                                      shape.tint.b, 0.55));
            g.addColorStop(1, Qt.rgba(shape.tint.r, shape.tint.g,
                                      shape.tint.b, 0.16));
            ctx.fillStyle = g;
            ctx.fill();

            if (shape.stroke > 0) {
                ctx.strokeStyle = Qt.rgba(shape.tint.r, shape.tint.g,
                                          shape.tint.b, 0.85);
                ctx.lineWidth = shape.stroke;
                ctx.lineJoin = "round";
                ctx.stroke();
            }
        }
    }
}
