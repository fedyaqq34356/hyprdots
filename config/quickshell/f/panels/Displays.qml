import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    function toggle() {
        if (root.phase === "confirm") {
            root.revert();
            return;
        }
        root.shown = !root.shown;
    }

    function close() {
        if (root.phase === "confirm")
            root.revert();
        root.shown = false;
    }

    property var live: []
    property var draft: []
    property var names: []
    property string sel: ""
    property string phase: "edit"
    property string note: ""

    readonly property var cur: root.find(root.sel, root.draft)

    function find(name, list) {
        for (const m of list)
            if (m.name === name)
                return m;
        return null;
    }

    function parse(text) {
        let rows;
        try {
            rows = JSON.parse(text);
        } catch (e) {
            return [];
        }
        return rows.map(r => {
            const modes = (r.availableModes || []).map(s => {
                const mm = /^(\d+)x(\d+)@([\d.]+)Hz$/.exec(s);
                return mm ? { w: +mm[1], h: +mm[2], hz: mm[3] } : null;
            }).filter(x => x);
            let hz = Number(r.refreshRate).toFixed(2);
            let best = 1e9;
            for (const m of modes) {
                const d = Math.abs(+m.hz - r.refreshRate);
                if (m.w === r.width && m.h === r.height && d < best) {
                    best = d;
                    hz = m.hz;
                }
            }
            return {
                name: r.name, desc: r.description || r.name,
                w: r.width, h: r.height, hz: hz,
                x: r.x, y: r.y, scale: Math.round(r.scale * 1e6) / 1e6,
                transform: r.transform || 0, on: !r.disabled,
                modes: modes.length > 0 ? modes : [{ w: r.width, h: r.height, hz: hz }]
            };
        });
    }

    function lw(m) { return (m.transform % 2 ? m.h : m.w) / m.scale; }
    function lh(m) { return (m.transform % 2 ? m.w : m.h) / m.scale; }

    function fmtScale(s) {
        const t = Math.round(s * 1e6) / 1e6;
        return String(t);
    }

    function rule(m) {
        if (!m.on)
            return m.name + ",disable";
        let r = m.name + "," + m.w + "x" + m.h + "@" + m.hz + ","
            + Math.round(m.x) + "x" + Math.round(m.y) + "," + root.fmtScale(m.scale);
        if (m.transform)
            r += ",transform," + m.transform;
        return r;
    }

    readonly property bool dirty: {
        if (root.draft.length !== root.live.length)
            return false;
        for (let i = 0; i < root.draft.length; i++)
            if (root.rule(root.draft[i]) !== root.rule(root.find(root.draft[i].name, root.live) || root.draft[i]))
                return true;
        return false;
    }

    function patch(name, fields) {
        root.draft = root.draft.map(m => m.name === name ? Object.assign({}, m, fields) : m);
    }

    readonly property var resolutions: {
        const m = root.cur;
        if (!m)
            return [];
        const seen = ({});
        const out = [];
        for (const x of m.modes) {
            const k = x.w + "x" + x.h;
            if (seen[k])
                continue;
            seen[k] = true;
            out.push({ w: x.w, h: x.h });
        }
        out.sort((a, b) => b.w * b.h - a.w * a.h);
        const top = out.slice(0, 5);
        if (!top.some(r => r.w === m.w && r.h === m.h))
            top.push({ w: m.w, h: m.h });
        return top;
    }

    readonly property var rates: {
        const m = root.cur;
        if (!m)
            return [];
        const seen = ({});
        const out = [];
        for (const x of m.modes) {
            if (x.w !== m.w || x.h !== m.h)
                continue;
            const k = Math.round(+x.hz);
            if (seen[k])
                continue;
            seen[k] = true;
            out.push(x.hz);
        }
        out.sort((a, b) => +b - +a);
        return out.slice(0, 5);
    }

    readonly property var scales: {
        const m = root.cur;
        if (!m)
            return [];
        const out = [];
        for (const s of [1, 1.25, 4 / 3, 1.5, 1.6, 5 / 3, 2, 2.5, 3]) {
            const a = m.w / s, b = m.h / s;
            if (Math.abs(a - Math.round(a)) < 0.01 && Math.abs(b - Math.round(b)) < 0.01)
                out.push(Math.round(s * 1e6) / 1e6);
        }
        if (!out.some(s => Math.abs(s - m.scale) < 1e-4))
            out.push(m.scale);
        return out.sort((a, b) => a - b).slice(0, 6);
    }

    function pickRes(r) {
        const m = root.cur;
        const same = m.modes.filter(x => x.w === r.w && x.h === r.h)
                            .sort((a, b) => Math.abs(+a.hz - +m.hz) - Math.abs(+b.hz - +m.hz));
        root.patch(m.name, { w: r.w, h: r.h, hz: same.length > 0 ? same[0].hz : m.hz });
        root.settle(m.name);
    }

    function pickOn(on) {
        const m = root.cur;
        if (!on && root.draft.filter(x => x.on && x.name !== m.name).length === 0) {
            root.say(I18n.t("disp.last"));
            return;
        }
        root.patch(m.name, { on: on });
        if (on)
            root.settle(m.name);
    }

    function say(t) {
        root.note = t;
        noteHide.restart();
    }
    Timer { id: noteHide; interval: 2600; onTriggered: root.note = "" }

    function overlaps(a, list) {
        for (const o of list) {
            if (a.x < o.x + o.w - 0.5 && a.x + a.w > o.x + 0.5
                && a.y < o.y + o.h - 0.5 && a.y + a.h > o.y + 0.5)
                return true;
        }
        return false;
    }

    function snap(name, px, py) {
        const me = root.find(name, root.draft);
        const w = root.lw(me), h = root.lh(me);
        const others = root.draft.filter(m => m.on && m.name !== name)
                                 .map(m => ({ x: m.x, y: m.y, w: root.lw(m), h: root.lh(m) }));
        if (others.length === 0)
            return { x: 0, y: 0 };

        const clamp = (v, a, b) => Math.max(a, Math.min(b, v));
        const cands = [];
        for (const o of others) {
            const ys = [o.y, o.y + o.h - h, o.y + (o.h - h) / 2, clamp(py, o.y - h + 1, o.y + o.h - 1)];
            const xs = [o.x, o.x + o.w - w, o.x + (o.w - w) / 2, clamp(px, o.x - w + 1, o.x + o.w - 1)];
            for (let i = 0; i < ys.length; i++) {
                cands.push({ x: o.x + o.w, y: ys[i], even: i < 3 });
                cands.push({ x: o.x - w, y: ys[i], even: i < 3 });
            }
            for (let i = 0; i < xs.length; i++) {
                cands.push({ x: xs[i], y: o.y + o.h, even: i < 3 });
                cands.push({ x: xs[i], y: o.y - h, even: i < 3 });
            }
        }

        let best = null, bd = 1e18;
        for (const c of cands) {
            const r = { x: Math.round(c.x), y: Math.round(c.y), w: w, h: h };
            if (root.overlaps(r, others))
                continue;
            const d = Math.hypot(r.x - px, r.y - py) - (c.even ? 150 : 0);
            if (d < bd) {
                bd = d;
                best = r;
            }
        }
        return best ? { x: best.x, y: best.y } : { x: me.x, y: me.y };
    }

    function settle(name) {
        const m = root.find(name, root.draft);
        if (!m || !m.on)
            return;
        const p = root.snap(name, m.x, m.y);
        root.patch(name, { x: p.x, y: p.y });
    }

    function normalized() {
        const on = root.draft.filter(m => m.on);
        if (on.length === 0)
            return root.draft;
        const mx = Math.min(...on.map(m => m.x));
        const my = Math.min(...on.map(m => m.y));
        return root.draft.map(m => m.on ? Object.assign({}, m, { x: m.x - mx, y: m.y - my }) : m);
    }

    property var backup: []
    property real remain: 0
    readonly property int wait: 12

    function apply() {
        if (!root.dirty)
            return;
        root.draft = root.normalized();
        root.backup = root.live.slice();
        const rules = root.draft.map(m => root.rule(m));
        rules.sort((a, b) => (a.endsWith(",disable") ? 1 : 0) - (b.endsWith(",disable") ? 1 : 0));
        root.run(rules);
        root.phase = "confirm";
        root.remain = root.wait;
        countdown.restart();
        Sfx.tapAlt();
    }

    function run(rules) {
        applier.running = false;
        applier.command = ["sh", "-c", 'for r in "$@"; do hyprdo keyword monitor "$r" >/dev/null 2>&1; done', "displays"]
            .concat(rules);
        applier.running = true;
    }

    function keep() {
        countdown.stop();
        root.phase = "edit";
        const lines = root.draft.map(m => {
            const parts = root.rule(m).split(",");
            if (!/^eDP/.test(m.name) && m.desc && m.desc !== m.name && m.desc.indexOf(",") < 0)
                parts[0] = "desc:" + m.desc;
            return "monitor = " + parts.join(", ");
        });
        lines.push("monitor = , preferred, auto, 1");
        writer.running = false;
        writer.command = ["sh", "-c", 'f="$HOME/.config/hypr/config/monitors.conf"; printf "%s\\n" "$@" > "$f.tmp" && mv "$f.tmp" "$f"', "displays"]
            .concat(lines);
        writer.running = true;
        Sfx.isleOk();
        refreshLater.restart();
    }

    function revert() {
        countdown.stop();
        root.phase = "edit";
        if (root.backup.length > 0)
            root.run(root.backup.map(m => root.rule(m)));
        refreshLater.restart();
    }

    Timer {
        id: countdown
        interval: 50
        repeat: true
        onTriggered: {
            root.remain = Math.max(0, root.remain - 0.05);
            if (root.remain <= 0)
                root.revert();
        }
    }

    Timer { id: refreshLater; interval: 700; onTriggered: root.reload() }

    Process { id: applier }
    Process { id: writer }

    Process {
        id: reader
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = root.parse(text);
                if (list.length === 0)
                    return;
                root.live = list;
                root.draft = list.map(m => Object.assign({}, m));
                root.names = list.map(m => m.name);
                if (!root.find(root.sel, list))
                    root.sel = (list.find(m => m.name === (Focus.screen ? Focus.screen.name : "")) || list[0]).name;
            }
        }
    }

    function reload() {
        reader.running = false;
        reader.running = true;
    }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (root.shown) {
            closeDelay.stop();
            root.phase = "edit";
            root.note = "";
            root.reload();
        } else {
            closeDelay.restart();
        }
    }

    Timer { id: closeDelay; interval: 760 }

    FileView {
        id: wallFile
        path: Quickshell.env("HOME") + "/.config/hypr/current-wallpaper"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string wall: {
        let p = "";
        try {
            p = wallFile.text().trim();
        } catch (e) {}
        return p !== "" ? "file://" + p : "";
    }

    component Seg: Item {
        id: seg

        property var labels: []
        property int index: -1
        signal picked(int i)

        implicitWidth: segRow.implicitWidth + 6
        implicitHeight: 30

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.05)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)
        }

        Rectangle {
            id: lit
            readonly property Item at: seg.index >= 0 && seg.index < segRep.count ? segRep.itemAt(seg.index) : null
            visible: lit.at !== null
            x: lit.at ? segRow.x + lit.at.x : 0
            width: lit.at ? lit.at.width : 0
            y: 3
            height: seg.height - 6
            radius: height / 2
            color: Colors.alpha(Colors.accent, 0.22)
            border.width: 1
            border.color: Colors.alpha(Colors.accent, 0.45)
            Behavior on x { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
            Behavior on width { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        }

        Row {
            id: segRow
            x: 3
            height: seg.height

            Repeater {
                id: segRep
                model: seg.labels

                Item {
                    id: cell
                    required property int index
                    required property string modelData
                    width: cellText.implicitWidth + 24
                    height: segRow.height

                    Text {
                        id: cellText
                        anchors.centerIn: parent
                        text: cell.modelData
                        color: cell.index === seg.index ? "white" : Qt.rgba(1, 1, 1, 0.55)
                        font.family: Fonts.display
                        font.pixelSize: 12
                        font.weight: cell.index === seg.index ? Font.DemiBold : Font.Medium
                        font.features: { "tnum": 1 }
                        Behavior on color { ColorAnimation { duration: 240 } }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (cell.index !== seg.index) {
                                Sfx.tap();
                                seg.picked(cell.index);
                            }
                        }
                    }
                }
            }
        }
    }

    component Pill: Rectangle {
        id: pill
        property string text: ""
        property string glyph: ""
        property bool strong: false
        property bool enabledish: true
        signal hit()

        implicitWidth: pillRow.implicitWidth + 28
        implicitHeight: 32
        radius: 16
        opacity: pill.enabledish ? 1 : 0.35
        color: pill.strong ? Colors.alpha(Colors.accent, pillArea.containsMouse ? 0.34 : 0.26)
                           : Qt.rgba(1, 1, 1, pillArea.containsMouse ? 0.10 : 0.06)
        border.width: 1
        border.color: pill.strong ? Colors.alpha(Colors.accent, 0.55) : Qt.rgba(1, 1, 1, 0.10)
        Behavior on color { ColorAnimation { duration: 160 } }
        Behavior on opacity { NumberAnimation { duration: 240 } }

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 7
            Text {
                visible: pill.glyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pill.glyph
                color: pill.strong ? Qt.lighter(Colors.accent, 1.35) : Qt.rgba(1, 1, 1, 0.8)
                font.family: Fonts.glyph
                font.pixelSize: 13
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: pill.text
                color: pill.strong ? Qt.lighter(Colors.accent, 1.35) : Qt.rgba(1, 1, 1, 0.85)
                font.family: Fonts.display
                font.pixelSize: 12
                font.weight: Font.DemiBold
            }
        }

        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: pill.enabledish
            cursorShape: Qt.PointingHandCursor
            onClicked: pill.hit()
        }
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: tag
            required property var modelData
            screen: modelData

            readonly property bool want: root.shown && root.phase === "edit"
                                         && !(Focus.screen && Focus.screen.name === tag.modelData.name)
            visible: tag.want || tagBody.opacity > 0.01

            WlrLayershell.namespace: "qs-displays-tag"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusiveZone: -1
            color: "transparent"
            anchors { top: true; bottom: true; left: true; right: true }
            mask: Region {}

            readonly property var mon: root.find(tag.modelData.name, root.draft)
            readonly property bool chosen: root.sel === tag.modelData.name

            Item {
                id: tagBody
                anchors.centerIn: parent
                width: 420
                height: 170
                opacity: tag.want ? 1 : 0
                scale: tag.want ? 1 : 0.96
                Behavior on opacity { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }
                Behavior on scale { NumberAnimation { duration: 620; easing.type: Easing.OutCubic } }

                RectangularShadow {
                    anchors.centerIn: parent
                    width: parent.width
                    height: parent.height
                    radius: 60
                    blur: 90
                    spread: -10
                    color: Qt.rgba(0, 0, 0, 0.55)
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tag.modelData.name
                        color: tag.chosen ? Qt.lighter(Colors.accent, 1.3) : "white"
                        font.family: Fonts.display
                        font.pixelSize: 54
                        font.weight: Font.Bold
                        Behavior on color { ColorAnimation { duration: 400 } }
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tag.mon ? tag.mon.desc : ""
                        color: Qt.rgba(1, 1, 1, 0.62)
                        font.family: Fonts.display
                        font.pixelSize: 15
                    }
                }
            }
        }
    }

    Loader {
        active: root.shown || closeDelay.running

        sourceComponent: Component {
            PanelWindow {
                id: win
                WlrLayershell.namespace: "qs-displays"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                screen: Focus.screen

                anchors { top: true; bottom: true; left: true; right: true }
                exclusiveZone: -1
                color: "transparent"

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                FocusScope {
                    anchors.fill: parent
                    focus: true
                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: root.phase === "confirm" ? root.keep() : root.apply()
                    Component.onCompleted: forceActiveFocus()
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
                    cardW: 620
                    cardH: root.phase === "confirm" ? 300 : body.height + 56
                    radius: 34
                    glow: Colors.accent

                    MouseArea { anchors.fill: parent }

                    Column {
                        id: body
                        anchors.top: parent.top
                        anchors.topMargin: 26
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 620 - 56
                        spacing: 16

                        opacity: root.phase === "edit" ? 1 : 0
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: 360; easing.type: Easing.InOutCubic } }

                        Item {
                            width: parent.width
                            height: titleText.height

                            Text {
                                id: titleText
                                text: I18n.t("disp.title")
                                color: Colors.alpha(Colors.fgDim, 0.55)
                                font.family: Fonts.mono
                                font.pixelSize: Fonts.tiny
                                font.weight: Font.DemiBold
                                font.letterSpacing: 3
                            }
                            Text {
                                anchors.right: parent.right
                                text: root.note !== "" ? root.note : I18n.t("disp.drag")
                                color: root.note !== "" ? Colors.warn : Qt.rgba(1, 1, 1, 0.32)
                                font.family: Fonts.display
                                font.pixelSize: 11
                                Behavior on color { ColorAnimation { duration: 240 } }
                            }
                        }

                        Item {
                            id: stage
                            width: parent.width
                            height: 270

                            Rectangle {
                                anchors.fill: parent
                                radius: 22
                                color: Qt.rgba(1, 1, 1, 0.025)
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.06)
                            }

                            Canvas {
                                anchors.fill: parent
                                anchors.margins: 1
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    ctx.fillStyle = "rgba(255,255,255,0.07)";
                                    for (let x = 14; x < width; x += 18)
                                        for (let y = 14; y < height; y += 18)
                                            ctx.fillRect(x, y, 1.4, 1.4);
                                }
                            }

                            property bool holding: false
                            readonly property real pad: 20
                            readonly property var box: {
                                const list = root.draft;
                                if (list.length === 0)
                                    return { x: 0, y: 0, w: 1, h: 1 };
                                const x0 = Math.min(...list.map(m => m.x));
                                const y0 = Math.min(...list.map(m => m.y));
                                const x1 = Math.max(...list.map(m => m.x + root.lw(m)));
                                const y1 = Math.max(...list.map(m => m.y + root.lh(m)));
                                return { x: x0, y: y0, w: Math.max(1, x1 - x0), h: Math.max(1, y1 - y0) };
                            }
                            property real k: 0.1
                            property real ox: 0
                            property real oy: 0
                            function fit() {
                                const b = stage.box;
                                const k = Math.min((stage.width - 2 * stage.pad) / b.w,
                                                   (stage.height - 2 * stage.pad) / b.h, 0.16);
                                stage.k = k;
                                stage.ox = (stage.width - b.w * k) / 2 - b.x * k;
                                stage.oy = (stage.height - b.h * k) / 2 - b.y * k;
                            }
                            onBoxChanged: if (!stage.holding) stage.fit()
                            onWidthChanged: stage.fit()
                            onHoldingChanged: if (!stage.holding) stage.fit()

                            Behavior on k { enabled: !stage.holding; NumberAnimation { duration: 460; easing.type: Easing.InOutCubic } }
                            Behavior on ox { enabled: !stage.holding; NumberAnimation { duration: 460; easing.type: Easing.InOutCubic } }
                            Behavior on oy { enabled: !stage.holding; NumberAnimation { duration: 460; easing.type: Easing.InOutCubic } }

                            Repeater {
                                model: root.names

                                Item {
                                    id: tile
                                    required property string modelData
                                    readonly property var m: root.find(tile.modelData, root.draft)
                                    readonly property bool chosen: root.sel === tile.modelData
                                    readonly property bool here: Focus.screen && Focus.screen.name === tile.modelData

                                    property bool held: false
                                    property real hx: 0
                                    property real hy: 0

                                    readonly property real tx: tile.m ? stage.ox + tile.m.x * stage.k : 0
                                    readonly property real ty: tile.m ? stage.oy + tile.m.y * stage.k : 0
                                    x: tile.held ? tile.hx : tile.tx
                                    y: tile.held ? tile.hy : tile.ty
                                    width: tile.m ? root.lw(tile.m) * stage.k : 0
                                    height: tile.m ? root.lh(tile.m) * stage.k : 0
                                    z: tile.held ? 3 : tile.chosen ? 2 : 1

                                    Behavior on x { enabled: !tile.held; NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }
                                    Behavior on y { enabled: !tile.held; NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }
                                    Behavior on width { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }
                                    Behavior on height { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }

                                    scale: tile.held ? 1.035 : 1
                                    Behavior on scale { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }

                                    RectangularShadow {
                                        anchors.fill: parent
                                        radius: 12
                                        blur: tile.held ? 46 : tile.chosen ? 34 : 18
                                        spread: -2
                                        offset.y: tile.held ? 10 : 4
                                        color: tile.chosen ? Colors.alpha(Colors.accent, 0.45) : Qt.rgba(0, 0, 0, 0.5)
                                        Behavior on blur { NumberAnimation { duration: 320 } }
                                        Behavior on color { ColorAnimation { duration: 320 } }
                                    }

                                    ClippingRectangle {
                                        id: glass
                                        anchors.fill: parent
                                        radius: 12
                                        color: "#101014"
                                        opacity: tile.m && !tile.m.on ? 0.45 : 1
                                        Behavior on opacity { NumberAnimation { duration: 400 } }

                                        Image {
                                            anchors.fill: parent
                                            source: root.wall
                                            fillMode: Image.PreserveAspectCrop
                                            asynchronous: true
                                            sourceSize.width: 360
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            color: "black"
                                            opacity: tile.m && !tile.m.on ? 0.6 : tile.chosen ? 0 : 0.18
                                            Behavior on opacity { NumberAnimation { duration: 360 } }
                                        }

                                        Rectangle {
                                            anchors.fill: parent
                                            gradient: Gradient {
                                                GradientStop { position: 0.35; color: "transparent" }
                                                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.72) }
                                            }
                                        }

                                        Column {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.margins: 10
                                            spacing: 1

                                            Text {
                                                width: parent.width
                                                elide: Text.ElideRight
                                                text: tile.modelData
                                                color: "white"
                                                font.family: Fonts.display
                                                font.pixelSize: 13
                                                font.weight: Font.DemiBold
                                            }
                                            Text {
                                                width: parent.width
                                                elide: Text.ElideRight
                                                visible: tile.height > 70
                                                text: tile.m ? (tile.m.on ? tile.m.w + "×" + tile.m.h + " · " + Math.round(+tile.m.hz) + " " + I18n.t("disp.hz")
                                                                          : I18n.t("disp.off")) : ""
                                                color: Qt.rgba(1, 1, 1, 0.62)
                                                font.family: Fonts.display
                                                font.pixelSize: 10
                                                font.features: { "tnum": 1 }
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 12
                                        color: "transparent"
                                        border.width: tile.chosen ? 2 : 1
                                        border.color: tile.chosen ? Colors.alpha(Qt.lighter(Colors.accent, 1.3), 0.95)
                                                                  : Qt.rgba(1, 1, 1, 0.16)
                                        Behavior on border.color { ColorAnimation { duration: 320 } }
                                    }

                                    Rectangle {
                                        visible: tile.here
                                        anchors.top: parent.top
                                        anchors.right: parent.right
                                        anchors.margins: 9
                                        width: 7
                                        height: 7
                                        radius: 3.5
                                        color: Qt.lighter(Colors.accent, 1.4)
                                        SequentialAnimation on opacity {
                                            running: tile.here && root.shown
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 1; to: 0.35; duration: 1400; easing.type: Easing.InOutSine }
                                            NumberAnimation { from: 0.35; to: 1; duration: 1400; easing.type: Easing.InOutSine }
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: tile.held ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                                        property real sx: 0
                                        property real sy: 0
                                        property real px: 0
                                        property real py: 0

                                        onPressed: (mouse) => {
                                            const p = mapToItem(stage, mouse.x, mouse.y);
                                            px = p.x; py = p.y;
                                            sx = tile.x; sy = tile.y;
                                            if (root.sel !== tile.modelData) {
                                                root.sel = tile.modelData;
                                                Sfx.tap();
                                            }
                                        }
                                        onPositionChanged: (mouse) => {
                                            if (!pressed || !tile.m || !tile.m.on)
                                                return;
                                            const p = mapToItem(stage, mouse.x, mouse.y);
                                            if (!tile.held) {
                                                if (Math.abs(p.x - px) < 3 && Math.abs(p.y - py) < 3)
                                                    return;
                                                tile.hx = sx;
                                                tile.hy = sy;
                                                stage.holding = true;
                                                tile.held = true;
                                            }
                                            tile.hx = sx + p.x - px;
                                            tile.hy = sy + p.y - py;
                                        }
                                        onReleased: {
                                            if (!tile.held)
                                                return;
                                            const lx = (tile.hx - stage.ox) / stage.k;
                                            const ly = (tile.hy - stage.oy) / stage.k;
                                            const at = root.snap(tile.modelData, lx, ly);
                                            root.patch(tile.modelData, { x: at.x, y: at.y });
                                            tile.held = false;
                                            stage.holding = false;
                                            Sfx.pick();
                                        }
                                    }
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 40

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    text: root.cur ? root.cur.name : ""
                                    color: "white"
                                    font.family: Fonts.display
                                    font.pixelSize: Fonts.large
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: root.cur ? root.cur.desc : ""
                                    color: Qt.rgba(1, 1, 1, 0.45)
                                    font.family: Fonts.display
                                    font.pixelSize: 11
                                }
                            }

                            Seg {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                labels: [I18n.t("disp.on"), I18n.t("disp.off")]
                                index: root.cur ? (root.cur.on ? 0 : 1) : -1
                                onPicked: (i) => root.pickOn(i === 0)
                            }
                        }

                        Grid {
                            columns: 2
                            columnSpacing: 18
                            rowSpacing: 12
                            opacity: root.cur && root.cur.on ? 1 : 0.35
                            enabled: root.cur !== null && root.cur.on
                            Behavior on opacity { NumberAnimation { duration: 300 } }

                            Text { text: I18n.t("disp.res"); color: Qt.rgba(1, 1, 1, 0.5); font.family: Fonts.display; font.pixelSize: 12; height: 30; verticalAlignment: Text.AlignVCenter }
                            Seg {
                                labels: root.resolutions.map(r => r.w + "×" + r.h)
                                index: root.cur ? root.resolutions.findIndex(r => r.w === root.cur.w && r.h === root.cur.h) : -1
                                onPicked: (i) => root.pickRes(root.resolutions[i])
                            }

                            Text { text: I18n.t("disp.rate"); color: Qt.rgba(1, 1, 1, 0.5); font.family: Fonts.display; font.pixelSize: 12; height: 30; verticalAlignment: Text.AlignVCenter }
                            Seg {
                                labels: root.rates.map(h => Math.round(+h) + " " + I18n.t("disp.hz"))
                                index: root.cur ? root.rates.findIndex(h => Math.round(+h) === Math.round(+root.cur.hz)) : -1
                                onPicked: (i) => root.patch(root.cur.name, { hz: root.rates[i] })
                            }

                            Text { text: I18n.t("disp.scale"); color: Qt.rgba(1, 1, 1, 0.5); font.family: Fonts.display; font.pixelSize: 12; height: 30; verticalAlignment: Text.AlignVCenter }
                            Seg {
                                labels: root.scales.map(s => Math.round(s * 100) + "%")
                                index: root.cur ? root.scales.findIndex(s => Math.abs(s - root.cur.scale) < 1e-4) : -1
                                onPicked: (i) => {
                                    root.patch(root.cur.name, { scale: root.scales[i] });
                                    root.settle(root.cur.name);
                                }
                            }

                            Text { text: I18n.t("disp.rotate"); color: Qt.rgba(1, 1, 1, 0.5); font.family: Fonts.display; font.pixelSize: 12; height: 30; verticalAlignment: Text.AlignVCenter }
                            Seg {
                                labels: ["0°", "90°", "180°", "270°"]
                                index: root.cur ? root.cur.transform % 4 : -1
                                onPicked: (i) => {
                                    root.patch(root.cur.name, { transform: i });
                                    root.settle(root.cur.name);
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: 34

                            Pill {
                                anchors.left: parent.left
                                text: I18n.t("disp.reset")
                                glyph: "󰑓"
                                enabledish: root.dirty
                                onHit: {
                                    root.draft = root.live.map(m => Object.assign({}, m));
                                    Sfx.tap();
                                }
                            }
                            Pill {
                                anchors.right: parent.right
                                text: I18n.t("disp.apply")
                                glyph: "󰄬"
                                strong: true
                                enabledish: root.dirty
                                onHit: root.apply()
                            }
                        }
                    }

                    Item {
                        id: ask
                        anchors.fill: parent
                        opacity: root.phase === "confirm" ? 1 : 0
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: 420; easing.type: Easing.InOutCubic } }

                        Item {
                            id: ring
                            width: 128
                            height: 128
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: 30

                            RectangularShadow {
                                anchors.centerIn: parent
                                width: 90
                                height: 90
                                radius: 45
                                blur: 50
                                color: Colors.alpha(Colors.accent, 0.35)
                            }

                            Canvas {
                                id: arc
                                anchors.fill: parent
                                readonly property real f: root.remain / root.wait
                                onFChanged: requestPaint()
                                onPaint: {
                                    const ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    const c = width / 2, r = c - 6;
                                    ctx.lineWidth = 5;
                                    ctx.lineCap = "round";
                                    ctx.strokeStyle = "rgba(255,255,255,0.08)";
                                    ctx.beginPath();
                                    ctx.arc(c, c, r, 0, Math.PI * 2);
                                    ctx.stroke();
                                    if (arc.f <= 0)
                                        return;
                                    ctx.strokeStyle = String(Qt.lighter(Colors.accent, 1.25));
                                    ctx.beginPath();
                                    ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * arc.f);
                                    ctx.stroke();
                                }
                            }

                            RollText {
                                anchors.centerIn: parent
                                text: String(Math.ceil(root.remain))
                                color: "white"
                                family: Fonts.display
                                pixelSize: 40
                                weight: Font.DemiBold
                                overshoot: 0
                            }
                        }

                        Column {
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: ring.y + ring.height + 18
                            spacing: 4
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: I18n.t("disp.ask")
                                color: "white"
                                font.family: Fonts.display
                                font.pixelSize: Fonts.large
                                font.weight: Font.DemiBold
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: I18n.t("disp.auto")
                                color: Qt.rgba(1, 1, 1, 0.45)
                                font.family: Fonts.display
                                font.pixelSize: 12
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 26
                            spacing: 12
                            Pill { text: I18n.t("disp.revert"); glyph: "󰕍"; onHit: root.revert() }
                            Pill { text: I18n.t("disp.keep"); glyph: "󰄬"; strong: true; onHit: root.keep() }
                        }
                    }
                }
            }
        }
    }
}
