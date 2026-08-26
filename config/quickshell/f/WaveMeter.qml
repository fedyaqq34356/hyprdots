import QtQuick

// A level meter drawn as a travelling sine wave instead of a bar.
//
// The wave runs the full width of the widget. Everything left of `value` is
// drawn filled in the accent colour; everything right of it stays as a faint
// outline, so the fill level still reads at a glance the way a bar does.
//
// Amplitude tracks the value as well, so a quiet volume is a nearly flat line
// and a loud one is a tall wave. `flat` (used for mute) collapses it to a
// straight line without hiding the widget.
Item {
    id: meter

    property real value: 0
    property bool flat: false
    property bool animating: true

    // Optional spectrum, one 0..1 level per band (Cava.levels). When it holds
    // anything, each band drives one harmonic of the drawn wave, so the shape
    // follows what is actually playing. Empty means fall back to a plain sine.
    property var spectrum: []

    property color fillColor: "#ffffff"
    property color trackColor: "#40ffffff"

    // Wavelength in pixels and how far the wave has travelled.
    property real wavelength: 46
    property real phase: 0

    implicitHeight: 26

    property real clamped: Math.max(0, Math.min(1, value))

    // Amplitude never reaches the full half-height: the stroke needs room and a
    // wave that touches the edges looks clipped.
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

            // A player can report "playing" while the stream is corked, in
            // which case every band is zero. Fade back to the plain sine as the
            // signal dies so silence still looks alive.
            const live = bandCount > 0 ? Math.min(1, energy * 4) : 0;

            // Normalise to the loudest band so a quiet passage still swells
            // instead of drawing a nearly straight line.
            let peak = 0;
            for (let b = 0; b < bandCount; b++)
                peak = Math.max(peak, bands[b]);
            const bandScale = peak > 0.001 ? 1 / peak : 0;

            // Cosine interpolation between neighbouring bands. Linear would
            // put a visible kink at every band boundary.
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

            // One sample per pixel is plenty at this size and keeps the paint
            // cheap enough to run every frame.
            //
            // The spectrum modulates the local amplitude rather than adding
            // harmonics: the wave swells where the music is loud and settles
            // where it is quiet, which reads clearly at this size where a sum
            // of twelve harmonics just looks like fuzz.
            function waveY(x) {
                const carrier = Math.sin(x * k + meter.phase);
                if (live <= 0.001)
                    return mid + carrier * amp;

                const swell = 0.30 + 0.70 * levelAt(x);
                const modulated = carrier * (1 - live + live * swell * 1.35);
                return mid + Math.max(-1, Math.min(1, modulated)) * amp;
            }

            // Track: the whole wave as a thin outline.
            ctx.beginPath();
            ctx.moveTo(0, waveY(0));
            for (let x = 1; x <= w; x++) ctx.lineTo(x, waveY(x));
            ctx.lineWidth = 1.5;
            ctx.lineCap = "round";
            ctx.strokeStyle = meter.trackColor;
            ctx.stroke();

            if (split <= 0)
                return;

            // Filled region up to the current value.
            ctx.beginPath();
            ctx.moveTo(0, h);
            ctx.lineTo(0, waveY(0));
            for (let x = 1; x <= split; x++) ctx.lineTo(x, waveY(x));
            ctx.lineTo(split, h);
            ctx.closePath();
            ctx.fillStyle = Qt.rgba(meter.fillColor.r, meter.fillColor.g,
                                    meter.fillColor.b, 0.28);
            ctx.fill();

            // Bright crest over the filled region.
            ctx.beginPath();
            ctx.moveTo(0, waveY(0));
            for (let x = 1; x <= split; x++) ctx.lineTo(x, waveY(x));
            ctx.lineWidth = 2.5;
            ctx.lineCap = "round";
            ctx.strokeStyle = meter.fillColor;
            ctx.stroke();

            // Dot riding the crest at the current level.
            ctx.beginPath();
            ctx.arc(split, waveY(split), 3, 0, Math.PI * 2);
            ctx.fillStyle = meter.fillColor;
            ctx.fill();
        }
    }
}
