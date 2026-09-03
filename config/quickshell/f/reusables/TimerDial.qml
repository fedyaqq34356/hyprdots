import QtQuick
import "root:/design"

Item {
    id: dial

    property real progress: 0
    property bool running: false
    property bool ringing: false
    property color tint: Colors.accent
    property real thickness: 7
    property int marks: 60
    property int urgentAt: 10
    property int remaining: 0

    implicitWidth: 260
    implicitHeight: 260

    readonly property bool urgent:
        dial.running && dial.remaining > 0 && dial.remaining <= dial.urgentAt

    readonly property color live:
        dial.ringing ? Colors.bad
                     : (dial.urgent ? Colors.warn : dial.tint)

    property real shown: 0
    onProgressChanged: dial.shown = dial.progress
    Behavior on shown {
        NumberAnimation { duration: 950; easing.type: Easing.Linear }
    }

    onShownChanged: dial.maybePaint()
    onLiveChanged: face.requestPaint()
    onWidthChanged: face.requestPaint()

    property real paintedAt: -1

    function maybePaint() {
        const span = Math.PI * dial.width;
        if (dial.paintedAt >= 0
            && Math.abs(dial.shown - dial.paintedAt) * span < 0.5)
            return;
        dial.paintedAt = dial.shown;
        face.requestPaint();
    }

    Canvas {
        id: halo

        anchors.centerIn: parent
        width: dial.width * 1.5
        height: width
        renderStrategy: Canvas.Cooperative

        opacity: dial.ringing ? 0.9 : (dial.running ? 0.35 : 0.12)
        Behavior on opacity { NumberAnimation { duration: Motion.slow } }

        readonly property color glow: dial.live
        onGlowChanged: halo.requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const r = width / 2;
            const g = ctx.createRadialGradient(r, r, r * 0.42, r, r, r);
            const c = halo.glow;
            g.addColorStop(0.00, Qt.rgba(c.r, c.g, c.b, 0.28));
            g.addColorStop(0.45, Qt.rgba(c.r, c.g, c.b, 0.10));
            g.addColorStop(1.00, Qt.rgba(c.r, c.g, c.b, 0.0));
            ctx.fillStyle = g;
            ctx.fillRect(0, 0, width, height);
        }

        SequentialAnimation on scale {
            running: dial.ringing
            loops: Animation.Infinite
            NumberAnimation { to: 1.10; duration: 620; easing.type: Easing.OutQuad }
            NumberAnimation { to: 0.96; duration: 620; easing.type: Easing.InQuad }
        }
    }

    onRingingChanged: if (!dial.ringing) halo.scale = 1

    Canvas {
        id: face

        anchors.fill: parent
        renderStrategy: Canvas.Cooperative
        antialiasing: true

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const cx = width / 2;
            const cy = height / 2;
            const r = Math.min(cx, cy) - dial.thickness * 1.6;
            if (r <= 0)
                return;

            const c = dial.live;
            const start = -Math.PI / 2;
            const sweep = Math.PI * 2 * Math.max(0, Math.min(1, dial.shown));

            for (let i = 0; i < dial.marks; i++) {
                const a = start + (Math.PI * 2 * i) / dial.marks;
                const major = i % 5 === 0;
                const lit = a - start <= sweep + 0.0001;
                const inner = r - (major ? dial.thickness * 1.5 : dial.thickness);
                ctx.beginPath();
                ctx.moveTo(cx + Math.cos(a) * inner, cy + Math.sin(a) * inner);
                ctx.lineTo(cx + Math.cos(a) * r, cy + Math.sin(a) * r);
                ctx.lineWidth = major ? 2 : 1;
                ctx.strokeStyle = lit
                    ? Qt.rgba(c.r, c.g, c.b, major ? 0.55 : 0.35)
                    : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b,
                              major ? 0.22 : 0.10);
                ctx.stroke();
            }

            const ar = r + dial.thickness * 0.9;
            ctx.beginPath();
            ctx.arc(cx, cy, ar, 0, Math.PI * 2);
            ctx.lineWidth = dial.thickness;
            ctx.strokeStyle = Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                      Colors.fgDim.b, 0.10);
            ctx.stroke();

            if (sweep <= 0.001)
                return;

            const grad = ctx.createLinearGradient(0, 0, width, height);
            grad.addColorStop(0.0, Qt.rgba(c.r, c.g, c.b, 0.55));
            grad.addColorStop(1.0, Qt.rgba(c.r, c.g, c.b, 1.0));

            ctx.beginPath();
            ctx.arc(cx, cy, ar, start, start + sweep);
            ctx.lineWidth = dial.thickness;
            ctx.lineCap = "round";
            ctx.strokeStyle = grad;
            ctx.stroke();

            const head = start + sweep;
            const hx = cx + Math.cos(head) * ar;
            const hy = cy + Math.sin(head) * ar;

            ctx.beginPath();
            ctx.arc(hx, hy, dial.thickness * 1.15, 0, Math.PI * 2);
            ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, 0.22);
            ctx.fill();

            ctx.beginPath();
            ctx.arc(hx, hy, dial.thickness * 0.62, 0, Math.PI * 2);
            ctx.fillStyle = c;
            ctx.fill();
        }
    }

    default property alias content: middle.data

    Item {
        id: middle
        anchors.centerIn: parent
        width: parent.width * 0.72
        height: parent.height * 0.72
    }
}
