import QtQuick
import QtQuick.Effects
import QtQuick.Shapes as Vec
import "root:/design"
import "root:/services"

Item {
    id: bat

    property bool open: false

    visible: opacity > 0.01
    opacity: bat.open ? 1 : 0
    scale: bat.open ? 1 : 0.97
    Behavior on opacity { NumberAnimation { duration: Motion.slow; easing.type: Easing.OutCubic } }
    Behavior on scale { NumberAnimation { duration: Motion.slow; easing.type: Easing.OutCubic } }

    readonly property color tone: Aula.charging ? Colors.good
        : Aula.battery >= 0 && Aula.battery <= 10 ? Colors.bad
        : Aula.battery >= 0 && Aula.battery <= 20 ? Colors.warn : Colors.accent

    property double now: Date.now() / 1000
    Timer {
        interval: 30000
        repeat: true
        running: bat.visible
        triggeredOnStart: true
        onTriggered: bat.now = Date.now() / 1000
    }

    readonly property var pts: {
        const h = (Aula.batHist || []).map(p => [p[0], p[1]]);
        if (Aula.battery >= 0) {
            const tail = Aula.batteryStale ? Aula.batteryAt : bat.now;
            if (!h.length || tail > h[h.length - 1][0])
                h.push([tail, Aula.battery]);
        }
        return h;
    }
    readonly property color mTone: Mouse.charging ? Colors.good
        : Mouse.known && Mouse.battery <= 5 ? Colors.bad
        : Mouse.known && Mouse.battery <= 20 ? Colors.warn : Colors.accentAlt

    readonly property var mPts: {
        const h = [];
        for (const q of Mouse.batHist || []) {
            if (h.length && Mouse.coarse)
                h.push([q[0], h[h.length - 1][1]]);
            h.push([q[0], q[1]]);
        }
        if (Mouse.known) {
            const tail = Mouse.batteryStale ? Mouse.batteryAt : bat.now;
            if (!h.length || tail > h[h.length - 1][0])
                h.push([tail, Mouse.battery]);
        }
        return h;
    }
    readonly property bool kEnough: bat.pts.length >= 2 && bat.pts[bat.pts.length - 1][0] - bat.pts[0][0] > 600
    readonly property bool mEnough: bat.mPts.length >= 2 && bat.mPts[bat.mPts.length - 1][0] - bat.mPts[0][0] > 600
    readonly property bool enough: bat.kEnough || bat.mEnough

    readonly property double t0: Math.min(bat.kEnough ? bat.pts[0][0] : bat.now,
                                          bat.mEnough ? bat.mPts[0][0] : bat.now)
    readonly property double tNow: bat.pts.length ? bat.pts[bat.pts.length - 1][0] : bat.now
    readonly property double mNow: bat.mPts.length ? bat.mPts[bat.mPts.length - 1][0] : bat.now
    readonly property real hrs: Aula.charging ? -1 : Aula.hoursLeft
    readonly property double tEnd: bat.hrs > 0 ? bat.tNow + bat.hrs * 3600 : bat.tNow
    readonly property double t1: Math.max(bat.t0 + 3600, bat.tNow + 0.08 * (bat.tNow - bat.t0),
                                          Math.min(bat.tEnd, bat.tNow + 0.5 * (bat.tNow - bat.t0)))
    function fcAt(sec) { return Aula.battery * Math.max(0, 1 - (sec - bat.tNow) / Math.max(1, bat.tEnd - bat.tNow)); }

    readonly property real rate: Aula.drainRate

    property real t: 0
    FrameAnimation {
        running: bat.visible && bat.enough
        onTriggered: bat.t += frameTime
    }
    readonly property real beat: 0.5 + 0.5 * Math.sin(bat.t * Math.PI)

    signal dismiss()

    Rectangle {
        anchors.fill: parent
        radius: Shape.card
        gradient: Gradient {
            GradientStop { position: 0.0; color: Colors.surface2 }
            GradientStop { position: 1.0; color: Colors.surface1 }
        }
        border.width: 1
        border.color: Colors.alpha(bat.tone, 0.18)

        Rectangle {
            anchors.fill: parent
            anchors.margins: 14
            radius: Shape.field
            color: Colors.step(Colors.bg, Colors.shadowTone, 0.5)
            opacity: 0.85
        }
    }

    RectangularShadow {
        visible: bat.enough
        x: graph.x + graph.width * 0.15
        y: graph.y + graph.height * 0.35
        width: graph.width * 0.7
        height: graph.height * 0.6
        radius: 40
        blur: 90
        color: Colors.alpha(bat.tone, 0.10 + 0.04 * bat.beat)
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.PointingHandCursor
        onClicked: bat.dismiss()
        onWheel: wheel => wheel.accepted = true
    }

    function span(sec) {
        const m = Math.round(sec / 60);
        if (m < 60)
            return m + I18n.t("aula.bat.m");
        const h = Math.floor(m / 60);
        if (h < 48)
            return h + I18n.t("aula.bat.h") + (h < 10 && m % 60 ? " " + (m % 60) + I18n.t("aula.bat.m") : "");
        return Math.floor(h / 24) + I18n.t("aula.bat.d") + " " + (h % 24) + I18n.t("aula.bat.h");
    }

    function stamp(sec) {
        const d = new Date(sec * 1000), today = new Date(bat.now * 1000);
        const loc = Qt.locale(I18n.lang === "ru" ? "ru_RU" : "en_GB");
        const days = Math.round((new Date(d).setHours(0, 0, 0, 0) - new Date(today).setHours(0, 0, 0, 0)) / 86400000);
        const hm = d.toLocaleTimeString(loc, "HH:mm");
        if (days === 0)
            return hm;
        if (days === -1)
            return I18n.t("aula.bat.yesterday") + " " + hm;
        if (days === 1)
            return I18n.t("aula.bat.tomorrow") + " " + hm;
        return d.toLocaleDateString(loc, "ddd") + " " + hm;
    }

    Column {
        id: head
        anchors { top: parent.top; left: parent.left; topMargin: 26; leftMargin: 32 }
        spacing: 2

        Row {
            spacing: 10

            Text {
                text: Aula.battery >= 0 ? Aula.battery + "%" : "—"
                color: Colors.fg
                font.family: Fonts.display
                font.pixelSize: Fonts.giant
                font.weight: Font.DemiBold
                font.features: Fonts.nums
                opacity: Aula.batteryStale ? 0.55 : 1
            }

            Text {
                anchors.baseline: parent.children[0].baseline
                text: Aula.charging ? "󰂄" : ""
                visible: Aula.charging
                color: Colors.good
                font.family: Fonts.glyph
                font.pixelSize: Fonts.large
            }
        }

        Text {
            text: {
                if (Aula.charging)
                    return I18n.t("aula.charging");
                const bits = [];
                if (bat.hrs >= 0)
                    bits.push(I18n.t("aula.bat.left").replace("%1", Aula.leftText(bat.hrs))
                              + (Aula.drainModel && Aula.drainModel.rough ? " " + I18n.t("aula.bat.rough") : ""));
                if (bat.rate > 0)
                    bits.push(bat.rate.toFixed(1) + I18n.t("aula.bat.perHour"));
                if (Aula.loadNow > 0.05 && Aula.rateAt(0) > 0 && Aula.battery > 0)
                    bits.push(I18n.t("aula.bat.dark").replace("%1", Aula.leftText(Aula.battery / Aula.rateAt(0))));
                if (Aula.batteryStale)
                    bits.push(I18n.t("aula.bat.seen").replace("%1", bat.stamp(Aula.batteryAt)));
                else if (bat.pts.length > 1)
                    bits.push(I18n.t("aula.bat.since").replace("%1", bat.span(bat.tNow - bat.pts[0][0])));
                return bits.join("  ·  ");
            }
            color: Colors.fgDim
            font.family: Fonts.mono
            font.pixelSize: Fonts.small
            font.features: Fonts.nums
        }
    }

    Column {
        anchors { top: parent.top; right: parent.right; topMargin: 26; rightMargin: 32 }
        spacing: 2
        visible: Mouse.found || Mouse.known
        opacity: Mouse.batteryStale || !Mouse.online ? 0.55 : 1

        Row {
            anchors.right: parent.right
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰍽"
                color: bat.mTone
                font.family: Fonts.glyph
                font.pixelSize: Fonts.larger
            }

            Text {
                text: Mouse.known ? (Mouse.coarse ? "~" : "") + Mouse.battery + "%" : "—"
                color: Colors.fg
                font.family: Fonts.display
                font.pixelSize: Fonts.huge
                font.weight: Font.DemiBold
                font.features: Fonts.nums
            }
        }

        Text {
            anchors.right: parent.right
            text: {
                const bits = [Mouse.shortName];
                if (Mouse.charging)
                    bits.push(I18n.t("aula.charging"));
                else if (!Mouse.online && Mouse.known)
                    bits.push(I18n.t("aula.bat.seen").replace("%1", bat.stamp(Mouse.batteryAt)));
                else if (Mouse.coarse)
                    bits.push(I18n.t("mouse.coarse"));
                return bits.join("  ·  ");
            }
            color: Colors.fgDim
            font.family: Fonts.mono
            font.pixelSize: Fonts.small
            font.features: Fonts.nums
        }
    }

    Item {
        id: graph
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom
                  leftMargin: 32; rightMargin: 32; bottomMargin: 40 }
        height: parent.height - head.height - 26 - 40 - 22

        readonly property real topY: 6
        readonly property real floorY: graph.height - 2

        function xOf(sec) { return (sec - bat.t0) / Math.max(1, bat.t1 - bat.t0) * graph.width; }
        function yOf(p) { return graph.floorY - p / 100 * (graph.floorY - graph.topY); }
        function wave(x) { return 1.6 * Math.sin(x * 0.021 + bat.t * 1.1) + 0.8 * Math.sin(x * 0.047 - bat.t * 0.8); }

        property real reveal: 0
        NumberAnimation on reveal {
            id: drawIn
            from: 0
            to: 1
            duration: 900
            easing.type: Easing.OutCubic
            running: false
        }
        Connections {
            target: bat
            function onOpenChanged() { if (bat.open) drawIn.restart(); }
        }

        function curve(p, fill) {
            const n = p.length;
            if (n < 2)
                return [];
            const P = p.map(q => {
                const x = graph.xOf(q[0]);
                return Qt.point(x, graph.yOf(q[1]) + graph.wave(x));
            });
            const lim = graph.xOf(p[n - 1][0]) * graph.reveal;
            const out = [];
            for (let i = 0; i < n - 1; i++) {
                const p0 = P[Math.max(0, i - 1)], p1 = P[i], p2 = P[i + 1], p3 = P[Math.min(n - 1, i + 2)];
                const lo = Math.min(p1.y, p2.y), hi = Math.max(p1.y, p2.y);
                const steps = Math.max(2, Math.min(24, Math.round((p2.x - p1.x) / 6)));
                for (let k = 0; k < steps; k++) {
                    const t = k / steps, t2 = t * t, t3 = t2 * t;
                    const x = p1.x + (p2.x - p1.x) * t;
                    if (x > lim)
                        break;
                    const y = 0.5 * (2 * p1.y + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2
                                     + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3);
                    out.push(Qt.point(x, Math.max(lo, Math.min(hi, y))));
                }
            }
            const last = P[n - 1];
            if (last.x <= lim)
                out.push(last);
            if (fill && out.length) {
                out.push(Qt.point(out[out.length - 1].x, graph.height + 2));
                out.push(Qt.point(out[0].x, graph.height + 2));
            }
            return out;
        }

        Repeater {
            model: [25, 50, 75, 100]
            Item {
                required property int modelData
                width: graph.width
                y: graph.yOf(modelData)

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Colors.alpha(Colors.outline, 0.10)
                }
                Text {
                    anchors { right: parent.right; bottom: parent.top; bottomMargin: 2 }
                    text: modelData + "%"
                    color: Colors.fgDim
                    opacity: 0.45
                    font.family: Fonts.mono
                    font.pixelSize: Fonts.tiny
                    font.features: Fonts.nums
                }
            }
        }

        Rectangle {
            visible: bat.enough
            width: 1
            height: graph.height
            x: Math.round(graph.xOf(bat.tNow))
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: Colors.alpha(bat.tone, 0.25) }
            }
        }

        Vec.Shape {
            anchors.fill: parent
            visible: bat.mEnough
            preferredRendererType: Vec.Shape.CurveRenderer

            Vec.ShapePath {
                strokeWidth: -1
                fillGradient: Vec.LinearGradient {
                    x1: 0; y1: 0
                    x2: 0; y2: graph.height
                    GradientStop { position: 0.0; color: Colors.alpha(bat.mTone, 0.18) }
                    GradientStop { position: 1.0; color: Colors.alpha(bat.mTone, 0.0) }
                }
                PathPolyline { path: graph.curve(bat.mEnough ? bat.mPts : [], true) }
            }
            Vec.ShapePath {
                fillColor: "transparent"
                strokeColor: Colors.alpha(Qt.lighter(bat.mTone, 1.1), 0.8)
                strokeWidth: 1.6
                capStyle: Vec.ShapePath.RoundCap
                joinStyle: Vec.ShapePath.RoundJoin
                PathPolyline { path: graph.curve(bat.mEnough ? bat.mPts : [], false) }
            }
        }

        Vec.Shape {
            anchors.fill: parent
            visible: bat.kEnough
            preferredRendererType: Vec.Shape.CurveRenderer

            Vec.ShapePath {
                strokeWidth: -1
                fillGradient: Vec.LinearGradient {
                    x1: 0; y1: 0
                    x2: 0; y2: graph.height
                    GradientStop { position: 0.0; color: Colors.alpha(bat.tone, 0.34) }
                    GradientStop { position: 1.0; color: Colors.alpha(bat.tone, 0.0) }
                }
                PathPolyline { path: graph.curve(bat.kEnough ? bat.pts : [], true) }
            }
            Vec.ShapePath {
                fillColor: "transparent"
                strokeColor: Colors.alpha(Qt.lighter(bat.tone, 1.15), 0.95)
                strokeWidth: 2
                capStyle: Vec.ShapePath.RoundCap
                joinStyle: Vec.ShapePath.RoundJoin
                PathPolyline { path: graph.curve(bat.kEnough ? bat.pts : [], false) }
            }
            Vec.ShapePath {
                fillColor: "transparent"
                strokeColor: Colors.alpha(bat.tone, 0.45 * graph.reveal)
                strokeWidth: 1.5
                strokeStyle: Vec.ShapePath.DashLine
                dashPattern: [3, 4]
                capStyle: Vec.ShapePath.RoundCap
                PathPolyline {
                    path: bat.hrs > 0 && Aula.battery > 0
                        ? [Qt.point(graph.xOf(bat.tNow), graph.yOf(Aula.battery)),
                           Qt.point(graph.xOf(Math.min(bat.tEnd, bat.t1)), graph.yOf(bat.fcAt(Math.min(bat.tEnd, bat.t1))))]
                        : []
                }
            }
        }

        Rectangle {
            id: dot
            visible: bat.kEnough && Aula.battery >= 0
            opacity: graph.reveal
            readonly property real cx: graph.xOf(bat.tNow)
            width: 7 + 3 * bat.beat
            height: width
            radius: width / 2
            x: cx - width / 2
            y: graph.yOf(Aula.battery) + graph.wave(cx) - height / 2
            color: Qt.lighter(bat.tone, 1.3)

            RectangularShadow {
                anchors.centerIn: parent
                width: 26
                height: 26
                radius: 13
                blur: 18
                color: Colors.alpha(bat.tone, 0.6)
                z: -1
            }
        }

        Rectangle {
            visible: bat.enough && Mouse.known
            opacity: graph.reveal * (Mouse.online ? 1 : 0.5)
            readonly property real cx: graph.xOf(bat.mNow)
            width: 6 + 2 * bat.beat
            height: width
            radius: width / 2
            x: cx - width / 2
            y: graph.yOf(Mouse.battery) + graph.wave(cx) - height / 2
            color: Qt.lighter(bat.mTone, 1.25)

            RectangularShadow {
                anchors.centerIn: parent
                width: 22
                height: 22
                radius: 11
                blur: 16
                color: Colors.alpha(bat.mTone, 0.5)
                z: -1
            }
        }

        Text {
            visible: bat.hrs > 0 && bat.kEnough
            opacity: 0.6 * graph.reveal
            x: Math.min(graph.width - width, graph.xOf(Math.min(bat.tEnd, bat.t1)) - width / 2)
            y: graph.height + 8
            text: "0% · " + bat.stamp(bat.tEnd)
            color: bat.tone
            font.family: Fonts.mono
            font.pixelSize: Fonts.tiny
            font.features: Fonts.nums
        }

        Text {
            visible: bat.enough
            opacity: 0.5
            x: 0
            y: graph.height + 8
            text: bat.stamp(bat.t0)
            color: Colors.fgDim
            font.family: Fonts.mono
            font.pixelSize: Fonts.tiny
            font.features: Fonts.nums
        }

        Text {
            visible: !bat.enough
            anchors.centerIn: parent
            width: parent.width * 0.7
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: Aula.charging ? I18n.t("aula.bat.charging") : I18n.t("aula.bat.empty")
            color: Colors.fgDim
            opacity: 0.7
            font.family: Fonts.mono
            font.pixelSize: Fonts.small
        }

        HoverHandler { id: scrub; enabled: bat.enough }

        Item {
            id: probe
            readonly property real px: scrub.point.position.x
            readonly property double sec: bat.t0 + px / Math.max(1, graph.width) * (bat.t1 - bat.t0)
            readonly property bool future: sec > bat.tNow
            readonly property real mPct: {
                const p = bat.mPts;
                if (!bat.mEnough || sec < p[0][0] || sec > bat.mNow)
                    return -1;
                let v = p[0][1];
                for (const q of p) {
                    if (q[0] > sec)
                        break;
                    v = q[1];
                }
                return v;
            }
            readonly property real pct: {
                const p = bat.pts;
                if (!p.length)
                    return -1;
                if (probe.future)
                    return bat.hrs > 0 ? bat.fcAt(sec) : -1;
                let v = p[0][1];
                for (const q of p) {
                    if (q[0] > sec)
                        break;
                    v = q[1];
                }
                return v;
            }
            readonly property real kPct: bat.kEnough && (sec >= bat.pts[0][0] || probe.future) ? probe.pct : -1
            visible: opacity > 0.01
            opacity: scrub.hovered && (probe.kPct >= 0 || probe.mPct >= 0) && px >= 0 && px <= graph.width ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }

            Rectangle {
                x: probe.px
                width: 1
                height: graph.height
                color: Colors.alpha(Colors.fg, 0.18)
            }

            Rectangle {
                visible: probe.kPct >= 0
                x: probe.px - width / 2
                y: graph.yOf(probe.pct) + (probe.future ? 0 : graph.wave(probe.px)) - height / 2
                width: 7
                height: 7
                radius: 4
                color: Colors.fg
                opacity: probe.future ? 0.5 : 0.9
            }

            Rectangle {
                x: Math.max(0, Math.min(graph.width - width, probe.px - width / 2))
                y: -26
                height: 22
                width: tip.implicitWidth + 18
                radius: height / 2
                color: Colors.alpha(Colors.bg, 0.88)
                border.width: 1
                border.color: Colors.alpha(bat.tone, 0.3)

                Text {
                    id: tip
                    anchors.centerIn: parent
                    text: {
                        const bits = [];
                        if (probe.kPct >= 0)
                            bits.push("󰌌 " + (probe.future ? "~" : "") + Math.round(probe.kPct) + "%");
                        if (probe.mPct >= 0)
                            bits.push("󰍽 " + (Mouse.coarse ? "~" : "") + Math.round(probe.mPct) + "%");
                        bits.push(bat.stamp(probe.sec));
                        return bits.join("  ·  ");
                    }
                    color: Colors.fg
                    font.family: Fonts.mono
                    font.pixelSize: Fonts.tiny
                    font.features: Fonts.nums
                }
            }
        }
    }
}
