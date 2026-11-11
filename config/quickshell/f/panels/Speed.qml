import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes as Vec
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property var screenOverride: null

    property string phase: "idle"
    property real live: 0
    property real prog: 0
    property var pings: []
    property var downs: []
    property var ups: []
    property var res: ({})
    property string where: ""
    property string err: ""
    property var last: null

    readonly property bool active: root.phase === "meta" || root.phase === "ping" || root.phase === "down" || root.phase === "up"
    readonly property string statePath: Quickshell.statePath("speedtest.json")
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/scripts/system/speedtest.py"
    readonly property real dlSecs: 10
    readonly property int samples: Math.round(root.dlSecs / 0.1)

    function toggle() { root.shown = !root.shown; }
    function close() { root.shown = false; }

    function start() {
        runner.running = false;
        root.phase = "meta";
        root.live = 0;
        root.prog = 0;
        root.pings = [];
        root.downs = [];
        root.ups = [];
        root.res = {};
        root.err = "";
        Sfx.fill();
        Qt.callLater(() => { runner.running = true; });
    }

    function stop() {
        runner.running = false;
        if (root.active)
            root.phase = "idle";
    }

    function put(k, v) {
        const r = Object.assign({}, root.res);
        r[k] = v;
        root.res = r;
    }

    function feed(line) {
        let d;
        try {
            d = JSON.parse(line);
        } catch (e) {
            return;
        }
        switch (d.t) {
        case "phase":
            root.phase = d.v;
            root.prog = 0;
            if (d.v !== "meta")
                Sfx.tick();
            break;
        case "meta":
            root.where = [d.colo, d.loc].filter(s => s).join(" · ");
            break;
        case "ping":
            root.live = d.v;
            root.prog = d.p;
            root.pings = root.pings.concat([d.v]);
            break;
        case "pingDone":
            root.put("ping", d.ping);
            root.put("jitter", d.jitter);
            break;
        case "down":
            root.live = d.v;
            root.prog = d.p;
            root.downs = root.downs.concat([d.v]);
            break;
        case "downDone":
            root.put("down", d.v);
            root.put("downLoaded", d.loaded);
            break;
        case "up":
            root.live = d.v;
            root.prog = d.p;
            root.ups = root.ups.concat([d.v]);
            break;
        case "upDone":
            root.put("up", d.v);
            root.put("upLoaded", d.loaded);
            break;
        case "done":
            root.phase = "done";
            root.live = d.down;
            root.prog = 1;
            Sfx.isleOk();
            root.remember(d);
            break;
        case "error":
            root.fail(d.v);
            break;
        }
    }

    function fail(msg) {
        root.phase = "error";
        root.err = msg || "";
        root.live = 0;
        Sfx.isleFail();
    }

    function remember(d) {
        root.last = { down: d.down, up: d.up, ping: d.ping, ts: d.ts };
        saver.setText(JSON.stringify(root.last));
    }

    function mbps(v) {
        if (v === undefined || v === null)
            return "—";
        if (v >= 1000)
            return (v / 1000).toFixed(v >= 10000 ? 0 : 2);
        return v < 10 ? v.toFixed(1) : Math.round(v).toString();
    }

    function unit(v) {
        return v >= 1000 ? I18n.t("speed.gbps") : I18n.t("speed.mbps");
    }

    function ms(v) {
        if (v === undefined || v === null)
            return "—";
        return v < 10 ? v.toFixed(1) : Math.round(v).toString();
    }

    function ago(ts) {
        const s = Date.now() / 1000 - ts;
        if (s < 3600) return Math.max(1, Math.round(s / 60)) + " " + I18n.t("procs.min");
        if (s < 86400) return Math.round(s / 3600) + " " + I18n.t("procs.hour");
        return Math.round(s / 86400) + " " + I18n.t("procs.day");
    }

    FileView {
        id: saver
        path: root.statePath
        blockLoading: true
        printErrors: false
        onLoaded: {
            try {
                root.last = JSON.parse(saver.text());
            } catch (e) {}
        }
    }

    Process {
        id: runner
        command: [root.script]
        stdout: SplitParser {
            onRead: line => root.feed(line)
        }
        onExited: (code) => {
            if (root.active)
                root.fail("");
        }
    }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (root.shown) {
            closeDelay.stop();
            if (!root.active)
                startDelay.restart();
        } else {
            startDelay.stop();
            root.stop();
            closeDelay.restart();
        }
    }

    Timer { id: startDelay; interval: 420; onTriggered: root.start() }
    Timer { id: closeDelay; interval: 760 }

    Loader {
        active: root.shown || closeDelay.running

        sourceComponent: Component {
            PanelWindow {
                id: win
                WlrLayershell.namespace: "qs-speed"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                screen: root.screenOverride || Focus.screen

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                exclusiveZone: -1
                color: "transparent"

                readonly property bool isUp: root.phase === "up"
                readonly property bool isPing: root.phase === "ping" || root.phase === "meta"

                property real upMix: win.isUp ? 1 : 0
                Behavior on upMix { NumberAnimation { duration: 900; easing.type: Easing.InOutCubic } }
                property real pingMix: win.isPing ? 1 : 0
                Behavior on pingMix { NumberAnimation { duration: 900; easing.type: Easing.InOutCubic } }
                property real badMix: root.phase === "error" ? 1 : 0
                Behavior on badMix { NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } }

                readonly property color downTone: Colors.accent
                readonly property color upTone: Colors.accentAlt
                readonly property color tone: {
                    const t = Colors.mix(win.downTone, win.upTone, win.upMix);
                    return Colors.mix(Colors.mix(t, Colors.fgDim, win.pingMix * 0.55), Colors.bad, win.badMix);
                }

                property real scaleMax: 100
                readonly property var tiers: [100, 300, 1000, 2500, 10000]
                function fitScale(v) {
                    for (const t of win.tiers)
                        if (v * 1.08 < t)
                            return t;
                    return win.tiers[win.tiers.length - 1];
                }
                Connections {
                    target: root
                    function onLiveChanged() {
                        if (!win.isPing) {
                            const want = win.fitScale(Math.max(root.live, root.res.down || 0, root.res.up || 0));
                            if (want > win.scaleMax || root.phase === "meta")
                                win.scaleMax = want;
                        }
                    }
                    function onPhaseChanged() {
                        if (root.phase === "meta")
                            win.scaleMax = 100;
                    }
                }
                property real sMax: win.scaleMax
                Behavior on sMax { NumberAnimation { duration: 1100; easing.type: Easing.InOutCubic } }

                function frac(v) {
                    return Math.max(0, Math.min(1, Math.log(1 + v) / Math.log(1 + win.sMax)));
                }

                property real shownVal: root.live
                Behavior on shownVal { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }

                readonly property real target: win.isPing ? root.prog * 0.999
                                              : root.phase === "error" || root.phase === "idle" ? 0
                                              : win.frac(root.live)
                property real arc: win.target
                Behavior on arc { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: root.shown ? 0.22 : 0
                    Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }
                }

                IsleDrip {
                    id: drip
                    anchors.fill: parent
                    open: root.shown
                    cardW: 580
                    cardH: 560
                    radius: 34
                    glow: win.tone

                    MouseArea { anchors.fill: parent }

                    Item {
                        id: keys
                        focus: true
                        Component.onCompleted: forceActiveFocus()
                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Escape) {
                                root.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space) {
                                if (!event.isAutoRepeat)
                                    root.active ? root.stop() : root.start();
                                event.accepted = true;
                            }
                        }
                    }

                    property real t: 0
                    FrameAnimation {
                        running: drip.living
                        onTriggered: drip.t += frameTime * (root.active ? 1.4 : 0.5)
                    }
                    readonly property real beat: 0.5 + 0.5 * Math.sin(drip.t * Math.PI)

                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 22
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.where !== "" ? "Cloudflare · " + root.where : "Cloudflare"
                        color: Colors.alpha(Colors.fgDim, 0.38)
                        font.family: Fonts.mono
                        font.pixelSize: Fonts.tiny
                        font.letterSpacing: 3
                    }

                    Item {
                        id: gauge
                        width: 320
                        height: 320
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 46

                        readonly property real cx: width / 2
                        readonly property real cy: height / 2
                        readonly property real r: 118
                        readonly property real a0: 135
                        readonly property real sweep: 270

                        readonly property real tipA: (gauge.a0 + gauge.sweep * win.arc) * Math.PI / 180
                        readonly property real tipX: gauge.cx + gauge.r * Math.cos(gauge.tipA)
                        readonly property real tipY: gauge.cy + gauge.r * Math.sin(gauge.tipA)

                        RectangularShadow {
                            anchors.centerIn: parent
                            width: 120 + 60 * win.arc + 14 * drip.beat * (root.active ? 1 : 0)
                            height: width
                            radius: width / 2
                            blur: 60 + 30 * win.arc
                            color: Colors.alpha(win.tone, 0.10 + 0.20 * win.arc)
                        }

                        Vec.Shape {
                            anchors.fill: parent
                            preferredRendererType: Vec.Shape.CurveRenderer

                            Vec.ShapePath {
                                fillColor: "transparent"
                                strokeColor: Colors.alpha(Colors.fg, 0.07)
                                strokeWidth: 14
                                capStyle: Vec.ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: gauge.cx; centerY: gauge.cy
                                    radiusX: gauge.r; radiusY: gauge.r
                                    startAngle: gauge.a0; sweepAngle: gauge.sweep
                                }
                            }
                            Vec.ShapePath {
                                fillColor: "transparent"
                                strokeColor: Colors.alpha(win.tone, 0.18)
                                strokeWidth: 26
                                capStyle: Vec.ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: gauge.cx; centerY: gauge.cy
                                    radiusX: gauge.r; radiusY: gauge.r
                                    startAngle: gauge.a0; sweepAngle: Math.max(0.01, gauge.sweep * win.arc)
                                }
                            }
                            Vec.ShapePath {
                                fillColor: "transparent"
                                strokeWidth: 14
                                capStyle: Vec.ShapePath.RoundCap
                                strokeColor: win.tone
                                PathAngleArc {
                                    centerX: gauge.cx; centerY: gauge.cy
                                    radiusX: gauge.r; radiusY: gauge.r
                                    startAngle: gauge.a0; sweepAngle: Math.max(0.01, gauge.sweep * win.arc)
                                }
                            }
                        }

                        Repeater {
                            model: {
                                const m = win.scaleMax;
                                if (m <= 100) return [0, 5, 10, 25, 50, 100];
                                if (m <= 300) return [0, 10, 50, 100, 200, 300];
                                if (m <= 1000) return [0, 10, 50, 100, 250, 500, 1000];
                                if (m <= 2500) return [0, 50, 100, 500, 1000, 2500];
                                return [0, 100, 500, 1000, 5000, 10000];
                            }
                            delegate: Text {
                                required property var modelData
                                readonly property real a: (gauge.a0 + gauge.sweep * win.frac(modelData)) * Math.PI / 180
                                readonly property real rr: gauge.r + 26
                                x: gauge.cx + rr * Math.cos(a) - width / 2
                                y: gauge.cy + rr * Math.sin(a) - height / 2
                                text: modelData >= 1000 ? (modelData / 1000) + "k" : modelData
                                color: Colors.alpha(Colors.fgDim, win.frac(modelData) <= win.arc + 0.001 && !win.isPing ? 0.6 : 0.22)
                                opacity: 1 - win.pingMix
                                font.family: Fonts.mono
                                font.features: Fonts.nums
                                font.pixelSize: Fonts.tiny
                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }

                        Rectangle {
                            visible: win.arc > 0.004
                            width: 8 + 3 * drip.beat
                            height: width
                            radius: width / 2
                            x: gauge.tipX - width / 2
                            y: gauge.tipY - height / 2
                            color: Qt.lighter(win.tone, 1.45)

                            RectangularShadow {
                                anchors.centerIn: parent
                                width: 30
                                height: 30
                                radius: 15
                                blur: 20
                                color: Colors.alpha(win.tone, 0.75)
                                z: -1
                            }
                        }

                        Column {
                            anchors.centerIn: parent
                            anchors.verticalCenterOffset: 6
                            spacing: 2

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: {
                                    switch (root.phase) {
                                    case "meta": return I18n.t("speed.connecting");
                                    case "ping": return I18n.t("speed.ping");
                                    case "down": return "↓  " + I18n.t("speed.down");
                                    case "up": return "↑  " + I18n.t("speed.up");
                                    case "done": return "↓  " + I18n.t("speed.down");
                                    case "error": return I18n.t("speed.error");
                                    default: return I18n.t("speed.ready");
                                    }
                                }
                                color: Colors.alpha(win.tone, 0.85)
                                font.family: Fonts.mono
                                font.pixelSize: Fonts.tiny
                                font.weight: Font.DemiBold
                                font.letterSpacing: 4
                            }

                            Text {
                                id: big
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: root.phase === "error" || root.phase === "idle" || root.phase === "meta" ? "—"
                                    : win.isPing ? root.ms(win.shownVal)
                                    : root.mbps(win.shownVal)
                                color: Colors.fg
                                font.family: Fonts.display
                                font.features: Fonts.nums
                                font.pixelSize: 74
                                font.weight: Font.Light
                                opacity: root.phase === "meta" ? 0.25 + 0.2 * drip.beat : 1
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: win.isPing ? I18n.t("speed.ms") : root.unit(win.shownVal)
                                color: Colors.alpha(Colors.fg, 0.4)
                                font.family: Fonts.display
                                font.pixelSize: Fonts.medium
                            }
                        }

                        HoverHandler { id: gaugeHover; cursorShape: Qt.PointingHandCursor }
                        TapHandler { onTapped: root.active ? root.stop() : root.start() }
                    }

                    Item {
                        id: graph
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: 120

                        readonly property real peak: Math.max(5, Math.max.apply(null, root.downs.concat(root.ups).concat([0])) * 1.15)
                        property real sPeak: graph.peak
                        Behavior on sPeak { NumberAnimation { duration: 900; easing.type: Easing.InOutCubic } }

                        function curve(vals, fill) {
                            const n = vals.length;
                            if (n < 2)
                                return [];
                            const h = graph.height, top = 14;
                            const step = graph.width / (root.samples - 1);
                            const P = [];
                            for (let i = 0; i < n; i++) {
                                const x = i * step;
                                const v = (vals[Math.max(0, i - 2)] + vals[Math.max(0, i - 1)] + 2 * vals[i] + vals[Math.min(n - 1, i + 1)] + vals[Math.min(n - 1, i + 2)]) / 6;
                                const wave = 1.8 * Math.sin(x * 0.024 + drip.t * 1.2) + 1.0 * Math.sin(x * 0.051 - drip.t * 0.8);
                                P.push(Qt.point(x, h - 8 - Math.min(1, v / graph.sPeak) * (h - top - 8) + wave));
                            }
                            const out = [];
                            for (let i = 0; i < n - 1; i++) {
                                const p0 = P[Math.max(0, i - 1)], p1 = P[i], p2 = P[i + 1], p3 = P[Math.min(n - 1, i + 2)];
                                for (let k = 0; k < 4; k++) {
                                    const t = k / 4, t2 = t * t, t3 = t2 * t;
                                    out.push(Qt.point(
                                        0.5 * (2 * p1.x + (-p0.x + p2.x) * t + (2 * p0.x - 5 * p1.x + 4 * p2.x - p3.x) * t2 + (-p0.x + 3 * p1.x - 3 * p2.x + p3.x) * t3),
                                        Math.min(h - 2, 0.5 * (2 * p1.y + (-p0.y + p2.y) * t + (2 * p0.y - 5 * p1.y + 4 * p2.y - p3.y) * t2 + (-p0.y + 3 * p1.y - 3 * p2.y + p3.y) * t3))));
                                }
                            }
                            out.push(P[n - 1]);
                            if (fill) {
                                out.push(Qt.point(P[n - 1].x, h + 2));
                                out.push(Qt.point(P[0].x, h + 2));
                            }
                            return out;
                        }

                        Repeater {
                            model: [
                                { key: "downs", tone: win.downTone },
                                { key: "ups", tone: win.upTone }
                            ]
                            delegate: Vec.Shape {
                                id: line
                                required property var modelData
                                readonly property var vals: root[modelData.key]
                                readonly property bool lead: (modelData.key === "ups") === win.isUp || root.phase === "done"
                                anchors.fill: parent
                                preferredRendererType: Vec.Shape.CurveRenderer
                                opacity: line.vals.length < 2 ? 0 : line.lead ? 1 : 0.35
                                Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutCubic } }

                                Vec.ShapePath {
                                    strokeWidth: -1
                                    fillGradient: Vec.LinearGradient {
                                        x1: 0; y1: 0
                                        x2: 0; y2: graph.height
                                        GradientStop { position: 0.0; color: Colors.alpha(line.modelData.tone, 0.26) }
                                        GradientStop { position: 1.0; color: Colors.alpha(line.modelData.tone, 0.0) }
                                    }
                                    PathPolyline { path: graph.curve(line.vals, true) }
                                }
                                Vec.ShapePath {
                                    fillColor: "transparent"
                                    strokeColor: Colors.alpha(Qt.lighter(line.modelData.tone, 1.15), 0.95)
                                    strokeWidth: 2
                                    capStyle: Vec.ShapePath.RoundCap
                                    joinStyle: Vec.ShapePath.RoundJoin
                                    PathPolyline { path: graph.curve(line.vals, false) }
                                }
                            }
                        }
                    }

                    Row {
                        id: stats
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: gauge.y + gauge.height - 18
                        spacing: 54

                        Repeater {
                            model: [
                                { k: "ping", label: "speed.ping", unit: "speed.ms", phase: "ping" },
                                { k: "down", label: "speed.down", unit: "", phase: "down" },
                                { k: "up", label: "speed.up", unit: "", phase: "up" }
                            ]
                            delegate: Column {
                                id: cell
                                required property var modelData
                                readonly property var v: root.res[modelData.k]
                                readonly property bool has: cell.v !== undefined && cell.v !== null
                                readonly property bool now: root.phase === modelData.phase
                                readonly property color tint: modelData.k === "up" ? win.upTone : modelData.k === "down" ? win.downTone : Colors.fg
                                spacing: 1
                                width: 108
                                opacity: cell.has ? 1 : cell.now ? 0.55 + 0.25 * drip.beat : 0.28
                                Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutCubic } }

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 4
                                    Text {
                                        id: num
                                        text: !cell.has ? "—" : cell.modelData.k === "ping" ? root.ms(cell.v) : root.mbps(cell.v)
                                        color: cell.has ? Colors.fg : Colors.fgDim
                                        font.family: Fonts.display
                                        font.features: Fonts.nums
                                        font.pixelSize: Fonts.giant - 4
                                        font.weight: Font.Light
                                        scale: cell.has ? 1 : 0.92
                                        Behavior on scale { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
                                    }
                                    Text {
                                        anchors.bottom: num.bottom
                                        anchors.bottomMargin: 6
                                        visible: cell.has
                                        text: cell.modelData.k === "ping" ? I18n.t("speed.ms") : root.unit(cell.v)
                                        color: Colors.alpha(Colors.fg, 0.38)
                                        font.family: Fonts.display
                                        font.pixelSize: Fonts.small
                                    }
                                }
                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 6
                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 6
                                        height: 6
                                        radius: 3
                                        color: cell.tint
                                        opacity: cell.modelData.k === "ping" ? 0 : 0.9
                                    }
                                    Text {
                                        text: I18n.t(cell.modelData.label)
                                        color: Colors.alpha(Colors.fgDim, 0.5)
                                        font.family: Fonts.mono
                                        font.pixelSize: Fonts.tiny
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 3
                                    }
                                }
                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    readonly property var sub: cell.modelData.k === "ping" ? root.res.jitter
                                                             : root.res[cell.modelData.k + "Loaded"]
                                    visible: cell.has && sub !== undefined && sub !== null
                                    text: cell.modelData.k === "ping" ? "± " + root.ms(sub) + " " + I18n.t("speed.ms")
                                                                      : "⏱ " + root.ms(sub) + " " + I18n.t("speed.ms")
                                    color: Colors.alpha(Colors.fgDim, 0.4)
                                    font.family: Fonts.mono
                                    font.features: Fonts.nums
                                    font.pixelSize: Fonts.tiny
                                }
                            }
                        }
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 18
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.active ? I18n.t("speed.hintStop")
                            : root.phase === "error" ? (root.err !== "" ? root.err + "   ·   " : "") + I18n.t("speed.hintAgain")
                            : root.last && root.phase !== "done"
                              ? I18n.t("speed.last") + " " + root.mbps(root.last.down) + " ↓  " + root.mbps(root.last.up) + " ↑   ·   " + root.ago(root.last.ts)
                            : I18n.t("speed.hintAgain")
                        color: root.phase === "error" ? Colors.alpha(Colors.bad, 0.85) : Colors.alpha(Colors.fgDim, 0.4)
                        font.family: Fonts.mono
                        font.features: Fonts.nums
                        font.pixelSize: Fonts.tiny
                        font.letterSpacing: 1
                        Behavior on color { ColorAnimation { duration: 260 } }
                    }
                }
            }
        }
    }
}
