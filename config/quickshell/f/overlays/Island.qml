import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import "root:/design"
import "root:/gtavi"
import "root:/services"

Scope {
    id: root

    property string flashKind: ""
    property string flashGlyph: ""
    property string flashText: ""
    property real flashFraction: -1

    property int stacked: 0

    Timer {
        id: flashLife
        interval: IslandConfig.s("dwellMs")
        onTriggered: {
            if (root.hoverHold || demoLife.running || root.replyOn !== "") {
                flashLife.restart();
                return;
            }
            root.flashKind = "";
            root.stacked = 0;
        }
    }

    function flash(kind, glyph, text, fraction, force) {
        if (!IslandConfig.s("enabled") || (!force && !IslandConfig.on(kind)))
            return;
        if (root.flashKind !== "" && root.flashKind !== kind)
            root.stacked = Math.min(9, root.stacked + 1);
        root.flashKind = kind;
        root.flashGlyph = glyph;
        root.flashText = text;
        root.flashFraction = fraction === undefined ? -1 : fraction;
        flashLife.restart();
        root.flashed(kind);
    }

    property var holds: ({})
    readonly property bool hoverHold: Object.keys(root.holds).length > 0

    function hold(screen, on) {
        const next = Object.assign({}, root.holds);
        if (on)
            next[screen] = true;
        else
            delete next[screen];
        root.holds = next;
    }

    readonly property string kind: {
        if (!IslandConfig.s("enabled"))
            return "";
        if (IslandConfig.on("alarm") && Timers.anyRinging)
            return "alarm";
        if (root.callState === "ring")
            return "call";
        if (root.mediaBig)
            return "media";
        if (root.demoKind !== "")
            return root.demoKind;
        if (root.flashKind !== "")
            return root.flashKind;
        if (root.callState === "live")
            return "call";
        if (root.gtaOn)
            return "gta";
        if (IslandConfig.on("record") && Recorder.active)
            return "record";
        if (IslandConfig.on("timer") && Timers.anyRunning
            && root.leftKind !== "timer")
            return "timer";
        if (root.restingClock)
            return "clock";
        if (IslandConfig.on("media") && Media.has && Media.playing)
            return "media";
        return "";
    }

    readonly property bool restingClock:
        IslandConfig.s("enabled")
        && (IslandConfig.s("inBar") || IslandConfig.on("clock"))

    readonly property string leftKind: {
        if (!IslandConfig.s("enabled") || !IslandConfig.s("leftSlot"))
            return "";
        if (root.launch !== null)
            return "launch";
        if (root.downloadPhase !== "")
            return "download";
        if (IslandConfig.on("print") && Printing.jobs.length > 0)
            return "print";
        if (IslandConfig.on("task") && (root.taskShown || root.taskResult !== ""))
            return "task";
        if (IslandConfig.on("timer") && Timers.anyRunning)
            return "timer";
        return "";
    }

    property bool mediaBig: false

    function toggleMedia() {
        root.mediaBig = !root.mediaBig && Media.has;
    }

    Connections {
        target: Media
        function onHasChanged() { if (!Media.has) root.mediaBig = false; }
    }

    readonly property bool miniMedia:
        IslandConfig.s("enabled") && IslandConfig.on("media")
        && Media.has && Media.playing

    signal shook()
    signal sparked()
    signal snapped()
    signal flashed(string kind)
    signal poured(real level)
    signal incoming(var e)
    signal absorbed()
    signal deskMoved(int dir)
    signal chimed()

    function fail(glyph, text) {
        root.flash("fail", glyph, text, -1, true);
        root.shook();
    }

    function done(glyph, text) {
        root.flash("done", glyph, text, -1, true);
        root.sparked();
    }

    Connections {
        target: IslandBus
        function onFailed(glyph, text) { root.fail(glyph, text); }
        function onFinished(glyph, text) { root.done(glyph, text); }
    }

    property var cmd: ({ ok: true, code: 0, secs: 0, line: "", win: "", big: false })

    readonly property string cmdTook: root.took(root.cmd.secs)

    function took(secs) {
        const m = Math.floor(secs / 60);
        const h = Math.floor(m / 60);
        if (h > 0)
            return h + ":" + String(m % 60).padStart(2, "0") + ":"
                 + String(secs % 60).padStart(2, "0");
        return m > 0 ? m + ":" + String(secs % 60).padStart(2, "0") : secs + "s";
    }

    function bareAddr(a) {
        return String(a || "").toLowerCase().replace(/^0x/, "");
    }

    function watching(win) {
        const t = Hyprland.activeToplevel;
        return win !== "" && t && root.bareAddr(t.address) === root.bareAddr(win);
    }

    function focusWindow(win) {
        if (win === "")
            return;
        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow",
                                 "address:0x" + root.bareAddr(win)]);
    }

    function shellDone(id, code, secs, line, win) {
        root.taskEnd(id, code, secs);
        if (!IslandConfig.on("shell"))
            return;
        if (code === 130 || code === 141 || code === 148)
            return;
        const ok = code === 0;
        if (ok && secs < 10)
            return;
        const what = line.trim().replace(/\s+/g, " ");
        const short = what.length > 42 ? what.slice(0, 41) + "…" : what;
        root.cmd = {
            ok: ok, code: code, secs: secs, line: what, win: win,
            big: secs >= 10 && !root.watching(win)
        };
        root.flash("cmd", ok ? "󰄬" : "󰅙",
                   short + " · " + (ok ? root.took(secs) : code), -1, true);
        if (ok) {
            if (!root.cmd.big)
                root.sparked();
        } else {
            root.shook();
        }
    }

    property var tasks: ({})
    property bool taskShown: false
    property bool taskLong: false
    property string taskResult: ""
    property string taskGlyph: "󰣪"
    property string taskWin: ""
    property string taskLine: ""

    function taskGlyphFor(line) {
        const w = line.trim().split(/\s+/);
        const first = w[0] === "sudo" ? (w[1] || "") : w[0];
        if (first === "git")
            return "󰊢";
        if (/^(yay|paru|pacman|makepkg|pip3?|uv|poetry|npm|pnpm|yarn|bun)$/.test(first)
            && /(^|\s)(install|add|sync|-S\S*)(\s|$)/.test(line))
            return "󰏗";
        if (/^(docker|podman)$/.test(first))
            return "󰡨";
        if (/^(rsync|scp|wget|curl)$/.test(first))
            return "󰇚";
        if (/^(pytest|cargo)$/.test(first) && /\btest\b/.test(line) || first === "pytest")
            return "󰙨";
        return "󰣪";
    }

    function taskBegin(id, win, line) {
        if (!IslandConfig.s("enabled") || !IslandConfig.on("task"))
            return;
        const next = Object.assign({}, root.tasks);
        next[id] = { line: line, win: win, at: Date.now() };
        root.tasks = next;
        root.taskGlyph = root.taskGlyphFor(line);
        root.taskWin = win;
        root.taskLine = line;
        root.taskResult = "";
        taskResultLife.stop();
        taskReveal.restart();
        taskLongWait.restart();
    }

    function taskEnd(id, code, secs) {
        if (!(id in root.tasks))
            return;
        const next = Object.assign({}, root.tasks);
        delete next[id];
        root.tasks = next;
        const any = Object.keys(next).length > 0;
        if (root.taskShown && !any) {
            if (code === 130 || code === 148) {
                root.taskShown = false;
                return;
            }
            root.taskResult = code === 0 ? "ok" : "bad";
            taskResultLife.restart();
        }
        if (!any) {
            taskReveal.stop();
            taskLongWait.stop();
            root.taskShown = false;
            root.taskLong = false;
        }
    }

    Timer {
        interval: 30000
        repeat: true
        running: Object.keys(root.tasks).length > 0
        onTriggered: {
            const alive = {};
            for (const t of Hyprland.toplevels.values)
                alive[root.bareAddr(t.address)] = true;
            const now = Date.now();
            for (const id of Object.keys(root.tasks)) {
                const t = root.tasks[id];
                if ((t.win !== "" && !alive[root.bareAddr(t.win)])
                    || now - t.at > 6 * 3600 * 1000)
                    root.taskEnd(id, 130, 0);
            }
        }
    }

    Timer {
        id: taskReveal
        interval: 1200
        onTriggered: root.taskShown = Object.keys(root.tasks).length > 0
    }

    Timer {
        id: taskLongWait
        interval: 8000
        onTriggered: root.taskLong = Object.keys(root.tasks).length > 0
    }

    Timer {
        id: taskResultLife
        interval: 1700
        onTriggered: root.taskResult = ""
    }

    property string shotPath: ""
    property real shotAt: 0

    function shot(path) {
        if (!IslandConfig.s("enabled") || !IslandConfig.on("shot"))
            return false;
        root.shotPath = path;
        root.shotAt = Date.now();
        root.flash("shot", "󰹑", path.split("/").pop(), -1);
        root.snapped();
        return true;
    }

    property var launch: null
    property string launchPhase: ""
    signal launchLanded(int ws)

    Connections {
        target: IslandBus
        function onLaunching(info) {
            if (!IslandConfig.s("enabled"))
                return;
            root.launch = info;
            root.launchPhase = "wait";
            launchClear.stop();
            launchGiveUp.restart();
        }
        function onWallApplied(path, tone) { root.wallStart(tone); }
    }

    function launchSeen(cls, ws) {
        if (!root.launch || root.launchPhase !== "wait")
            return;
        if (!Running.matches(root.launch, cls))
            return;
        launchGiveUp.stop();
        root.launchPhase = "ok";
        launchClear.interval = 1500;
        launchClear.restart();
        root.launchLanded(ws);
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!root.launch || root.launchPhase !== "wait")
                return;
            if (event.name === "openwindow") {
                const p = event.data.split(",");
                if (p.length >= 3)
                    root.launchSeen(p[2], parseInt(p[1]));
            } else if (event.name === "activewindow") {
                const c = event.data.split(",")[0];
                const f = Hyprland.focusedWorkspace;
                root.launchSeen(c, f ? f.id : -1);
            }
        }
    }

    Timer {
        id: launchGiveUp
        interval: 10000
        onTriggered: {
            if (!root.launch)
                return;
            if (root.launch.running) {
                root.launchPhase = "ok";
                launchClear.interval = 900;
                launchClear.restart();
                return;
            }
            root.launchPhase = "bad";
            root.flash("fail", "󰅙", root.launch.name + " didn't open", -1, true);
            launchClear.interval = 2200;
            launchClear.restart();
        }
    }

    Timer {
        id: launchClear
        interval: 1500
        onTriggered: {
            root.launch = null;
            root.launchPhase = "";
        }
    }

    readonly property string downloadsDir: Quickshell.env("HOME") + "/Downloads"
    property int downloading: 0
    property string downloadPath: ""
    property string downloadPhase: ""

    Process {
        id: dlProbe
        command: ["sh", "-c",
            "find \"$1\" -maxdepth 1 -type f \\( -name '*.part' -o -name '*.crdownload' \\) | wc -l",
            "sh", root.downloadsDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const n = parseInt(this.text.trim()) || 0;
                const was = root.downloading;
                root.downloading = n;
                if (n > 0) {
                    dlDone.stop();
                    root.downloadPhase = "busy";
                } else if (was > 0) {
                    dlNewest.running = true;
                }
            }
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: IslandConfig.s("enabled")
        triggeredOnStart: true
        onTriggered: if (!dlProbe.running) dlProbe.running = true
    }

    Process {
        id: dlNewest
        command: ["sh", "-c",
            "find \"$1\" -maxdepth 1 -type f ! -name '*.part' ! -name '*.crdownload' -newermt '-20 seconds' "
            + "-printf '%T@\\t%p\\n' | sort -rn | head -1 | cut -f2-",
            "sh", root.downloadsDir]
        stdout: StdioCollector {
            onStreamFinished: {
                const path = this.text.trim();
                root.downloadPhase = path !== "" ? "ok" : "";
                dlDone.restart();
                if (path === "")
                    return;
                root.downloadPath = path;
                root.flash("download", root.fileGlyph(path), path.split("/").pop(), -1, true);
            }
        }
    }

    Timer { id: dlDone; interval: 1600; onTriggered: root.downloadPhase = "" }

    function fileGlyph(path) {
        const ext = (path.split(".").pop() || "").toLowerCase();
        if (["png", "jpg", "jpeg", "webp", "gif", "svg", "avif"].indexOf(ext) >= 0) return "󰋩";
        if (["mp4", "mkv", "webm", "mov", "avi"].indexOf(ext) >= 0) return "󰈫";
        if (["mp3", "flac", "ogg", "wav", "m4a", "opus"].indexOf(ext) >= 0) return "󰈣";
        if (["zip", "tar", "gz", "xz", "zst", "7z", "rar"].indexOf(ext) >= 0) return "󰗄";
        if (ext === "pdf") return "󰈦";
        if (["doc", "docx", "odt", "txt", "md"].indexOf(ext) >= 0) return "󰈙";
        if (["deb", "rpm", "appimage", "exe", "iso"].indexOf(ext) >= 0) return "󰏗";
        return "󰈔";
    }

    function openDownload() {
        if (root.downloadPath === "")
            return;
        Quickshell.execDetached(["kitty", "--class", "yazi", "-e", "yazi", root.downloadPath]);
        root.dismiss();
    }

    property bool wallBusy: false
    property color wallTone: Colors.accent
    signal wallSpread(color tone)
    signal wallDone(color tone)

    function wallStart(tone) {
        if (!IslandConfig.s("enabled"))
            return;
        root.wallTone = tone;
        root.wallBusy = true;
        root.flash("wall", "󰸉", "Applying wallpaper", -1, true);
        root.wallSpread(tone);
        wallGiveUp.restart();
    }

    function wallFinish() {
        if (!root.wallBusy)
            return;
        wallGiveUp.stop();
        root.wallBusy = false;
        root.wallTone = Colors.srcAccent;
        root.flash("wall", "󰏘", "Theme updated", -1, true);
        root.wallDone(Colors.srcAccent);
        root.sparked();
    }

    Connections {
        target: Colors
        function onSrcAccentChanged() {
            if (root.wallBusy)
                wallSettle.restart();
        }
    }

    Timer { id: wallSettle; interval: 380; onTriggered: root.wallFinish() }
    Timer { id: wallGiveUp; interval: 9000; onTriggered: root.wallFinish() }

    function tone(kind) {
        switch (kind) {
        case "done": return "hi";
        case "fail": return "lo";
        case "cmd":  return root.cmd.ok ? "hi" : "lo";
        case "bt":   return root.btOn ? "hi" : "lo";
        case "power": return Power.plugged ? "hi" : "lo";
        case "peri": return "lo";
        case "vpn":  return Vpn.up ? "hi" : "lo";
        case "net":  return Network.connected ? "hi" : "lo";
        case "alarm": return "lo";
        }
        return "mid";
    }

    property var skyInfo: ({ kind: "rain", mins: 0, chance: 0 })

    function sky(kind, at, chance, force) {
        const mins = Math.max(0, Math.round((at - Date.now()) / 60000));
        const when = mins < 20 ? I18n.t("isle.sky.now")
                   : mins < 90 ? I18n.t("isle.sky.in") + " " + (Math.round(mins / 10) * 10) + " " + I18n.t("isle.sky.min")
                   : I18n.t("isle.sky.in") + " ~" + Math.round(mins / 60) + " " + I18n.t("isle.sky.h");
        root.skyInfo = { kind: kind, mins: mins, chance: chance, when: when };
        root.flash("weather", kind === "snow" ? "󰖘" : "󰖗",
                   I18n.t(kind === "snow" ? "isle.sky.snow" : "isle.sky.rain") + " · " + when, -1,
                   force);
    }

    function dismiss() {
        flashLife.stop();
        root.flashKind = "";
        root.stacked = 0;
    }

    property string notifSummary: ""
    property string notifBody: ""
    property string notifApp: ""
    property color notifTint: Colors.accent
    property string notifImage: ""
    property string notifIcon: ""
    property int notifCount: 1

    readonly property string notifIconUrl:
        root.notifIcon === "" ? ""
        : root.notifIcon.startsWith("/") || root.notifIcon.startsWith("file:")
          || root.notifIcon.startsWith("image:")
          ? root.notifIcon : Quickshell.iconPath(root.notifIcon, true)

    property var notifLive: null
    property string replyOn: ""

    property var notifStack: []
    property int notifIndex: 0
    readonly property int notifTotal: root.notifStack.length

    property string lastNotifKey: ""
    property real lastNotifAt: 0
    property int lastNotifCount: 0

    function pushNotif(e) {
        const key = e.app + "\n" + e.summary;
        const now = Date.now();
        const next = root.notifStack.slice();
        const at = next.findIndex(x => x.key === key);
        let count = 1;
        if (at >= 0) {
            const old = next.splice(at, 1)[0];
            count = old.count + 1;
            if (old.live && old.live !== e.live && old.live.tracked)
                old.live.expire();
        } else if (key === root.lastNotifKey && now - root.lastNotifAt < 15000) {
            count = root.lastNotifCount + 1;
        }
        e.key = key;
        e.count = count;
        next.unshift(e);
        while (next.length > 5) {
            const gone = next.pop();
            if (gone.live && gone.live.tracked)
                gone.live.expire();
        }
        root.lastNotifKey = key;
        root.lastNotifAt = now;
        root.lastNotifCount = count;
        root.notifStack = next;
        root.notifIndex = 0;
        root.showNotif();
    }

    property var cometQueue: []
    property bool demoAfterComet: false

    function arrive(e) {
        if (!IslandConfig.s("comet") || !IslandConfig.s("enabled") || !IslandConfig.on("notif")) {
            root.pushNotif(e);
            root.flash("notif", "󰂚", root.notifSummary, -1);
            return;
        }
        root.cometQueue = root.cometQueue.concat([e]);
        root.incoming(e);
        if (!cometLand.running || root.cometQueue.length >= 3)
            cometLand.restart();
    }

    Timer {
        id: cometLand
        interval: Motion.isleCometMs
        onTriggered: {
            const q = root.cometQueue;
            root.cometQueue = [];
            if (q.length === 0)
                return;
            for (const e of q)
                root.pushNotif(e);
            root.absorbed();
            root.flash("notif", "󰂚", root.notifSummary, -1, root.demoAfterComet);
            if (root.demoAfterComet) {
                root.demoAfterComet = false;
                root.demoKind = "notif";
                root.demoWide = true;
                demoLife.restart();
            }
        }
    }

    function showNotif() {
        const e = root.notifStack[root.notifIndex];
        if (!e)
            return;
        root.notifSummary = e.summary;
        root.notifBody = e.body;
        root.notifApp = e.app;
        root.notifTint = NotifHistory.appColor(e.app);
        root.notifImage = e.image;
        root.notifIcon = e.icon;
        root.notifCount = e.count;
        root.notifLive = e.live || null;
        root.replyOn = "";
    }

    function scrollNotif(step) {
        const n = Math.max(0, Math.min(root.notifTotal - 1, root.notifIndex + step));
        if (n === root.notifIndex)
            return;
        root.notifIndex = n;
        root.showNotif();
        flashLife.restart();
    }

    function doneNotif() {
        const next = root.notifStack.slice();
        next.splice(root.notifIndex, 1);
        root.notifStack = next;
        if (next.length === 0) {
            root.dismiss();
            return;
        }
        root.notifIndex = Math.min(root.notifIndex, next.length - 1);
        root.showNotif();
        flashLife.restart();
    }

    function dropNotif() {
        for (const e of root.notifStack) {
            if (e.live && e.live.tracked)
                e.live.expire();
        }
        root.notifStack = [];
        root.notifIndex = 0;
        root.notifLive = null;
        root.replyOn = "";
    }

    onFlashKindChanged: if (root.flashKind !== "notif" && root.notifStack.length > 0) root.dropNotif()

    Connections {
        target: root.notifLive
        ignoreUnknownSignals: true
        function onClosed() {
            root.notifLive = null;
            root.replyOn = "";
        }
    }

    property var call: null
    property string callState: ""
    property real callStart: 0
    property int callSecs: 0

    Timer {
        running: root.callState === "live"
        interval: 1000
        repeat: true
        onTriggered: root.callSecs = Math.floor((Date.now() - root.callStart) / 1000)
    }

    Timer {
        running: root.callState === "ring"
        interval: 60000
        onTriggered: root.endCall()
    }

    Connections {
        target: root.call ? root.call.live : null
        ignoreUnknownSignals: true
        function onClosed() {
            if (root.callState === "ring")
                root.endCall();
        }
    }

    readonly property string callIconUrl: {
        const i = root.call ? root.call.icon : "";
        return i === "" ? "" : i.startsWith("/") || i.startsWith("image:")
            ? i : Quickshell.iconPath(i, true);
    }

    readonly property string callClock: {
        const t = root.callSecs;
        const h = Math.floor(t / 3600), m = Math.floor(t / 60) % 60, s2 = t % 60;
        const pad = (n) => (n < 10 ? "0" : "") + n;
        return (h > 0 ? h + ":" + pad(m) : pad(m)) + ":" + pad(s2);
    }

    function startCall(c) {
        root.call = c;
        root.callSecs = 0;
        root.callState = "ring";
    }

    function callAction(re) {
        const n = root.call ? root.call.live : null;
        const a = n ? n.actions : null;
        for (let i = 0; a && i < a.length; i++) {
            if (re.test(a[i].identifier) || re.test(a[i].text || "")) {
                a[i].invoke();
                return true;
            }
        }
        return false;
    }

    function acceptCall() {
        if (!root.callAction(/accept|answer|pick|принять|ответить/i))
            root.callAction(/^default$/);
        root.callStart = Date.now();
        root.callSecs = 0;
        root.callState = "live";
    }

    function declineCall() {
        if (!root.callAction(/decline|reject|hang|отклон|сбросить/i)) {
            const n = root.call ? root.call.live : null;
            if (n && n.tracked)
                n.dismiss();
        }
        root.endCall();
    }

    function endCall() {
        const n = root.call ? root.call.live : null;
        root.callState = "";
        root.call = null;
        if (n && n.tracked)
            n.expire();
    }

    function focusCall() {
        const app = root.call ? root.call.app : "";
        const cls = /telegram/i.test(app) ? "org.telegram.desktop"
                  : /discord/i.test(app) ? "discord" : app;
        Quickshell.execDetached(["hyprctl", "dispatch", "focuswindow", "class:(?i)" + cls]);
    }

    property string clipImage: ""
    property bool btOn: false
    property int deskDir: 0

    readonly property bool charging: Power.plugged
    readonly property int batteryPct: Power.percent

    IslandSources { hub: root }

    property bool gtaOn: false
    property bool gtaHover: false
    property string gtaShort: ""

    function gtaText() {
        const rem = GtaConfig.releaseFallbackMs - Date.now();
        if (rem <= 0)
            return "OUT NOW";
        return Math.floor(rem / 86400000) + "d "
             + String(Math.floor(rem / 3600000) % 24).padStart(2, "0") + "h";
    }

    function startGta() {
        root.gtaShort = root.gtaText();
        root.gtaOn = true;
        gtaLife.restart();
    }

    Timer {
        id: gtaLife
        interval: 10000
        onTriggered: root.gtaHover ? restart() : (root.gtaOn = false)
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.gtaOn
        onTriggered: root.gtaShort = root.gtaText()
    }

    Process {
        running: true
        command: ["sh", "-c",
            "m=\"${XDG_RUNTIME_DIR:-/tmp}/gtavi-island-shown\"; "
            + "if [ -e \"$m\" ]; then echo seen; else : > \"$m\"; echo first; fi"]
        stdout: StdioCollector {
            onStreamFinished: if (text.trim() === "first") gtaDelay.start()
        }
    }

    Timer { id: gtaDelay; interval: 2500; onTriggered: root.startGta() }

    IpcHandler {
        target: "island"

        function demo(kind: string): string { return root.runDemo(kind); }
        function play(kind: string): void { root.runDemo(kind); }
        function pin(on: bool): void { root.pinned = on; }
        function media(): string { root.toggleMedia(); return root.mediaBig ? "open" : "closed"; }
        function call(action: string): string {
            if (root.callState === "")
                return "no call";
            if (action === "accept" && root.callState === "ring") root.acceptCall();
            else if (action === "decline" && root.callState === "ring") root.declineCall();
            else if (action === "end") root.endCall();
            else return "ring: accept|decline, live: end";
            return root.callState === "" ? "ended" : root.callState;
        }
        function knob(name: string, value: string): string { return root.knob(name, value); }
        function chime(): void { root.chimed(); }
        function timer(secs: int, label: string): string {
            return String(Timers.start(secs, label));
        }
        function untimer(id: string): void { Timers.cancel(isNaN(parseInt(id)) ? id : parseInt(id)); }

        function begin(id: string, win: string, line: string): void { root.taskBegin(id, win, line); }
        function end(id: string, code: int, secs: int, win: string, line: string): void {
            root.shellDone(id, code, secs, line, win);
        }
        function cmd(code: int, secs: int, line: string): void { root.shellDone("", code, secs, line, ""); }

        function shot(path: string): string { return root.shot(path) ? "ok" : "off"; }

        function fail(text: string): void { root.fail("󰅙", text); }
        function done(text: string): void { root.done("󰄬", text); }
    }

    function knob(name, value) {
        const sp = IslandConfig.spec[name];
        if (!sp)
            return "no such knob: " + name;
        let v = value;
        if (sp.type === "bool")
            v = value === "true" || value === "1" || value === "on";
        else if (sp.type === "int")
            v = parseInt(value);
        IslandConfig.setStyle(name, v);
        return name + " = " + v;
    }

    property var demo: ({})
    property string demoKind: ""
    property bool demoWide: false
    property bool pinned: false

    readonly property var demoKinds: [
        "media", "osd", "notif", "timer", "alarm", "record", "bt", "btoff",
        "peri", "power", "low", "net", "vpn", "print", "clip", "clipimg",
        "keys", "desk", "route", "focus", "cmd", "cmdfail", "task", "taskfail",
        "shot", "fail", "done", "gta", "rain", "snow", "stack", "call"
    ]

    Timer {
        id: demoLife
        interval: 5200
        onTriggered: root.endDemo()
    }

    function endDemo() {
        root.demo = ({});
        root.demoKind = "";
        root.demoWide = false;
    }

    property int tourAt: -1

    Timer {
        id: tour
        interval: 4400
        repeat: true
        onTriggered: {
            root.tourAt++;
            if (root.tourAt >= root.demoKinds.length) {
                tour.stop();
                root.tourAt = -1;
                root.endDemo();
                return;
            }
            root.showDemo(root.demoKinds[root.tourAt]);
        }
    }

    function runDemo(kind) {
        switch (kind) {
        case "list":
            return root.demoKinds.join(" ") + "  |  all stop";
        case "all":
            root.tourAt = -1;
            tour.restart();
            tour.triggered();
            return "tour: " + root.demoKinds.length + " kinds, "
                 + Math.round(tour.interval / 1000) + " s each";
        case "stop":
            tour.stop();
            root.tourAt = -1;
            demoLife.stop();
            root.endDemo();
            root.dismiss();
            root.endCall();
            return "stopped";
        }
        if (root.demoKinds.indexOf(kind) < 0)
            return "unknown: " + kind + " (try: demo list)";
        root.showDemo(kind);
        return "ok";
    }

    function showDemo(kind) {
        root.endDemo();
        root.dismiss();
        let card = true;
        let held = kind;
        switch (kind) {
        case "media":
            root.demo = { media: { title: "Нічний експрес", artist: "Остров · демо",
                                   art: "", progress: 0.36, length: 214 } };
            break;
        case "osd":
            Feedback.pulse++;
            held = "";
            break;
        case "notif":
            root.demoAfterComet = IslandConfig.s("comet");
            root.arrive({ app: "Telegram", summary: "Остров", image: "",
                          body: "Так выглядит уведомление: заголовок, текст в две строки и цвет приложения.",
                          icon: "org.telegram.desktop", live: null });
            if (root.demoAfterComet) {
                held = "";
                card = false;
            }
            break;
        case "stack":
            root.pushNotif({ app: "Почта", summary: "GitHub", image: "", icon: "",
                             body: "Review requested on #5708", live: null });
            root.pushNotif({ app: "discord", summary: "#general · Лёша", image: "", icon: "discord",
                             body: "Кто сегодня на рейд в девять?", live: null });
            root.pushNotif({ app: "Telegram", summary: "Саша", image: "", icon: "org.telegram.desktop",
                             body: "Мы уже на месте, ты где?", live: null });
            root.flash("notif", "󰂚", root.notifSummary, -1, true);
            held = "notif";
            break;
        case "call":
            root.startCall({ name: "Мама", app: "Telegram", image: "",
                             icon: "org.telegram.desktop", live: null });
            held = "";
            card = false;
            break;
        case "timer":
            root.demo = { timer: { label: "Чай", left: 173, progress: 0.58 } };
            break;
        case "alarm":
        case "gta":
            break;
        case "record":
            root.demo = { record: { clock: "01:24" } };
            break;
        case "bt":
            root.demo = { bt: { name: "Sony Pulse Elite", battery: 0.82, on: true } };
            root.btOn = true;
            root.flash("bt", "󰋋", "Sony Pulse Elite", -1, true);
            break;
        case "btoff":
            root.demo = { bt: { name: "Sony Pulse Elite", battery: -1, on: false } };
            root.btOn = false;
            root.flash("bt", "󰂲", I18n.t("isle.bt.gone"), -1, true);
            held = "bt";
            break;
        case "power":
            root.demo = { power: { pct: 64, charging: true } };
            root.flash("power", "󰂄", "64%", 0.64, true);
            root.poured(0.64);
            break;
        case "rain":
        case "snow":
            root.sky(kind, Date.now() + (kind === "rain" ? 40 : 130) * 60000,
                     kind === "rain" ? 72 : 64, true);
            held = "weather";
            break;
        case "low":
            root.demo = { power: { pct: 9, charging: false } };
            root.flash("power", "󰂃", "9%", 0.09, true);
            held = "power";
            break;
        case "peri":
            root.demo = { peri: { pct: 12, model: "MX Master 3S" } };
            root.flash("peri", "󰍽", "MX Master 3S  12%", 0.12, true);
            break;
        case "net":
            root.flash("net", "󰤨", Network.ssid !== "" ? Network.ssid : "Home", -1, true);
            break;
        case "vpn":
            root.flash("vpn", "󰦝", "wg0", -1, true);
            break;
        case "print":
            root.demo = { print: { queue: 2, printer: "Canon LBP6000" } };
            break;
        case "clip":
            root.clipImage = "";
            root.flash("clip", "󰅌", "git push origin main", -1, true);
            card = false;
            break;
        case "clipimg":
            root.clipImage = "file://" + Quickshell.shellDir + "/assets/grain.png";
            root.flash("clip", "󰋩", I18n.t("isle.clip.image"), -1, true);
            held = "clip";
            break;
        case "keys":
            root.flash("keys", "󰌌", Keyboard.code.toUpperCase(), -1, true);
            card = false;
            break;
        case "desk": {
            const w = Hyprland.focusedWorkspace;
            root.deskDir = 1;
            root.deskMoved(1);
            root.flash("desk", "󰧨", w ? String(w.id) : "1", -1, true);
            card = false;
            break;
        }
        case "route":
            root.flash("route", "󰋋", "Sony Pulse Elite", -1, true);
            card = false;
            break;
        case "focus":
            root.flash("focus", "󰂛", I18n.t("isle.focus.on"), -1, true);
            card = false;
            break;
        case "cmd":
            root.cmd = { ok: true, code: 0, secs: 252, line: "cargo build --release",
                         win: "", big: true };
            root.flash("cmd", "󰄬", "cargo build --release · 4:12", -1, true);
            break;
        case "cmdfail":
            root.cmd = { ok: false, code: 2, secs: 37, line: "make -j8 install",
                         win: "", big: true };
            root.flash("cmd", "󰅙", "make -j8 install · 2", -1, true);
            root.shook();
            held = "cmd";
            break;
        case "task":
        case "taskfail": {
            const id = "demo";
            root.taskBegin(id, "", kind === "task" ? "cargo build" : "git push origin main");
            root.taskShown = true;
            root.taskLong = true;
            taskReveal.stop();
            taskLongWait.stop();
            demoTaskEnd.code = kind === "task" ? 0 : 1;
            demoTaskEnd.restart();
            card = false;
            held = "";
            break;
        }
        case "shot":
            root.shotPath = Quickshell.shellDir + "/assets/grain.png";
            root.shotAt = Date.now();
            root.flash("shot", "󰹑", "2026-10-07_12-00-00.png", -1, true);
            root.snapped();
            break;
        case "fail":
            root.fail("󰅙", "polkit · wrong password");
            card = false;
            break;
        case "done":
            root.done("󰄬", "yay -Syu · 4:12");
            card = false;
            break;
        }
        root.demoKind = held;
        root.demoWide = card && held !== "";
        demoLife.restart();
    }

    Timer {
        id: demoTaskEnd
        property int code: 0
        interval: 4800
        onTriggered: root.taskEnd("demo", demoTaskEnd.code, 3)
    }

    Variants {
        model: Quickshell.screens

        IslandWindow {
            hub: root
        }
    }
}
