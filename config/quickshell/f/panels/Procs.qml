import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
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

    property var groups: []
    property real memTotal: 1
    property string key: ""
    property string query: ""
    property bool busy: false
    property string note: ""
    property var hist: ({})
    property int beat: 0
    readonly property int depth: 48

    readonly property var hero: root.find(root.key)
    readonly property int index: root.indexOf(root.key)

    function toggle() { root.shown = !root.shown; }
    function close() { root.shown = false; }
    function hold(on) { on ? charge.start() : charge.stop(); }
    property bool pickCpu: false
    function openHeaviest() {
        root.shown = true;
        root.pickCpu = true;
    }

    function find(k) {
        for (let i = 0; i < root.groups.length; i++)
            if (root.groups[i].key === k)
                return root.groups[i];
        return null;
    }

    function indexOf(k) {
        for (let i = 0; i < root.groups.length; i++)
            if (root.groups[i].key === k)
                return i;
        return -1;
    }

    function neighbour(dir) {
        const n = root.groups.length;
        if (n === 0)
            return null;
        const i = root.index < 0 ? 0 : (root.index + dir + n) % n;
        return root.groups[i];
    }

    function step(dir) {
        if (root.busy || root.groups.length < 2)
            return;
        const g = root.neighbour(dir);
        if (g && g.key !== root.key) {
            Sfx.tick();
            hop.go(dir, g.key);
        }
    }

    function match(q) {
        q = q.trim().toLowerCase();
        if (q === "")
            return null;
        let best = null, bestScore = 0;
        for (const g of root.groups) {
            const hay = [g.key, g.cls, root.label(g), g.title].map(s => (s || "").toLowerCase());
            let s = 0;
            if (hay[0].startsWith(q) || hay[2].startsWith(q)) s = 3;
            else if (hay[1].startsWith(q)) s = 2.5;
            else if (hay.slice(0, 3).some(h => h.includes(q))) s = 2;
            else if (hay[3].includes(q)) s = 1;
            if (s > bestScore) {
                best = g;
                bestScore = s;
            }
        }
        return best;
    }

    onQueryChanged: {
        const g = root.match(root.query);
        if (g && g.key !== root.key)
            hop.go(root.index >= 0 && root.indexOf(g.key) < root.index ? -1 : 1, g.key);
    }

    function names(g) {
        const k = g.key.toLowerCase();
        const bare = k.replace(/[-_]?(web)?helper$/, "").replace(/[-_]?(bin|app|desktop|daemon)$/, "");
        const head = k.split(/[-_.]/)[0];
        return [g.cls, g.key, bare, head].filter((v, i, a) => v && a.indexOf(v) === i);
    }

    function entry(g) {
        if (!g)
            return null;
        for (const n of root.names(g)) {
            const e = DesktopEntries.heuristicLookup(n);
            if (e)
                return e;
        }
        return null;
    }

    function label(g) {
        const e = root.entry(g);
        return e && e.name ? e.name : (g ? g.key : "");
    }

    function icon(g) {
        if (!g)
            return "";
        const e = root.entry(g);
        const tries = [e ? e.icon : ""].concat(root.names(g).map(n => n.toLowerCase()));
        for (const t of tries) {
            if (!t)
                continue;
            if (t.startsWith("/"))
                return "file://" + t;
            const p = Quickshell.iconPath(t, true);
            if (p !== "")
                return p;
        }
        return Quickshell.iconPath("application-x-executable");
    }

    function mem(b) {
        const mb = b / 1048576;
        return mb < 1000 ? Math.round(mb) + " MB" : (mb / 1024).toFixed(mb < 10240 ? 1 : 0) + " GB";
    }

    function age(s) {
        if (s < 60) return I18n.t("procs.now");
        if (s < 3600) return Math.floor(s / 60) + " " + I18n.t("procs.min");
        if (s < 86400) return Math.floor(s / 3600) + " " + I18n.t("procs.hour");
        return Math.floor(s / 86400) + " " + I18n.t("procs.day");
    }

    function kill() {
        const g = root.hero;
        if (!g || g.prot || root.busy)
            return;
        root.busy = true;
        reaper.target = g.key;
        reaper.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/system/procs.py", "kill", g.key];
        reaper.running = true;
    }

    function finished(res) {
        if (res.error || res.left > 0) {
            Sfx.isleFail();
            root.note = res.error === "protected" ? I18n.t("procs.system") : I18n.t("procs.failed");
            root.busy = false;
            noteTimer.restart();
            return;
        }
        Sfx.isleOk();
        root.query = "";
        root.note = res.forced > 0 ? I18n.t("procs.forced") : "";
        if (root.note !== "")
            noteTimer.restart();
        const next = root.neighbour(1);
        root.groups = root.groups.filter(g => g.key !== res.key);
        root.busy = false;
        hop.go(1, next && next.key !== res.key ? next.key : (root.groups[0] ? root.groups[0].key : ""));
    }

    Timer { id: noteTimer; interval: 2600; onTriggered: root.note = "" }

    Process {
        id: feed
        running: root.shown
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/system/procs.py"]
        stdout: SplitParser {
            onRead: function (line) {
                let d;
                try {
                    d = JSON.parse(line);
                } catch (e) {
                    return;
                }
                root.memTotal = d.memTotal || 1;
                const gone = reaper.running ? reaper.target : "";
                root.groups = (d.groups || []).filter(g => g.key !== gone);
                const h = {};
                for (const g of root.groups) {
                    const prev = root.hist[g.key];
                    const a = prev ? prev.slice(1 - root.depth) : new Array(root.depth - 1).fill(g.cpu);
                    a.push(g.cpu);
                    h[g.key] = a;
                }
                root.hist = h;
                root.beat++;
                if (root.key === "" && root.groups.length) {
                    let top = root.groups[0];
                    if (root.pickCpu)
                        for (const g of root.groups)
                            if (!g.prot && g.cpu > top.cpu)
                                top = g;
                    root.pickCpu = false;
                    root.key = top.key;
                }
                else if (!root.find(root.key) && !hop.running && !root.busy && root.groups.length)
                    hop.go(1, root.groups[0].key);
            }
        }
    }

    Process {
        id: reaper
        property string target: ""
        stdout: SplitParser {
            onRead: function (line) {
                try {
                    root.finished(JSON.parse(line));
                } catch (e) {
                    root.busy = false;
                }
            }
        }
        onExited: (code) => { if (code !== 0) root.busy = false; }
    }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (root.shown) {
            closeDelay.stop();
            root.key = "";
            root.query = "";
            root.note = "";
            root.groups = [];
            root.hist = {};
        } else {
            closeDelay.restart();
        }
    }

    Timer { id: closeDelay; interval: 760 }

    QtObject {
        id: hop
        property bool running: anim.running
        property int dir: 1
        property string next: ""
        function go(d, k) {
            if (k === root.key && !anim.running)
                return;
            hop.dir = d;
            hop.next = k;
            anim.restart();
        }
    }

    property real slide: 0
    property real fade: 1

    SequentialAnimation {
        id: anim
        ParallelAnimation {
            NumberAnimation { target: root; property: "slide"; to: -hop.dir * 34; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: root; property: "fade"; to: 0; duration: 150; easing.type: Easing.InCubic }
        }
        ScriptAction {
            script: {
                root.key = hop.next;
                charge.reset();
                root.slide = hop.dir * 34;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: root; property: "slide"; to: 0; duration: 340; easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "fade"; to: 1; duration: 300; easing.type: Easing.OutCubic }
        }
    }

    QtObject {
        id: charge
        property real p: 0
        property int handle: -1
        property bool held: false

        function start() {
            if (!root.hero || root.busy || anim.running)
                return;
            if (root.hero.prot) {
                Sfx.toggleOff();
                root.note = I18n.t("procs.system");
                noteTimer.restart();
                return;
            }
            charge.held = true;
            drain.stop();
            charge.handle = Sfx.loop(Sfx.serp + "reusables/fillbutton/charge_loop.wav", 0.4);
            fill.restart();
        }

        function stop() {
            if (!charge.held)
                return;
            charge.held = false;
            if (fill.running) {
                fill.stop();
                Sfx.toggleOff();
                drain.restart();
            }
            Sfx.stop(charge.handle);
            charge.handle = -1;
        }

        function reset() {
            fill.stop();
            drain.stop();
            charge.held = false;
            charge.p = 0;
        }
    }

    NumberAnimation {
        id: fill
        target: charge
        property: "p"
        to: 1
        duration: 900 * (1 - charge.p)
        easing.type: Easing.InOutSine
        onFinished: {
            Sfx.stop(charge.handle);
            charge.handle = -1;
            charge.held = false;
            Sfx.tapAlt();
            root.kill();
        }
    }

    NumberAnimation {
        id: drain
        target: charge
        property: "p"
        to: 0
        duration: 360
        easing.type: Easing.OutCubic
    }

    Loader {
        active: root.shown || closeDelay.running

        sourceComponent: Component {
            PanelWindow {
                id: win
                WlrLayershell.namespace: "qs-procs"
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

                readonly property var g: root.hero
                readonly property real load: g ? Math.min(1, g.cpu / 60) : 0
                property real sLoad: win.load
                Behavior on sLoad { NumberAnimation { duration: 900; easing.type: Easing.InOutCubic } }

                readonly property color tone: {
                    const hot = Colors.mix(Colors.accent, Colors.warn, Math.min(1, win.sLoad * 1.4));
                    return Colors.mix(hot, Colors.bad, charge.p);
                }

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
                    cardW: 560
                    cardH: 430
                    radius: 34
                    glow: win.tone

                    MouseArea {
                        anchors.fill: parent
                        onWheel: (wheel) => root.step(wheel.angleDelta.y < 0 || wheel.angleDelta.x < 0 ? 1 : -1)
                    }

                    TextInput {
                        id: search
                        width: 1
                        height: 1
                        opacity: 0
                        focus: true
                        text: root.query
                        onTextChanged: root.query = search.text
                        Connections {
                            target: root
                            function onQueryChanged() {
                                if (search.text !== root.query)
                                    search.text = root.query;
                            }
                        }
                        Component.onCompleted: forceActiveFocus()

                        Keys.onPressed: (event) => {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                if (!event.isAutoRepeat)
                                    charge.start();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Escape) {
                                if (search.text !== "")
                                    search.text = "";
                                else
                                    root.close();
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Up) {
                                root.step(-1);
                                event.accepted = true;
                            } else if (event.key === Qt.Key_Right || event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                                root.step(1);
                                event.accepted = true;
                            }
                        }
                        Keys.onReleased: (event) => {
                            if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && !event.isAutoRepeat) {
                                charge.stop();
                                event.accepted = true;
                            }
                        }
                    }

                    Text {
                        anchors.top: parent.top
                        anchors.topMargin: 22
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.query !== "" ? root.query : I18n.t("procs.type")
                        color: root.query !== "" ? Colors.alpha(Colors.fg, 0.8) : Colors.alpha(Colors.fgDim, 0.32)
                        font.family: Fonts.mono
                        font.pixelSize: Fonts.small
                        font.letterSpacing: root.query !== "" ? 1 : 3
                        Behavior on color { ColorAnimation { duration: 240 } }
                    }

                    Repeater {
                        model: [-1, 1]
                        delegate: Item {
                            id: ghost
                            required property int modelData
                            readonly property var g: root.groups.length > 2 || (root.groups.length === 2 && modelData === 1)
                                                     ? root.neighbour(modelData) : null
                            width: 44
                            height: 44
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: -24
                            x: modelData < 0 ? 30 : parent.width - 30 - width
                            opacity: ghost.g && !root.busy ? (ghostHover.hovered ? 0.7 : 0.22) * root.fade : 0
                            Behavior on opacity { NumberAnimation { duration: 260 } }

                            IconImage {
                                anchors.centerIn: parent
                                implicitSize: 34
                                source: root.icon(ghost.g)
                                asynchronous: true
                            }
                            HoverHandler { id: ghostHover }
                            TapHandler { onTapped: root.step(ghost.modelData) }
                        }
                    }

                    Item {
                        id: hero
                        anchors.fill: parent
                        opacity: root.fade * (root.busy ? 0.35 : 1)
                        Behavior on opacity { enabled: !anim.running; NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }
                        transform: Translate { x: root.slide }
                        visible: win.g !== null

                        property real t: 0
                        FrameAnimation {
                            running: drip.living && hero.visible
                            onTriggered: hero.t += frameTime * (0.6 + win.sLoad * 2.4)
                        }
                        readonly property real beat: 0.5 + 0.5 * Math.sin(hero.t * Math.PI)

                        Item {
                            id: graph
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 104

                            readonly property var cpu: win.g ? (root.hist[win.g.key] || []) : []
                            readonly property real step: graph.width / (root.depth - 3)

                            property real phase: 1
                            NumberAnimation on phase {
                                id: flow
                                from: 0
                                to: 1
                                duration: 1500
                                running: false
                            }
                            Connections {
                                target: root
                                function onBeatChanged() { flow.restart(); }
                            }

                            property real cpuPeak: Math.max(8, Math.max.apply(null, graph.cpu.concat([0])) * 1.25)
                            Behavior on cpuPeak { NumberAnimation { duration: 900; easing.type: Easing.InOutCubic } }

                            function curve(vals, peak, fill) {
                                const n = vals.length;
                                if (n < 2)
                                    return [];
                                const h = graph.height, top = 18;
                                const P = [];
                                for (let i = 0; i < n; i++)
                                {
                                    const x = graph.width - (n - 1 - i) * graph.step + (1 - graph.phase) * graph.step;
                                    const wave = 2.6 * Math.sin(x * 0.021 + hero.t * 1.3) + 1.4 * Math.sin(x * 0.047 - hero.t * 0.9);
                                    P.push(Qt.point(x, h - 10 - Math.min(1, vals[i] / peak) * (h - top - 8) + wave));
                                }
                                const out = [];
                                for (let i = 0; i < n - 1; i++) {
                                    const p0 = P[Math.max(0, i - 1)], p1 = P[i], p2 = P[i + 1], p3 = P[Math.min(n - 1, i + 2)];
                                    for (let k = 0; k < 6; k++) {
                                        const t = k / 6, t2 = t * t, t3 = t2 * t;
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

                            Vec.Shape {
                                anchors.fill: parent
                                preferredRendererType: Vec.Shape.CurveRenderer

                                Vec.ShapePath {
                                    strokeWidth: -1
                                    fillGradient: Vec.LinearGradient {
                                        x1: 0; y1: 0
                                        x2: 0; y2: graph.height
                                        GradientStop { position: 0.0; color: Colors.alpha(win.tone, 0.34) }
                                        GradientStop { position: 1.0; color: Colors.alpha(win.tone, 0.0) }
                                    }
                                    PathPolyline { path: graph.curve(graph.cpu, graph.cpuPeak, true) }
                                }
                                Vec.ShapePath {
                                    fillColor: "transparent"
                                    strokeColor: Colors.alpha(Qt.lighter(win.tone, 1.15), 0.95)
                                    strokeWidth: 2
                                    capStyle: Vec.ShapePath.RoundCap
                                    joinStyle: Vec.ShapePath.RoundJoin
                                    PathPolyline { path: graph.curve(graph.cpu, graph.cpuPeak, false) }
                                }
                            }

                            Rectangle {
                                readonly property var last: graph.cpu.length ? graph.cpu[graph.cpu.length - 1] : 0
                                visible: graph.cpu.length > 1
                                width: 7 + 3 * hero.beat
                                height: width
                                radius: width / 2
                                x: graph.width - 14 - width / 2
                                property real lvl: Math.min(1, last / graph.cpuPeak)
                                Behavior on lvl { NumberAnimation { duration: 1500; easing.type: Easing.InOutSine } }
                                readonly property real cx: graph.width - 14
                                y: graph.height - 10 - lvl * (graph.height - 26)
                                   + 2.6 * Math.sin(cx * 0.021 + hero.t * 1.3) + 1.4 * Math.sin(cx * 0.047 - hero.t * 0.9)
                                   - height / 2
                                color: Qt.lighter(win.tone, 1.3)

                                RectangularShadow {
                                    anchors.centerIn: parent
                                    width: 26
                                    height: 26
                                    radius: 13
                                    blur: 18
                                    color: Colors.alpha(win.tone, 0.6)
                                    z: -1
                                }
                            }
                        }

                        Item {
                            id: badge
                            width: 132
                            height: 132
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 52

                            RectangularShadow {
                                anchors.centerIn: parent
                                width: 70 + 30 * win.sLoad + 10 * hero.beat * win.sLoad
                                height: width
                                radius: width / 2
                                blur: 46 + 30 * win.sLoad
                                color: Colors.alpha(win.tone, 0.20 + 0.25 * win.sLoad + 0.35 * charge.p)
                            }

                            Canvas {
                                id: ring
                                anchors.fill: parent
                                antialiasing: true
                                readonly property real p: charge.p
                                onPChanged: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.reset();
                                    if (ring.p <= 0.001)
                                        return;
                                    ctx.lineWidth = 2.5;
                                    ctx.lineCap = "round";
                                    ctx.strokeStyle = Colors.bad;
                                    ctx.globalAlpha = Math.min(1, ring.p * 3);
                                    ctx.beginPath();
                                    ctx.arc(width / 2, height / 2, width / 2 - 4, -Math.PI / 2,
                                            -Math.PI / 2 + Math.PI * 2 * ring.p);
                                    ctx.stroke();
                                }
                            }

                            IconImage {
                                id: appIcon
                                anchors.centerIn: parent
                                implicitSize: 76
                                source: root.icon(win.g)
                                asynchronous: true
                                scale: (1 - 0.14 * charge.p) * (iconHover.hovered && !charge.held ? 1.04 : 1)
                                Behavior on scale { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }
                            }

                            HoverHandler { id: iconHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler {
                                id: press
                                onPressedChanged: press.pressed ? charge.start() : charge.stop()
                            }
                        }

                        Column {
                            anchors.top: badge.bottom
                            anchors.topMargin: 6
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 4
                            width: parent.width - 120

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideRight
                                text: root.label(win.g)
                                color: Colors.fg
                                font.family: Fonts.display
                                font.pixelSize: Fonts.larger
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideMiddle
                                text: win.g ? (win.g.title !== "" ? win.g.title
                                              : win.g.n + " " + I18n.plural("plural.proc", win.g.n)) : ""
                                color: Colors.alpha(Colors.fgDim, 0.55)
                                font.family: Fonts.display
                                font.pixelSize: Fonts.small
                            }

                            Item { width: 1; height: 12 }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: 34

                                Column {
                                    spacing: 0
                                    Row {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        spacing: 2
                                        RollText {
                                            id: cpuText
                                            text: win.g ? (win.g.cpu < 10 ? win.g.cpu.toFixed(1) : Math.round(win.g.cpu).toString()) : "0"
                                            color: Colors.fg
                                            family: Fonts.display
                                            pixelSize: Fonts.huge
                                            weight: Font.Light
                                        }
                                        Text {
                                            anchors.bottom: cpuText.bottom
                                            anchors.bottomMargin: 6
                                            text: "%"
                                            color: Colors.alpha(Colors.fg, 0.4)
                                            font.family: Fonts.display
                                            font.pixelSize: Fonts.medium
                                        }
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "CPU"
                                        color: Colors.alpha(Colors.fgDim, 0.45)
                                        font.family: Fonts.mono
                                        font.pixelSize: Fonts.tiny
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 4
                                    }
                                }

                                Column {
                                    spacing: 0
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        height: cpuText.height
                                        verticalAlignment: Text.AlignBottom
                                        bottomPadding: 4
                                        text: win.g ? root.mem(win.g.mem) : ""
                                        color: Colors.fg
                                        font.family: Fonts.display
                                        font.features: Fonts.nums
                                        font.pixelSize: Fonts.larger
                                        font.weight: Font.Light
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: "RAM"
                                        color: Colors.alpha(Colors.fgDim, 0.45)
                                        font.family: Fonts.mono
                                        font.pixelSize: Fonts.tiny
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 4
                                    }
                                }

                                Column {
                                    spacing: 0
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        height: cpuText.height
                                        verticalAlignment: Text.AlignBottom
                                        bottomPadding: 4
                                        text: win.g ? root.age(win.g.age) : ""
                                        color: Colors.fg
                                        font.family: Fonts.display
                                        font.features: Fonts.nums
                                        font.pixelSize: Fonts.larger
                                        font.weight: Font.Light
                                    }
                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: I18n.t("procs.up")
                                        color: Colors.alpha(Colors.fgDim, 0.45)
                                        font.family: Fonts.mono
                                        font.pixelSize: Fonts.tiny
                                        font.weight: Font.DemiBold
                                        font.letterSpacing: 4
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 30
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: root.note !== "" ? root.note
                            : root.busy ? I18n.t("procs.closing")
                            : win.g && win.g.prot ? "🔒  " + I18n.t("procs.system")
                            : root.groups.length ? (root.index + 1) + " / " + root.groups.length + "   ·   " + I18n.t("procs.hint")
                            : I18n.t("procs.loading")
                        color: root.note !== "" ? Colors.alpha(Colors.warn, 0.9) : Colors.alpha(Colors.fgDim, 0.4)
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
