pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import "root:/design"
import "root:/services"

Singleton {
    id: root

    readonly property string bin: Quickshell.env("HOME") + "/.local/bin/aulactl"

    property bool found: false
    property string connection: "none"
    property bool access: false
    property bool controllable: false
    property string error: ""
    property bool busy: committer.running
    property int hwBattery: -1

    readonly property bool ready: root.found && root.controllable && root.access && root.error === ""

    readonly property var upDevice: {
        const list = UPower.devices ? UPower.devices.values : [];
        for (const d of list) {
            if (!d || !d.isPresent || d.isLaptopBattery)
                continue;
            const m = ((d.model || "") + " " + (d.nativePath || "")).toLowerCase();
            if (m.indexOf("aula") >= 0 || m.indexOf("f75") >= 0)
                return d;
        }
        return null;
    }

    readonly property int liveBattery: root.hwBattery >= 0 ? root.hwBattery
        : root.upDevice ? Math.round(root.upDevice.percentage * 100) : -1

    readonly property bool charging: root.connection === "wired"
        || (!!root.upDevice && root.upDevice.state === UPowerDeviceState.Charging)

    readonly property int battery: root.liveBattery >= 0 ? root.liveBattery : store.batLast
    readonly property bool batteryStale: root.liveBattery < 0 && store.batLast >= 0
    readonly property double batteryAt: store.batLastAt

    readonly property real hoursLeft: {
        const h = store.batHist || [];
        if (root.charging || h.length < 2 || root.battery < 0)
            return -1;
        const a = h[0], b = h[h.length - 1];
        const dt = (b[0] - a[0]) / 3600, dp = a[1] - b[1];
        if (dt < 0.5 || dp < 2)
            return -1;
        const left = root.battery / (dp / dt);
        const since = Math.max(0, (Date.now() / 1000 - b[0]) / 3600);
        return Math.max(0, left - (root.batteryStale ? since : 0));
    }

    function leftText(h) {
        if (h < 0)
            return "";
        if (h < 1)
            return "~" + Math.max(1, Math.round(h * 60)) + "m";
        if (h < 48)
            return "~" + Math.round(h) + "h";
        const d = Math.floor(h / 24);
        return "~" + d + "d " + Math.round(h - d * 24) + "h";
    }

    function noteBattery(v) {
        if (v < 0)
            return;
        const now = Math.round(Date.now() / 1000);
        let h = (store.batHist || []).slice();
        const last = h.length ? h[h.length - 1] : null;
        if (root.charging || (last && v > last[1] + 1)) {
            h = [[now, v]];
            store.batWarned = 101;
        } else if (!last || last[1] !== v) {
            h.push([now, v]);
            while (h.length > 400)
                h.shift();
        }
        store.batHist = h;
        store.batLast = v;
        store.batLastAt = now;
        root.save();
        root.warnLow(v);
    }

    function warnLow(v) {
        if (root.charging)
            return;
        for (const lvl of [10, 20]) {
            if (v <= lvl && store.batWarned > lvl) {
                store.batWarned = lvl;
                root.save();
                const left = root.leftText(root.hoursLeft);
                notifier.command = ["notify-send", "-a", "AULA F75", "-i", "input-keyboard",
                                    "-u", lvl <= 10 ? "critical" : "normal",
                                    I18n.t("aula.lowTitle").replace("%1", v),
                                    left !== "" ? I18n.t("aula.lowBodyLeft").replace("%1", left)
                                                : I18n.t("aula.lowBody")];
                notifier.running = true;
                return;
            }
        }
    }

    Process { id: notifier }

    onLiveBatteryChanged: root.noteBattery(root.liveBattery)
    onChargingChanged: if (root.charging) { store.batHist = []; store.batWarned = 101; root.save(); }

    property var keys: []
    property var knob: [600, 27, 34, 34]
    readonly property real boardW: 640
    readonly property real boardH: 270

    readonly property var modes: [
        { key: "solid",         kind: "stored", glyph: "󰝤", speed: false },
        { key: "gradient",      kind: "stored", glyph: "󰸱", speed: false },
        { key: "aurora",        kind: "live",   glyph: "󰖨", speed: true },
        { key: "wave",          kind: "live",   glyph: "󰾞", speed: true },
        { key: "pulse",         kind: "live",   glyph: "󰐰", speed: true },
        { key: "music",         kind: "live",   glyph: "󰝚", speed: false },
        { key: "breathe",       kind: "native", id: 2,  glyph: "󰟀", speed: true,  palette: true },
        { key: "rainbow",       kind: "native", id: 3,  glyph: "󰉦", speed: true,  palette: false },
        { key: "waterfall",     kind: "native", id: 16, glyph: "󰖌", speed: true,  palette: false },
        { key: "sine_wave",     kind: "native", id: 13, glyph: "󰥛", speed: true,  palette: true },
        { key: "ripples",       kind: "native", id: 7,  glyph: "󰐱", speed: true,  palette: true },
        { key: "blossom",       kind: "native", id: 17, glyph: "󰉊", speed: true,  palette: false },
        { key: "rainbow_wheel", kind: "native", id: 6,  glyph: "󰑓", speed: true,  palette: true },
        { key: "windmill",      kind: "native", id: 15, glyph: "󰈐", speed: true,  palette: false },
        { key: "neon",          kind: "native", id: 11, glyph: "󰛨", speed: true,  palette: true },
        { key: "raindrops",     kind: "native", id: 5,  glyph: "󰖗", speed: true,  palette: true },
        { key: "stars",         kind: "native", id: 8,  glyph: "󰫢", speed: true,  palette: true },
        { key: "flash_away",    kind: "native", id: 4,  glyph: "󱐋", speed: true,  palette: true },
        { key: "snake",         kind: "native", id: 10, glyph: "󰐗", speed: true,  palette: true },
        { key: "reactive",      kind: "native", id: 12, glyph: "󰌌", speed: true,  palette: true },
        { key: "static",        kind: "native", id: 1,  glyph: "󰛩", speed: false, palette: true }
    ]

    function modeOf(key) {
        for (const m of root.modes)
            if (m.key === key)
                return m;
        return root.modes[0];
    }

    function modeById(id) {
        for (const m of root.modes)
            if (m.kind === "native" && m.id === id)
                return m;
        return null;
    }

    readonly property var hwPalette: ["#ff0000", "#00ff00", "#0000ff", "#ffff00",
                                      "#ff00ff", "#00ffff", "#ffffff", ""]
    readonly property var hwRgb: [[1, 0, 0], [0, 1, 0], [0, 0, 1], [1, 1, 0], [1, 0, 1], [0, 1, 1], [1, 1, 1]]

    readonly property string mode: store.mode
    readonly property var current: root.modeOf(store.mode)
    readonly property string kind: root.current.kind
    readonly property bool on: store.on
    readonly property color color: store.color !== "" ? store.color : Colors.srcAccent
    readonly property color color2: store.color2 !== "" ? store.color2 : Colors.srcAccentAlt
    readonly property int brightness: store.brightness
    readonly property int speed: store.speed
    readonly property int palette: store.palette
    readonly property var paint: store.paint
    readonly property bool wallSync: store.wallSync
    readonly property var presets: store.presets

    readonly property bool canSpeed: !!root.current.speed
    readonly property bool canPalette: root.kind === "native" && !!root.current.palette
    readonly property bool canColor: root.kind !== "native"
    readonly property bool canPaint: root.kind !== "native"

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/aula-f75.json"
        printErrors: false
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        property bool done: false
        onLoaded: file.done = true
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) {
                store.fresh = true;
                file.writeAdapter();
            }
            file.done = true;
        }

        JsonAdapter {
            id: store
            property bool fresh: false
            property string mode: "solid"
            property bool on: true
            property string color: ""
            property string color2: ""
            property int brightness: 9
            property int speed: 2
            property int palette: 0
            property var paint: ({})
            property bool wallSync: false
            property var presets: []
            property int batLast: -1
            property real batLastAt: 0
            property var batHist: []
            property int batWarned: 101
        }
    }

    function save() {
        file.writeAdapter();
    }

    function setMode(key) {
        if (store.mode === key && store.on)
            return;
        store.mode = key;
        store.on = true;
        root.changed(true);
    }

    function setColor(c) {
        store.color = String(c);
        root.changed(false);
    }

    function setColor2(c) {
        store.color2 = String(c);
        root.changed(false);
    }

    function setBrightness(v) {
        store.brightness = Math.max(0, Math.min(9, Math.round(v)));
        root.changed(false);
    }

    function setSpeed(v) {
        store.speed = Math.max(0, Math.min(4, Math.round(v)));
        root.changed(false);
    }

    function setPalette(i) {
        store.palette = i;
        root.changed(true);
    }

    function setOn(v) {
        store.on = v;
        root.changed(true);
    }

    function paintKey(name, c) {
        const p = Object.assign({}, store.paint);
        if (c === null || c === undefined)
            delete p[name];
        else
            p[name] = String(c);
        store.paint = p;
        root.changed(false);
    }

    function clearPaint() {
        store.paint = ({});
        root.changed(true);
    }

    function setWallSync(v) {
        store.wallSync = v;
        if (v)
            root.followWall();
        root.save();
    }

    function useTheme() {
        store.color = String(Colors.srcAccent);
        store.color2 = String(Colors.srcAccentAlt);
        root.changed(true);
    }

    function savePreset(name) {
        const list = (store.presets || []).slice();
        list.push({
            name: name,
            mode: store.mode,
            color: String(root.color),
            color2: String(root.color2),
            brightness: store.brightness,
            speed: store.speed,
            palette: store.palette,
            paint: Object.assign({}, store.paint)
        });
        store.presets = list;
        root.save();
    }

    function loadPreset(i) {
        const p = (store.presets || [])[i];
        if (!p)
            return;
        store.mode = p.mode;
        store.color = p.color;
        store.color2 = p.color2;
        store.brightness = p.brightness;
        store.speed = p.speed;
        store.palette = p.palette;
        store.paint = p.paint || ({});
        store.on = true;
        root.changed(true);
    }

    function deletePreset(i) {
        const list = (store.presets || []).slice();
        list.splice(i, 1);
        store.presets = list;
        root.save();
    }

    function followWall() {
        store.color = String(Colors.srcAccent);
        store.color2 = String(Colors.srcAccentAlt);
        root.changed(true);
    }

    Connections {
        target: Colors
        function onSrcAccentChanged() {
            if (store.wallSync)
                wallDebounce.restart();
        }
    }

    Timer {
        id: wallDebounce
        interval: 900
        onTriggered: root.followWall()
    }

    property bool pending: false

    function changed(now) {
        store.fresh = false;
        root.save();
        root.pending = true;
        if (now)
            commitDelay.interval = 60;
        else
            commitDelay.interval = 650;
        commitDelay.restart();
        root.pushFrame();
    }

    Timer {
        id: commitDelay
        interval: 650
        onTriggered: root.commit()
    }

    property bool again: false

    function commit() {
        if (!root.ready) {
            root.pending = false;
            return;
        }
        if (committer.running) {
            root.again = true;
            return;
        }
        let cmd;
        if (!store.on) {
            cmd = [root.bin, "--json", "off"];
        } else if (root.kind === "native") {
            cmd = [root.bin, "--json", "mode", String(root.current.id), "-b", String(store.brightness)];
            if (root.current.speed)
                cmd.push("-s", String(store.speed));
            if (root.current.palette)
                cmd.push("-p", String(store.palette));
        } else {
            const spec = JSON.stringify({ base: "#000000", keys: root.frameKeys(0, root.restMode()), brightness: store.brightness });
            cmd = ["sh", "-c", "printf '%s' \"$1\" | \"$0\" --json keys -", root.bin, spec];
        }
        committer.command = cmd;
        committer.running = true;
    }

    Process {
        id: committer
        stdout: StdioCollector {
            onStreamFinished: {
                root.pending = false;
                try {
                    const r = JSON.parse(this.text);
                    if (r.ok) {
                        root.error = "";
                        root.busyTries = 0;
                        root.adopt(r, false);
                    } else if (r.error === "busy" && root.busyTries < 8) {
                        root.busyTries++;
                        root.pending = true;
                        root.again = false;
                        busyRetry.restart();
                        return;
                    } else {
                        root.busyTries = 0;
                        root.error = r.error || "io";
                        root.errorText = r.message || "";
                    }
                } catch (e) {}
                if (root.again) {
                    root.again = false;
                    root.commit();
                }
            }
        }
    }

    property string errorText: ""
    property int busyTries: 0

    Timer {
        id: busyRetry
        interval: 250
        onTriggered: root.commit()
    }

    Process {
        id: watcher
        running: file.done
        command: [root.bin, "watch"]
        stdout: SplitParser {
            onRead: line => {
                let ev;
                try { ev = JSON.parse(line); } catch (e) { return; }
                if (ev.event === "battery") {
                    root.hwBattery = ev.battery === null ? -1 : ev.battery;
                    return;
                }
                if (ev.event !== "device")
                    return;
                const was = root.ready;
                root.found = !!ev.found;
                root.connection = ev.connection || "none";
                root.access = !!ev.access;
                root.controllable = !!ev.controllable;
                root.error = ev.error || (ev.found && ev.controllable && !ev.access ? "permission" : "");
                root.errorText = ev.message || "";
                root.hwBattery = ev.battery === undefined || ev.battery === null ? -1 : ev.battery;
                const took = ev.effect ? root.adopt(ev, true) : false;
                if (!was && root.ready && !took)
                    root.arrived();
            }
        }
        onExited: restartWatch.start()
    }

    Timer {
        id: restartWatch
        interval: 5000
        onTriggered: watcher.running = true
    }

    function arrived() {
        if (store.fresh) {
            store.fresh = false;
            root.save();
            return;
        }
        root.commit();
    }

    function adopt(st, fromDevice) {
        const eff = st.effect ? st.effect.id : -1;
        if (!fromDevice || root.pending)
            return false;
        if (eff === 0) {
            if (store.on && !store.fresh) {
                store.on = false;
                root.save();
                return true;
            }
            return false;
        }
        const m = root.modeById(eff);
        if (store.fresh) {
            if (m) {
                store.mode = m.key;
                if (st.palette)
                    store.palette = st.palette.index;
            } else if (st.color) {
                store.mode = "solid";
                store.color = String(st.color);
            }
            if (st.brightness !== null && st.brightness !== undefined)
                store.brightness = st.brightness;
            if (st.speed !== null && st.speed !== undefined)
                store.speed = st.speed;
            return false;
        }
        if (m && (m.key !== store.mode || !store.on)) {
            store.mode = m.key;
            store.on = true;
            if (st.brightness !== null && st.brightness !== undefined)
                store.brightness = st.brightness;
            if (st.speed !== null && st.speed !== undefined)
                store.speed = st.speed;
            if (st.palette)
                store.palette = st.palette.index;
            root.save();
            return true;
        }
        if (m && m.key === store.mode) {
            let moved = false;
            if (st.brightness !== null && st.brightness !== undefined && st.brightness !== store.brightness) {
                store.brightness = st.brightness;
                moved = true;
            }
            if (st.speed !== null && st.speed !== undefined && st.speed !== store.speed) {
                store.speed = st.speed;
                moved = true;
            }
            if (st.palette && st.palette.index !== store.palette) {
                store.palette = st.palette.index;
                moved = true;
            }
            if (moved)
                root.save();
            return moved;
        }
        return false;
    }

    function refresh() {
        if (!root.ready || committer.running || reader.running || root.pending)
            return;
        reader.running = true;
    }

    Process {
        id: reader
        command: [root.bin, "--json", "status"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(this.text);
                    if (r.ok && r.effect)
                        root.adopt(r, true);
                    if (r.battery !== undefined && r.battery !== null)
                        root.hwBattery = r.battery;
                } catch (e) {}
            }
        }
    }

    readonly property bool streaming: root.ready && store.on
        && (root.kind === "live" || (root.pending && root.kind === "stored"))

    Process {
        id: live
        command: [root.bin, "live"]
        stdinEnabled: true
        running: root.streaming || root.stopping
        onRunningChanged: if (running) root.pushFrame()
    }

    property bool stopping: false
    onStreamingChanged: {
        if (!root.streaming && live.running) {
            live.write("stop\n");
            root.stopping = true;
            stopLater.restart();
        }
    }

    Timer {
        id: stopLater
        interval: 300
        onTriggered: root.stopping = false
    }

    Timer {
        interval: root.mode === "music" ? 40 : 50
        repeat: true
        running: root.streaming && root.kind === "live"
        onTriggered: root.pushFrame()
    }

    readonly property bool wantMusic: root.streaming && root.mode === "music"
    onWantMusicChanged: root.wantMusic ? Cava.hold() : Cava.release()

    function pushFrame() {
        if (!live.running)
            return;
        const t = (Date.now() - root.epoch) / 1000;
        const out = new Array(126).fill("000000");
        const k = root.keys;
        const scale = Math.pow(store.brightness / 9, 2.2);
        const X = root.context();
        for (let i = 0; i < k.length; i++) {
            const c = root.shade(k[i], i, t, undefined, X);
            out[k[i].led] = root.hex2(c[0] * scale) + root.hex2(c[1] * scale) + root.hex2(c[2] * scale);
        }
        live.write("F " + out.join("") + "\n");
    }

    readonly property double epoch: Date.now()

    function hex2(v) {
        const n = Math.max(0, Math.min(255, Math.round(v * 255)));
        return (n < 16 ? "0" : "") + n.toString(16);
    }

    function restMode() {
        switch (store.mode) {
        case "aurora":
        case "music":
            return "gradient";
        case "wave":
        case "pulse":
            return "solid";
        default:
            return store.mode;
        }
    }

    function frameKeys(t, modeKey) {
        const out = {};
        const X = root.context();
        for (let i = 0; i < root.keys.length; i++) {
            let c = root.shade(root.keys[i], i, t, modeKey, X);
            if (X.paint && X.paint[root.keys[i].name])
                c = X.paint[root.keys[i].name];
            out[root.keys[i].name] = "#" + root.hex2(c[0]) + root.hex2(c[1]) + root.hex2(c[2]);
        }
        return out;
    }

    function rgb(c) { return [c.r, c.g, c.b]; }

    function hsv(h, s, v) {
        h = ((h % 1) + 1) % 1 * 6;
        const i = Math.floor(h) % 6, f = h - Math.floor(h);
        const p = v * (1 - s), q = v * (1 - s * f), w = v * (1 - s * (1 - f));
        switch (i) {
        case 0: return [v, w, p];
        case 1: return [q, v, p];
        case 2: return [p, v, w];
        case 3: return [p, q, v];
        case 4: return [w, p, v];
        default: return [v, p, q];
        }
    }

    function mul(c, k) { return [c[0] * k, c[1] * k, c[2] * k]; }

    function lerp(a, b, t) {
        return [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];
    }

    function hash(i) {
        const s = Math.sin(i * 127.1 + 311.7) * 43758.5453;
        return s - Math.floor(s);
    }

    function palColor(k, i, t, x) {
        const p = x.pal;
        if (p >= 7)
            return root.hsv(root.hash(i) + t * 0.03, 1, 1);
        return root.hwRgb[p];
    }

    function context() {
        return {
            pal: store.palette,
            r: 0.35 + store.speed * 0.4,
            base: root.rgb(root.color),
            alt: root.rgb(root.color2),
            n: root.keys.length || 80,
            bands: Cava.smooth || [],
            paint: root.paintRgb()
        };
    }

    function paintRgb() {
        if (root.current.kind === "native")
            return null;
        const out = {};
        for (const name in store.paint) {
            const q = Qt.color(store.paint[name]);
            out[name] = [q.r, q.g, q.b];
        }
        return out;
    }

    function shade(k, i, t, modeKey, ctx) {
        const key = modeKey || store.mode;
        const X = ctx || root.context();
        const r = X.r;
        const x = k.cx, y = k.cy;
        const base = X.base;
        let c;
        switch (key) {
        case "solid":
            c = base;
            break;
        case "gradient":
            c = root.lerp(base, X.alt, Math.min(1, Math.max(0, x * 1.05 - 0.02)));
            break;
        case "aurora": {
            const f = 0.5 + 0.5 * Math.sin(x * 3.2 + t * r * 0.55 + Math.sin(y * 2.4 + t * r * 0.3) * 1.4);
            const g = 0.75 + 0.25 * Math.sin(x * 5.0 - t * r * 0.8 + y * 3);
            c = root.mul(root.lerp(base, X.alt, f), g);
            break;
        }
        case "wave": {
            const f = 0.5 + 0.5 * Math.sin(x * 6.5 - t * r * 2.2);
            c = root.mul(base, 0.1 + 0.9 * f * f);
            break;
        }
        case "pulse": {
            const f = 0.5 - 0.5 * Math.cos(t * r * 1.2);
            c = root.mul(base, 0.08 + 0.92 * f);
            break;
        }
        case "music": {
            const bands = X.bands;
            const n = bands.length || 1;
            const lvl = bands[Math.min(n - 1, Math.floor(x * n))] || 0;
            const h = 1 - y;
            c = h <= lvl * 1.05 + 0.02 ? root.lerp(base, X.alt, h) : root.mul(base, 0.06);
            break;
        }
        case "breathe": {
            const f = 0.5 - 0.5 * Math.cos(t * r * 0.9);
            c = root.mul(root.palColor(k, i, t, X), 0.04 + 0.96 * f);
            break;
        }
        case "rainbow":
            c = root.hsv(x * 0.85 - t * r * 0.18, 1, 1);
            break;
        case "waterfall":
            c = root.hsv(y * 0.7 + x * 0.08 - t * r * 0.18, 1, 1);
            break;
        case "sine_wave": {
            const f = 0.5 + 0.5 * Math.sin(x * 7 + y * 2 - t * r * 2.4);
            c = root.mul(root.palColor(k, i, t, X), Math.pow(f, 2.2));
            break;
        }
        case "ripples": {
            const d = Math.hypot((x - 0.5) * 2.3, y - 0.5);
            const f = Math.pow(0.5 + 0.5 * Math.cos(d * 9 - t * r * 3), 5);
            c = root.mul(root.palColor(k, i, t, X), f);
            break;
        }
        case "blossom": {
            const d = Math.hypot((x - 0.5) * 2.3, y - 0.5);
            c = root.hsv(d * 0.9 - t * r * 0.2, 1, 1);
            break;
        }
        case "rainbow_wheel": {
            const a = Math.atan2(y - 0.5, (x - 0.5) * 2.4) / (2 * Math.PI);
            c = X.pal >= 7 ? root.hsv(a + t * r * 0.15, 1, 1)
                                   : root.mul(root.palColor(k, i, t, X), 0.5 + 0.5 * Math.sin((a + t * r * 0.15) * 2 * Math.PI));
            break;
        }
        case "windmill": {
            const a = Math.atan2(y - 0.5, (x - 0.5) * 2.4) / (2 * Math.PI);
            c = root.hsv(Math.floor((a + t * r * 0.08) * 6) / 6, 1, 1);
            break;
        }
        case "neon":
            c = X.pal >= 7 ? root.hsv(t * r * 0.06, 1, 1)
                                   : root.mul(root.palColor(k, i, t, X), 0.7 + 0.3 * Math.sin(t * r * 1.5 + x * 2));
            break;
        case "raindrops": {
            const ph = (t * r * 0.45 + root.hash(i) * 7) % 1;
            const lit = root.hash(i * 3.3 + Math.floor(t * r * 0.45 + root.hash(i) * 7)) < 0.32;
            c = lit && ph < 0.4 ? root.mul(root.palColor(k, i, t, X), 1 - ph / 0.4) : [0, 0, 0];
            break;
        }
        case "stars": {
            const f = Math.max(0, Math.sin(t * r * 1.1 + root.hash(i) * 40));
            c = root.mul(root.palColor(k, i, t, X), Math.pow(f, 10));
            break;
        }
        case "flash_away": {
            const front = ((t * r * 0.35) % 1) * 1.6 - 0.3;
            const d = Math.abs(front - (x * 0.75 + (1 - y) * 0.25));
            c = root.mul(root.palColor(k, i, t, X), Math.max(0, 1 - d * 5));
            break;
        }
        case "snake": {
            const n = X.n;
            const head = (t * r * 0.1) % 1;
            const lag = ((head - i / n) + 1) % 1;
            c = root.mul(root.palColor(k, i, t, X), Math.max(0, 1 - lag * 14));
            break;
        }
        case "reactive": {
            const slot = Math.floor(t * 6);
            const hit = Math.floor(root.hash(slot) * X.n) === i
                     || Math.floor(root.hash(slot - 1) * X.n) === i;
            const fade = 1 - ((t * 6) % 1);
            c = hit ? root.mul(root.palColor(k, i, t, X), fade) : [0, 0, 0];
            break;
        }
        case "static":
            c = root.palColor(k, i, t, X);
            break;
        default:
            c = base;
        }
        if (!modeKey && X.paint) {
            const p = X.paint[k.name];
            if (p)
                c = p;
        }
        return c;
    }

    Process {
        id: layoutQuery
        running: true
        command: [root.bin, "--json", "layout"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const r = JSON.parse(this.text);
                    const W = r.width, H = r.height;
                    let minX = 1e9, minY = 1e9, maxX = 0, maxY = 0;
                    for (const k of r.keys) {
                        minX = Math.min(minX, k.x);
                        minY = Math.min(minY, k.y);
                        maxX = Math.max(maxX, k.x + k.w);
                        maxY = Math.max(maxY, k.y + k.h);
                    }
                    root.keys = r.keys.map(k => Object.assign({}, k, {
                        cx: (k.x + k.w / 2 - minX) / (maxX - minX),
                        cy: (k.y + k.h / 2 - minY) / (maxY - minY)
                    }));
                    root.knob = r.knob;
                } catch (e) {}
            }
        }
    }
}
