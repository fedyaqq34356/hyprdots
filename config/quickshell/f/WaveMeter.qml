import QtQuick

Item {
    id: meter

    property real value: 0
    property bool flat: false
    property bool animating: true

    property var spectrum: []

    property color fillColor: "#ffffff"
    property color trackColor: "#40ffffff"

    property real wavelength: 46
    property real phase: 0

    implicitHeight: 26

    property real clamped: Math.max(0, Math.min(1, value))

    property real amplitude:
        flat ? 0 : (height / 2 - 3) * (0.25 + 0.75 * clamped)

    NumberAnimation on phase {
        running: meter.animating && meter.visible && !meter.flat
        loops: Animation.Infinite
        from: 0
        to: Math.PI * 2
        duration: 1400
    }

    Behavior on clamped {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }
    Behavior on amplitude {
        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
    }

    onPhaseChanged: canvas.requestPaint()
    onClampedChanged: canvas.requestPaint()
    onSpectrumChanged: canvas.requestPaint()
    onAmplitudeChanged: canvas.requestPaint()
    onFillColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const w = width;
            const h = height;
            const mid = h / 2;
            const amp = meter.amplitude;
            const k = (Math.PI * 2) / Math.max(1, meter.wavelength);
            const split = w * meter.clamped;

            const bands = meter.spectrum;
            const bandCount = bands ? bands.length : 0;

            let energy = 0;
            for (let b = 0; b < bandCount; b++) energy += bands[b];

            const live = bandCount > 0 ? Math.min(1, energy * 4) : 0;

            let peak = 0;
            for (let b = 0; b < bandCount; b++)
                peak = Math.max(peak, bands[b]);
            const bandScale = peak > 0.001 ? 1 / peak : 0;

            function levelAt(x) {
                if (bandCount === 0) return 0;
                if (bandCount === 1) return bands[0] * bandScale;

                const pos = (x / Math.max(1, w)) * (bandCount - 1);
                const i = Math.min(bandCount - 2, Math.floor(pos));
                const t = pos - i;
                const smooth = (1 - Math.cos(t * Math.PI)) / 2;
                return (bands[i] * (1 - smooth) + bands[i + 1] * smooth)
                       * bandScale;
            }

            function waveY(x) {
                const carrier = Math.sin(x * k + meter.phase);
                if (live <= 0.001)
                    return mid + carrier * amp;

                const swell = 0.30 + 0.70 * levelAt(x);
                const modulated = carrier * (1 - live + live * swell * 1.35);
                return mid + Math.max(-1, Math.min(1, modulated)) * amp;
            }

            ctx.beginPath();
            ctx.moveTo(0, waveY(0));
            for (let x = 1; x <= w; x++) ctx.lineTo(x, waveY(x));
            ctx.lineWidth = 1.5;
            ctx.lineCap = "round";
            ctx.strokeStyle = meter.trackColor;
            ctx.stroke();

            if (split <= 0)
                return;

            ctx.beginPath();
            ctx.moveTo(0, h);
            ctx.lineTo(0, waveY(0));
            for (let x = 1; x <= split; x++) ctx.lineTo(x, waveY(x));
            ctx.lineTo(split, h);
            ctx.closePath();
            ctx.fillStyle = Qt.rgba(meter.fillColor.r, meter.fillColor.g,
                                    meter.fillColor.b, 0.28);
            ctx.fill();

            ctx.beginPath();
            ctx.moveTo(0, waveY(0));
            for (let x = 1; x <= split; x++) ctx.lineTo(x, waveY(x));
            ctx.lineWidth = 2.5;
            ctx.lineCap = "round";
            ctx.strokeStyle = meter.fillColor;
            ctx.stroke();

            ctx.beginPath();
            ctx.arc(split, waveY(split), 3, 0, Math.PI * 2);
            ctx.fillStyle = meter.fillColor;
            ctx.fill();
        }
    }
}
