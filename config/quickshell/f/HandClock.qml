import QtQuick

Item {
    id: clock

    property string text: "00:00"
    property color color: "#ffffff"
    property real thickness: 3
    property real glyphWidth: 62
    property real glyphHeight: 100
    property real spacing: 10

    property int writeDuration: 900

    implicitWidth: row.implicitWidth
    implicitHeight: glyphHeight

    readonly property var glyphs: ({
        "0": [[[72,38],[68,18],[46,10],[26,22],[18,55],[18,105],[28,140],[50,150],
               [70,140],[80,105],[80,60],[72,38]]],
        "1": [[[24,44],[42,26],[52,18],[52,150]]],
        "2": [[[18,42],[26,20],[50,12],[72,22],[78,48],[64,78],[30,116],[16,150],
               [82,150]]],
        "3": [[[20,30],[40,12],[66,16],[78,38],[66,62],[44,72],[68,76],[82,100],
               [74,134],[46,152],[20,142],[14,124]]],
        "4": [[[64,14],[16,104],[86,104]], [[64,14],[64,150]]],
        "5": [[[76,16],[28,16],[22,68],[44,60],[70,66],[84,94],[76,132],[46,152],
               [20,142],[14,124]]],
        "6": [[[74,20],[46,12],[26,34],[18,80],[18,120],[32,148],[58,152],[76,132],
               [78,102],[60,84],[34,86],[19,104]]],
        "7": [[[16,18],[84,18],[46,150]]],
        "8": [[[50,80],[28,66],[22,42],[38,18],[62,18],[78,40],[70,66],[50,80],
               [26,94],[16,122],[34,150],[64,150],[84,124],[74,94],[50,80]]],
        "9": [[[80,74],[64,90],[38,88],[22,68],[26,36],[48,16],[72,22],[82,50],
               [82,100],[72,138],[46,152],[24,144]]],
        ":": [[[50,52],[50,58]], [[50,112],[50,118]]]
    })

    Row {
        id: row
        anchors.centerIn: parent
        spacing: clock.spacing

        Repeater {
            model: clock.text.length

            Item {
                id: cell
                required property int index

                readonly property string glyph: clock.text.charAt(index)
                readonly property bool separator: glyph === ":"

                width: separator ? clock.glyphWidth * 0.4 : clock.glyphWidth
                height: clock.glyphHeight
                anchors.verticalCenter: parent.verticalCenter

                property real progress: 0

                onGlyphChanged: write.restart()
                Component.onCompleted: {
                    write.delay = index * 130;
                    write.restart();
                }

                SequentialAnimation {
                    id: write
                    property int delay: 0

                    PauseAnimation { duration: write.delay }
                    ScriptAction { script: cell.progress = 0 }
                    NumberAnimation {
                        target: cell
                        property: "progress"
                        from: 0
                        to: 1
                        duration: clock.writeDuration
                        easing.type: Easing.InOutSine
                    }
                    onStarted: write.delay = 0
                }

                onProgressChanged: canvas.requestPaint()

                Canvas {
                    id: canvas
                    anchors.fill: parent
                    renderStrategy: Canvas.Cooperative

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();

                        const strokes = clock.glyphs[cell.glyph];
                        if (!strokes)
                            return;

                        const sx = width / 100;
                        const sy = height / 160;

                        function smooth(points) {
                            if (points.length < 3) return points.slice();
                            const out = [];
                            for (let i = 0; i < points.length - 1; i++) {
                                const p0 = points[Math.max(0, i - 1)];
                                const p1 = points[i];
                                const p2 = points[i + 1];
                                const p3 = points[Math.min(points.length - 1, i + 2)];
                                for (let s = 0; s < 8; s++) {
                                    const t = s / 8;
                                    const t2 = t * t;
                                    const t3 = t2 * t;
                                    out.push([
                                        0.5 * ((2 * p1[0]) + (-p0[0] + p2[0]) * t
                                             + (2*p0[0] - 5*p1[0] + 4*p2[0] - p3[0]) * t2
                                             + (-p0[0] + 3*p1[0] - 3*p2[0] + p3[0]) * t3),
                                        0.5 * ((2 * p1[1]) + (-p0[1] + p2[1]) * t
                                             + (2*p0[1] - 5*p1[1] + 4*p2[1] - p3[1]) * t2
                                             + (-p0[1] + 3*p1[1] - 3*p2[1] + p3[1]) * t3)
                                    ]);
                                }
                            }
                            out.push(points[points.length - 1]);
                            return out;
                        }

                        const curves = strokes.map(smooth);

                        let total = 0;
                        const lengths = [];
                        for (const c of curves) {
                            let len = 0;
                            for (let i = 1; i < c.length; i++) {
                                const dx = (c[i][0] - c[i-1][0]) * sx;
                                const dy = (c[i][1] - c[i-1][1]) * sy;
                                len += Math.sqrt(dx * dx + dy * dy);
                            }
                            lengths.push(len);
                            total += len;
                        }
                        if (total <= 0)
                            return;

                        let budget = total * cell.progress;

                        ctx.strokeStyle = clock.color;
                        ctx.lineWidth = clock.thickness;
                        ctx.lineCap = "round";
                        ctx.lineJoin = "round";

                        for (let ci = 0; ci < curves.length; ci++) {
                            if (budget <= 0) break;
                            const c = curves[ci];

                            ctx.beginPath();
                            ctx.moveTo(c[0][0] * sx, c[0][1] * sy);

                            for (let i = 1; i < c.length; i++) {
                                const x1 = c[i-1][0] * sx, y1 = c[i-1][1] * sy;
                                const x2 = c[i][0] * sx,   y2 = c[i][1] * sy;
                                const seg = Math.sqrt((x2-x1)*(x2-x1) + (y2-y1)*(y2-y1));

                                if (seg <= budget) {
                                    ctx.lineTo(x2, y2);
                                    budget -= seg;
                                } else {
                                    const t = seg > 0 ? budget / seg : 0;
                                    ctx.lineTo(x1 + (x2 - x1) * t,
                                               y1 + (y2 - y1) * t);
                                    budget = 0;
                                    break;
                                }
                            }
                            ctx.stroke();
                        }
                    }
                }
            }
        }
    }
}
