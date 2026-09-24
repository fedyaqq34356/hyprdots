import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: at

    property string source: Media.art
    property color fallback: Colors.accent
    property bool found: false
    property color color: at.fallback

    width: 16
    height: 16
    opacity: 0.02

    Behavior on color { ColorAnimation { duration: 700 } }

    onSourceChanged: at.probe()
    Component.onCompleted: at.probe()

    function probe() {
        if (at.source === "") {
            at.found = false;
            at.color = at.fallback;
            return;
        }
        if (probeCanvas.isImageLoaded(at.source))
            probeCanvas.requestPaint();
        else
            probeCanvas.loadImage(at.source);
    }

    Canvas {
        id: probeCanvas

        anchors.fill: parent
        renderTarget: Canvas.Image
        renderStrategy: Canvas.Immediate

        onImageLoaded: probeCanvas.requestPaint()

        onPaint: {
            const src = at.source;
            if (src === "" || !probeCanvas.isImageLoaded(src))
                return;
            const w = probeCanvas.width;
            const h = probeCanvas.height;
            const ctx = getContext("2d");
            ctx.clearRect(0, 0, w, h);
            ctx.drawImage(src, 0, 0, w, h);
            const px = ctx.getImageData(0, 0, w, h).data;
            at.pick(px);
            probeCanvas.unloadImage(src);
        }
    }

    function pick(px) {
        const bins = 12;
        const wr = new Array(bins).fill(0);
        const wg = new Array(bins).fill(0);
        const wb = new Array(bins).fill(0);
        const wt = new Array(bins).fill(0);
        let total = 0;

        for (let i = 0; i < px.length; i += 4) {
            const r = px[i] / 255, g = px[i + 1] / 255, b = px[i + 2] / 255;
            const mx = Math.max(r, g, b), mn = Math.min(r, g, b);
            const v = mx;
            const s = mx === 0 ? 0 : (mx - mn) / mx;
            if (v < 0.14 || s < 0.16)
                continue;
            let hue;
            const d = mx - mn;
            if (mx === r)      hue = ((g - b) / d) % 6;
            else if (mx === g) hue = (b - r) / d + 2;
            else               hue = (r - g) / d + 4;
            hue = (hue * 60 + 360) % 360;
            const k = Math.floor(hue / 360 * bins) % bins;
            const wgt = s * s * v;
            wr[k] += r * wgt; wg[k] += g * wgt; wb[k] += b * wgt; wt[k] += wgt;
            total += wgt;
        }

        let best = -1, bestW = 0;
        for (let k = 0; k < bins; k++) {
            const sw = wt[k] + 0.5 * (wt[(k + 1) % bins] + wt[(k + bins - 1) % bins]);
            if (sw > bestW) { bestW = sw; best = k; }
        }

        if (best < 0 || total < 0.6) {
            at.found = false;
            at.color = at.fallback;
            return;
        }

        const kl = (best + bins - 1) % bins, kr = (best + 1) % bins;
        const sr = wr[best] + 0.5 * (wr[kl] + wr[kr]);
        const sg = wg[best] + 0.5 * (wg[kl] + wg[kr]);
        const sb = wb[best] + 0.5 * (wb[kl] + wb[kr]);
        const c = Qt.rgba(sr / bestW, sg / bestW, sb / bestW, 1);
        const hs = c.hslSaturation, hl = c.hslLightness;
        at.color = Qt.hsla(Math.max(0, c.hslHue),
                           Math.max(0.55, Math.min(0.92, hs * 1.25)),
                           Math.max(0.58, Math.min(0.72, hl)), 1);
        at.found = true;
    }
}
