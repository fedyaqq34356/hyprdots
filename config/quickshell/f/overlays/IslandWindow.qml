import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes as Vec
import "root:/design"
import "root:/reusables"
import "root:/services"

PanelWindow {
    WlrLayershell.namespace: "qs-island"
    WlrLayershell.layer: WlrLayer.Overlay
    id: win
    required property var modelData
    required property var hub
    screen: modelData

    readonly property bool mine:
        IslandConfig.s("where") === "all"
        || (Focus.screen && Focus.screen.name === modelData.name)

    readonly property bool blocked: {
        if (!IslandConfig.s("hideFull"))
            return false;
        const mon = Hyprland.monitorFor(win.modelData);
        const ws = mon ? mon.activeWorkspace : null;
        if (ws && !ws.hasFullscreen)
            return false;
        const list = ToplevelManager.toplevels
            ? ToplevelManager.toplevels.values : [];
        for (const t of list) {
            if (!t || !t.fullscreen)
                continue;
            for (const s of t.screens || []) {
                if (s && s.name === win.modelData.name)
                    return true;
            }
        }
        return false;
    }

    readonly property bool wanted:
        win.hub.kind !== "" || win.hub.miniMedia || win.hub.leftKind !== ""
        || win.seeking

    readonly property bool seeking:
        IslandBus.searching && IslandBus.searchScreen === win.modelData.name

    visible: IslandConfig.s("enabled")
             && ((win.mine && !win.blocked && win.wanted)
                 || birth.value > 0.01 || (win.blocked && fold.value < 0.96))

    readonly property bool inBar: IslandConfig.s("inBar")
    readonly property bool atTop:
        win.inBar ? Prefs.barAtTop : IslandConfig.s("edge") === "top"

    anchors {
        top: win.atTop
        bottom: !win.atTop
        left: true
        right: true
    }

    implicitHeight: 320

    exclusiveZone: -1
    color: "transparent"
    mask: Region { item: stage }

    property bool pointerIn: false
    property bool hovering: false

    onPointerInChanged: {
        if (win.pointerIn) {
            hoverDrop.stop();
            hoverPick.restart();
        } else {
            hoverPick.stop();
            hoverDrop.restart();
        }
    }

    Timer {
        id: hoverPick
        interval: 150
        onTriggered: win.hovering = true
    }

    Timer {
        id: hoverDrop
        interval: 100
        onTriggered: win.hovering = false
    }

    property bool forced: false
    property real wheelAt: 0

    Timer {
        id: force
        interval: IslandConfig.s("autoWideMs")
        onTriggered: win.forced = false
    }

    readonly property bool bigEvent:
        win.hub.kind === "notif" || win.hub.kind === "alarm"
        || win.hub.kind === "bt" || win.hub.kind === "peri"
        || win.hub.kind === "power"
        || win.hub.kind === "net" || win.hub.kind === "vpn"
        || (win.hub.kind === "clip" && win.hub.clipImage !== "")
        || win.hub.kind === "shot"
        || (win.hub.kind === "cmd" && win.hub.cmd.big)
        || win.hub.kind === "weather"
        || win.ringing

    Connections {
        target: win.hub
        function onKindChanged() {
            if (win.hub.kind === "")
                return;
            win.bump();
            if (!IslandConfig.s("autoWide") || !win.bigEvent)
                return;
            win.forced = true;
            force.restart();
        }
    }

    readonly property bool big: win.hub.mediaBig && win.lead

    readonly property string wideKind: {
        if (win.big)
            return "media";
        if (win.hub.demoWide)
            return win.hub.kind;
        if (win.bigEvent || win.hub.kind === "gta")
            return win.hub.kind;
        if (win.hub.kind === "timer" || win.hub.kind === "record"
            || win.hub.kind === "osd"
            || win.hub.kind === "net" || win.hub.kind === "vpn"
            || win.hub.kind === "print"
            || win.hub.kind === "cmd" || win.hub.kind === "shot")
            return win.hub.kind;
        if (Media.has)
            return "media";
        return "";
    }

    readonly property bool replying:
        win.hub.replyOn !== "" && win.hub.replyOn === win.modelData.name
        && win.wideKind === "notif"

    WlrLayershell.keyboardFocus: win.replying || win.big ? WlrKeyboardFocus.Exclusive
                                                         : WlrKeyboardFocus.None

    property bool grabbing: false
    onBigChanged: {
        if (win.big)
            grabLater.restart();
        else {
            grabLater.stop();
            win.grabbing = false;
        }
    }
    Timer { id: grabLater; interval: 160; onTriggered: win.grabbing = win.big }

    readonly property bool bigMotion: win.big || bigSettle.running
        || wideSpan.value > IslandConfig.s("wideWidth") + 6
    Timer { id: bigSettle; interval: 1100 }
    Connections {
        target: win
        function onBigChanged() { bigSettle.restart(); }
    }

    HyprlandFocusGrab {
        active: win.grabbing
        windows: [win]
        onCleared: win.hub.mediaBig = false
    }

    Item {
        focus: win.big
        Keys.onEscapePressed: win.hub.mediaBig = false
        Keys.onSpacePressed: Media.toggle()
        Keys.onLeftPressed: Media.seekTo(Media.progress - 0.02)
        Keys.onRightPressed: Media.seekTo(Media.progress + 0.02)
    }

    readonly property bool notifTools: {
        if (win.wideKind !== "notif" || !win.hub.notifLive)
            return false;
        if (win.replying)
            return true;
        if (!win.hovering)
            return false;
        const n = win.hub.notifLive;
        if (n.hasInlineReply)
            return true;
        const a = n.actions;
        for (let i = 0; a && i < a.length; i++) {
            if (a[i].text && a[i].identifier !== "default"
                && a[i].identifier !== "inline-reply")
                return true;
        }
        return false;
    }

    readonly property bool ringing:
        win.hub.kind === "call" && win.hub.callState === "ring"

    readonly property bool wide:
        win.wideKind !== "" && !win.seeking
        && (win.hub.pinned || win.forced || win.hub.demoWide || win.replying
            || win.big
            || win.ringing
            || (win.hovering && IslandConfig.s("hoverWide")
                && !win.hushed))

    property bool opened: false

    MorphSpring {
        id: windup
        springBack: true
        response: 0.22
        damping: 0.42
        epsilon: 0.002
        target: 0
    }

    Timer {
        id: windupHold
        interval: Motion.isleWindupMs
        Component.onCompleted: win.opened = win.wide
        onTriggered: {
            windup.target = 0;
            win.opened = win.wide;
        }
    }

    Connections {
        target: win
        function onWideChanged() {
            if (win.wide) {
                if (IslandConfig.s("anticipate") && !win.big && win.visible && birth.value > 0.9) {
                    windup.target = 1;
                    windupHold.restart();
                } else {
                    win.opened = true;
                }
            } else {
                windupHold.stop();
                windup.target = 0;
                win.opened = false;
            }
        }
    }

    property bool hushed: false
    onHoveringChanged: {
        if (!win.hovering)
            win.hushed = false;
        win.hub.gtaHover = win.hovering;
        win.hub.hold(win.modelData.name, win.hovering);
    }

    readonly property color mediaTint:
        IslandConfig.s("artTint") && artTint.found ? artTint.color
                                                   : Colors.accent

    readonly property color bodyColor:
        IslandConfig.s("black") ? Qt.rgba(0, 0, 0, 1) : Colors.bg

    readonly property color tint: {
        if (win.seeking)
            return IslandBus.hueOn ? IslandBus.hue : Colors.accent;
        if (!IslandConfig.s("tintEdge"))
            return Colors.outline;
        if (win.wide && win.wideKind === "media")
            return win.mediaTint;
        switch (win.hub.kind) {
        case "alarm":  return Colors.bad;
        case "record": return Colors.bad;
        case "notif":  return iconTint.found ? iconTint.color : win.hub.notifTint;
        case "call":   return win.hub.callState === "live" ? Colors.good
                            : callTint.found ? callTint.color : Colors.accent;
        case "osd":    return Feedback.channel === "source" ? Colors.accentAlt
                            : Feedback.channel === "light" ? Qt.rgba(1.0, 0.80, 0.42, 1)
                            : Colors.accent;
        case "timer":  return Colors.accentAlt;
        case "gta":    return "#f976b0";
        case "desk":   return Colors.accentAlt;
        case "peri":   return Peripherals.critical ? Colors.bad
                                                   : Colors.warn;
        case "power":  return win.hub.charging ? Colors.good
                            : (win.hub.batteryPct <= 15 ? Colors.bad
                                                     : Colors.accent);
        case "bt":     return win.hub.btOn ? Colors.good : Colors.fgDim;
        case "vpn":    return Vpn.up ? Colors.good : Colors.fgDim;
        case "net":    return Network.connected ? Colors.accentAlt
                                                : Colors.fgDim;
        case "print":  return Colors.accentAlt;
        case "focus":  return Dnd.active ? Qt.rgba(0.37, 0.36, 0.90, 1)
                                         : Colors.fgDim;
        case "route":  return Colors.accent;
        case "caps":   return Colors.warn;
        case "keys":   return Keyboard.code === "RU" ? Colors.accentAlt : Colors.accent;
        case "fail":   return Colors.bad;
        case "cmd":    return win.hub.cmd.ok ? Colors.good : Colors.bad;
        case "shot":   return Colors.fg;
        case "weather": return win.hub.skyInfo.kind === "snow" ? Qt.rgba(0.75, 0.85, 1, 1)
                                                               : Colors.accentAlt;
        case "done":   return Colors.good;
        case "download": return Colors.good;
        case "wall":   return win.hub.wallTone;
        case "clip":   return win.hub.flashGlyph === "󰌾" ? Colors.warn
                                                       : Colors.accentAlt;
        case "media":  return win.mediaTint;
        default:       return win.hub.miniMedia ? win.mediaTint
                                             : Colors.accent;
        }
    }

    readonly property bool lead:
        win.mine && (!Focus.screen || Focus.screen.name === win.modelData.name)
    readonly property bool loud: IslandConfig.s("sfx") && win.lead && win.visible

    property bool sounded: false
    onWideChanged: {
        if (!win.loud) {
            win.sounded = false;
            return;
        }
        if (win.wide) {
            if (win.wideKind === "notif" || win.wideKind === "shot") {
                win.sounded = false;
                return;
            }
            Sfx.isleOpen(win.hub.tone(win.hub.kind), !win.forced && !win.hub.demoWide);
            win.sounded = true;
        } else if (win.sounded) {
            Sfx.isleClose();
            win.sounded = false;
        }
    }

    Connections {
        target: win.hub
        function onFlashed(kind) {
            if (kind === "notif" && IslandConfig.s("autoWide") && win.bigEvent) {
                win.forced = true;
                force.restart();
            }
            if (!win.loud)
                return;
            if (kind === "done" || (kind === "cmd" && win.hub.cmd.ok && !win.hub.cmd.big))
                Sfx.isleOk();
            else if (kind === "fail" || (kind === "cmd" && !win.hub.cmd.ok && !win.hub.cmd.big))
                Sfx.isleFail();
        }
        function onSnapped() {
            if (win.loud)
                Sfx.isleShutter();
        }
    }

    MorphSpring {
        id: morph
        target: win.opened ? 1 : 0
        response: win.bigMotion ? 0.5 : Motion.isleOpenResponse
        damping: win.bigMotion ? 0.92 : Motion.isleOpenDamping
        closeMs: win.bigMotion ? 420 : Motion.isleCloseMs
        softClose: win.bigMotion
    }

    MorphSpring {
        id: pillWidth
        springBack: true
        response: pillWidth.target > pillWidth.value
            ? 0.30 : Motion.isleWidthResponse
        damping: Motion.isleWidthDamping
        target: Math.max(IslandConfig.s("pillMin"), pill.implicitWidth + 26)
        epsilon: 0.25
        Component.onCompleted: pillWidth.land()
    }

    MorphSpring {
        id: birth
        target: win.mine && win.wanted && !(win.blocked && fold.value > 0.96) ? 1 : 0
    }

    MorphSpring {
        id: fold
        response: 0.5
        damping: 1.0
        closeMs: 520
        softClose: true
        target: win.blocked ? 1 : 0
    }

    MorphSpring {
        id: wideTall
        springBack: true
        response: win.bigMotion ? 0.56 : Motion.isleWidthResponse
        damping: win.bigMotion ? 1.0 : 0.78
        epsilon: 0.25
        target: win.big ? IslandConfig.s("mediaBigHeight")
              : win.wideKind === "media" ? IslandConfig.s("mediaHeight")
              : IslandConfig.s("wideHeight") + (win.notifTools ? 40 : 0)
        Component.onCompleted: wideTall.land()
    }

    MorphSpring {
        id: wideSpan
        springBack: true
        response: win.bigMotion ? 0.56 : 0.44
        damping: win.bigMotion ? 1.0 : 0.74
        epsilon: 0.25
        target: win.big ? IslandConfig.s("mediaBigWidth") : IslandConfig.s("wideWidth")
        Component.onCompleted: wideSpan.land()
    }

    MorphSpring {
        id: seek
        response: 0.40
        damping: 0.96
        closeMs: 260
        softClose: true
        target: win.seeking ? 1 : 0
    }

    FrameAnimation {
        running: (win.seeking || seek.running)
                 && IslandBus.searchScreen === win.modelData.name
        onTriggered: {
            const r = surface.mapToItem(comet, 0, 0);
            const q = surface.mapToItem(comet, surface.width, surface.height);
            IslandBus.isleX = r.x;
            IslandBus.isleY = r.y;
            IslandBus.isleW = q.x - r.x;
            IslandBus.isleH = q.y - r.y;
            IslandBus.isleScreen = win.modelData.name;
        }
    }

    property real beat: 0

    Connections {
        target: Cava
        enabled: (IslandConfig.s("glow") || IslandConfig.s("pulse"))
                 && (win.hub.miniMedia || win.big) && win.visible
        function onSmoothChanged() {
            const l = Cava.smooth;
            win.beat = Math.min(1, ((l[0] || 0) + (l[1] || 0)
                                    + (l[2] || 0)) / 2.4);
        }
    }

    Connections {
        target: win.hub
        function onMiniMediaChanged() {
            if (!win.hub.miniMedia)
                win.beat = 0;
        }
    }

    MorphSpring {
        id: dotLife
        target: stage.minimalOn ? 1 : 0
    }

    MorphSpring {
        id: slotLife
        target: stage.leftOn ? 1 : 0
    }

    readonly property real rimValue: {
        if (!IslandConfig.s("rim"))
            return -1;
        if (win.wide && win.wideKind === "media")
            return Media.hasPosition ? Media.progress : -1;
        switch (win.hub.kind) {
        case "peri":
        case "power":
            return win.hub.flashFraction;
        case "timer":
            return Timers.soonest ? Timers.progress(Timers.soonest) : -1;
        case "media":
            return Media.hasPosition ? Media.progress : -1;
        }
        return -1;
    }

    readonly property bool rimBusy:
        IslandConfig.s("rim") && !IslandConfig.s("leftSlot")
        && IslandConfig.on("print") && Printing.jobs.length > 0

    MorphSpring {
        id: hoverLift
        springBack: true
        response: Motion.isleHoverResponse
        damping: Motion.isleHoverDamping
        target: win.hovering ? 1 : 0
    }

    MorphSpring {
        id: peek
        springBack: true
        response: Motion.islePeekResponse
        damping: Motion.islePeekDamping
        target: 0
    }

    Timer {
        id: peekHold
        interval: Motion.islePeekHoldMs
        onTriggered: peek.target = 0
    }

    function bump() {
        peek.target = 1;
        peekHold.restart();
    }

    Connections {
        target: Emergence
        function onLaunched() { if (win.mine) win.bump(); }
    }

    property bool pressed: false

    MorphSpring {
        id: press
        springBack: true
        response: Motion.isleTapResponse
        damping: Motion.isleTapDamping
        target: win.pressed ? 1 : 0
    }

    readonly property bool throbbing:
        win.hub.kind === "alarm"
        || (win.hub.kind === "record" && !win.wide)

    property real throb: 0

    SequentialAnimation {
        running: win.throbbing && win.visible
        loops: Animation.Infinite
        alwaysRunToEnd: true
        onStopped: win.throb = 0

        NumberAnimation {
            target: win; property: "throb"
            to: 1; duration: Motion.isleThrobMs * 0.42
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: win; property: "throb"
            to: 0; duration: Motion.isleThrobMs * 0.58
            easing.type: Easing.InOutSine
        }
    }

    MorphSpring {
        id: squash
        springBack: true
        response: Motion.isleSquashResponse
        damping: Motion.isleSquashDamping
        epsilon: 0.002
        target: win.pressed && IslandConfig.s("rubber") ? 1 : 0
    }

    readonly property bool hearing:
        IslandConfig.s("pulse") && win.hub.miniMedia && win.visible
        && win.mine && !win.asleep
    onHearingChanged: win.hearing ? Cava.hold() : Cava.release()
    Component.onDestruction: {
        if (win.hearing)
            Cava.release();
        if (win.voicing)
            MicLevel.release();
        win.hub.hold(win.modelData.name, false);
    }

    readonly property real edgeAlpha:
        Math.min(1, IslandConfig.s("borderAlpha") / 100
                    + (win.hearing ? 0.10 + 0.85 * win.beat : 0)
                    + (win.voicing ? 0.12 + 0.85 * voice.value : 0))

    readonly property bool voicing:
        IslandConfig.s("micRim") && win.mine && win.visible
        && (win.hub.callState === "live" || Recorder.active)
    onVoicingChanged: win.voicing ? MicLevel.hold() : MicLevel.release()

    MorphSpring {
        id: voice
        springBack: true
        response: 0.16
        damping: 0.78
        epsilon: 0.002
        target: win.voicing ? MicLevel.level : 0
    }

    readonly property bool magnetOn:
        IslandConfig.s("magnet") && win.mine && win.visible && !win.wide
        && !win.blocked && !win.asleep
    property bool near: false

    onMagnetOnChanged: if (!win.magnetOn) win.unpull()

    function unpull() {
        win.near = false;
        magX.target = 0;
        magY.target = 0;
        magP.target = 0;
    }

    function aim(gx, gy) {
        const x = gx - win.modelData.x;
        const y = gy - win.modelData.y;
        const hw = surface.width / 2;
        const hh = surface.height / 2;
        const cx = stage.x + stage.head + hw;
        const cy = stage.y + hh;
        const dx = x - cx;
        const dy = y - cy;
        const ox = Math.max(0, Math.abs(dx) - hw);
        const oy = Math.max(0, Math.abs(dy) - hh);
        const d = Math.hypot(ox, oy);
        const reach = Motion.isleMagnetReach;
        win.near = d < reach * 2.2;
        let p = d >= reach ? 0 : 1 - d / reach;
        p = p * p * (3 - 2 * p);
        const lx = Math.max(-1, Math.min(1, dx / (hw + reach)));
        const ly = Math.max(-1, Math.min(1, dy / (hh + reach)));
        magX.target = lx * p * Motion.isleMagnetPull;
        magY.target = Math.max(-0.3, ly) * p * Motion.isleMagnetPull * 0.7;
        magP.target = p;
    }

    MorphSpring { id: magX; springBack: true; response: 0.42; damping: 0.55; epsilon: 0.01 }
    MorphSpring { id: magY; springBack: true; response: 0.42; damping: 0.55; epsilon: 0.01 }
    MorphSpring { id: magP; springBack: true; response: 0.36; damping: 0.62; epsilon: 0.002 }

    Socket {
        id: cursorSock
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/"
              + Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE") + "/.socket.sock"
        parser: SplitParser {
            splitMarker: ""
            onRead: (data) => {
                const m = data.split(",");
                cursorSock.connected = false;
                if (m.length < 2 || !win.magnetOn)
                    return;
                const gx = parseFloat(m[0]);
                const gy = parseFloat(m[1]);
                if (!isNaN(gx) && !isNaN(gy))
                    win.aim(gx, gy);
            }
        }
        onConnectedChanged: {
            if (cursorSock.connected) {
                cursorSock.write("cursorpos");
                cursorSock.flush();
            }
        }
    }

    Timer {
        interval: win.near ? 33 : 160
        repeat: true
        running: win.magnetOn
        onTriggered: if (!cursorSock.connected) cursorSock.connected = true
    }

    MorphSpring {
        id: drift
        springBack: true
        response: 0.30
        damping: 0.52
        epsilon: 0.002
        target: 0
    }

    Timer {
        id: driftHold
        interval: 90
        onTriggered: drift.target = 0
    }

    Connections {
        target: win.hub
        function onDeskMoved(dir) {
            if (!win.mine || !win.visible)
                return;
            drift.target = dir;
            driftHold.restart();
        }
    }

    property bool chiming: false
    property real chimeGlow: 0

    SystemClock {
        id: hourClock
        precision: SystemClock.Minutes
        onDateChanged: {
            if (hourClock.date.getMinutes() === 0 && win.mine && win.visible)
                chimeRun.restart();
        }
    }

    function chime() { chimeRun.restart(); }

    SequentialAnimation {
        id: chimeRun
        ScriptAction { script: win.chiming = true }
        NumberAnimation { target: win; property: "chimeGlow"; to: 1; duration: 700; easing.type: Easing.InOutSine }
        NumberAnimation { target: win; property: "chimeGlow"; to: 0; duration: 1900; easing.type: Easing.InOutSine }
        ScriptAction { script: win.chiming = false }
    }

    Connections {
        target: win.hub
        function onChimed() { if (win.mine) win.chime(); }
    }

    property real shakeX: 0

    SequentialAnimation {
        id: shakeRun
        readonly property int step: Motion.isleShakeMs / 7
        NumberAnimation { target: win; property: "shakeX"; to: -Motion.isleShakePx;        duration: shakeRun.step; easing.type: Easing.OutQuad }
        NumberAnimation { target: win; property: "shakeX"; to:  Motion.isleShakePx * 0.85; duration: shakeRun.step; easing.type: Easing.InOutQuad }
        NumberAnimation { target: win; property: "shakeX"; to: -Motion.isleShakePx * 0.62; duration: shakeRun.step; easing.type: Easing.InOutQuad }
        NumberAnimation { target: win; property: "shakeX"; to:  Motion.isleShakePx * 0.40; duration: shakeRun.step; easing.type: Easing.InOutQuad }
        NumberAnimation { target: win; property: "shakeX"; to: -Motion.isleShakePx * 0.22; duration: shakeRun.step; easing.type: Easing.InOutQuad }
        NumberAnimation { target: win; property: "shakeX"; to:  Motion.isleShakePx * 0.08; duration: shakeRun.step; easing.type: Easing.InOutQuad }
        NumberAnimation { target: win; property: "shakeX"; to: 0;                          duration: shakeRun.step; easing.type: Easing.OutQuad }
    }

    Connections {
        target: win.hub
        function onShook() {
            if (IslandConfig.s("shake") && win.mine)
                shakeRun.restart();
        }
        function onSparked() {
            if (IslandConfig.s("sparks") && win.mine)
                sparks.play();
        }
    }

    readonly property bool restful:
        IslandConfig.s("sleep") && win.hub.kind === "clock"
        && !win.hub.miniMedia && win.hub.leftKind === ""
        && !win.hovering && !win.wide && !win.hub.pinned
        && !(IslandConfig.s("privacy") && (Privacy.mic || Privacy.camera))

    property bool asleep: false
    onRestfulChanged: if (!win.restful) win.asleep = false

    Timer {
        interval: IslandConfig.s("sleepSec") * 1000
        running: win.restful && !win.asleep && win.visible
        onTriggered: win.asleep = true
    }

    MorphSpring {
        id: doze
        target: win.asleep ? 1 : 0
    }

    property real breath: 0

    SequentialAnimation {
        running: win.asleep && win.visible
        loops: Animation.Infinite
        onStopped: win.breath = 0
        NumberAnimation {
            target: win; property: "breath"
            to: 1; duration: Motion.isleDozeMs / 2
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: win; property: "breath"
            to: 0; duration: Motion.isleDozeMs / 2
            easing.type: Easing.InOutSine
        }
    }

    Item {
        id: comet
        anchors.fill: parent

        property var e: null
        property real lift: 0
        property real t: 0
        property real speed: 0
        property real lastT: 0

        readonly property bool on: comet.e !== null
        visible: comet.on

        readonly property real sw: 340
        readonly property real sh: 64
        readonly property real sx: comet.width - 24 - comet.sw / 2
        readonly property real sy: (Prefs.barAtTop ? 42 : 12) + comet.sh / 2

        property real ex: comet.width / 2
        property real ey: 14
        property real ew: 92
        property real eh: 28

        readonly property string icon: {
            const i = comet.e ? comet.e.icon || "" : "";
            return i === "" ? "" : i.startsWith("/") || i.startsWith("file:") || i.startsWith("image:")
                ? i : Quickshell.iconPath(i, true);
        }

        Connections {
            target: win.hub
            function onIncoming(e) {
                if (!win.lead || !win.visible || !win.atTop || win.blocked)
                    return;
                comet.e = e;
                comet.lastT = 0;
                comet.speed = 0;
                cometRun.restart();
            }
            function onAbsorbed() {
                if (win.mine)
                    win.bump();
            }
        }

        SequentialAnimation {
            id: cometRun
            ScriptAction { script: { comet.t = 0; comet.lift = 0; } }
            NumberAnimation {
                target: comet; property: "lift"
                from: 0; to: 1; duration: Motion.isleCometLiftMs
                easing.type: Easing.OutBack; easing.overshoot: 1.4
            }
            NumberAnimation {
                target: comet; property: "t"
                from: 0; to: 1
                duration: Motion.isleCometMs - Motion.isleCometLiftMs - 20
                easing.type: Easing.InBack; easing.overshoot: 0.8
            }
            ScriptAction { script: comet.e = null }
        }

        FrameAnimation {
            running: comet.on
            onTriggered: {
                const r = surface.mapToItem(comet, 0, 0);
                const q = surface.mapToItem(comet, surface.width, surface.height);
                comet.ew = q.x - r.x;
                comet.eh = q.y - r.y;
                comet.ex = r.x + comet.ew / 2;
                comet.ey = r.y + comet.eh / 2;
                const dt = Math.max(0.001, frameTime);
                comet.speed = comet.speed * 0.6 + 0.4 * Math.abs(comet.t - comet.lastT) / dt;
                comet.lastT = comet.t;
                cometGoo.requestSync();
            }
        }

        readonly property real u: comet.t
        readonly property real kx: Motion.mix(comet.sx, comet.ex, 0.55)
        readonly property real ky: comet.sy + 46
        readonly property real cx:
            (1 - comet.u) * (1 - comet.u) * comet.sx + 2 * (1 - comet.u) * comet.u * comet.kx
            + comet.u * comet.u * comet.ex
        readonly property real cy:
            (1 - comet.u) * (1 - comet.u) * comet.sy + 2 * (1 - comet.u) * comet.u * comet.ky
            + comet.u * comet.u * comet.ey
        readonly property real shrink: Math.pow(Math.max(0, Math.min(1, comet.u)), 1.3)
        readonly property real dw: Math.max(4, Motion.mix(comet.sw, comet.eh * 0.9, comet.shrink) * comet.lift)
        readonly property real dh: Math.max(4, Motion.mix(comet.sh, comet.eh * 0.82, Math.pow(Math.max(0, comet.u), 0.8)) * comet.lift)
        readonly property real stretch: Math.min(0.42, comet.speed * 0.05)

        Item {
            id: cometField
            visible: comet.on
            x: Math.max(0, comet.ex - comet.ew / 2 - 40)
            y: 0
            width: comet.width - cometField.x
            height: comet.sy + comet.sh / 2 + 70

            Item {
                property bool isBlob: true
                x: comet.ex - comet.ew / 2 - cometField.x
                y: comet.ey - comet.eh / 2
                width: comet.ew
                height: comet.eh
            }

            Item {
                id: drop
                property bool isBlob: true
                readonly property real blobScaleX: 1 + comet.stretch
                readonly property real blobScaleY: 1 - comet.stretch * 0.55
                x: comet.cx - comet.dw / 2 - cometField.x
                y: comet.cy - comet.dh / 2
                width: comet.dw
                height: comet.dh
            }
        }

        Blobs {
            id: cometGoo
            host: cometField
            visible: comet.on && count > 0
            fuse: 26
            corner: Math.min(18, stage.pillH / 2)
            stroke: 0
            shadow: false
            fillColor: win.bodyColor
            fillAlpha: IslandConfig.s("fill") / 100
            hoverColor: win.bodyColor
            hoverAlpha: IslandConfig.s("fill") / 100
            strokeAlpha: 0
        }

        RectangularShadow {
            visible: comet.on && comet.lift > 0.01
            x: comet.cx - width / 2
            y: comet.cy - height / 2
            width: comet.dw * (1 + comet.stretch)
            height: comet.dh * (1 - comet.stretch * 0.55)
            radius: Math.min(18, height / 2)
            blur: 18
            color: Colors.alpha(win.hub.notifTint, 0.45 * comet.lift * (1 - comet.shrink * 0.6))
            z: -1
        }

        Item {
            visible: comet.on && opacity > 0.01
            x: comet.cx - comet.dw / 2
            y: comet.cy - comet.dh / 2
            width: comet.dw
            height: comet.dh
            clip: true
            opacity: comet.lift * (1 - Math.min(1, Math.max(0, comet.u) * 2.2))

            Row {
                x: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                IconImage {
                    width: 30
                    height: 30
                    anchors.verticalCenter: parent.verticalCenter
                    source: comet.icon
                    visible: comet.icon !== ""
                    asynchronous: true
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: comet.e ? comet.e.app : ""
                        color: Colors.alpha(Colors.fg, 0.55)
                        font.family: Fonts.display
                        font.pixelSize: 10
                    }
                    Text {
                        width: comet.sw - 74
                        text: comet.e ? comet.e.summary : ""
                        color: Colors.fg
                        font.family: Fonts.display
                        font.pixelSize: 13
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }
                }
            }
        }
    }

    Item {
        id: stage

        readonly property int pillH: IslandConfig.s("pillHeight")
        readonly property int dotSize: stage.pillH
        readonly property int gapPx: IslandConfig.s("minimalGap")

        readonly property bool minimalOn:
            IslandConfig.s("minimal") && win.hub.miniMedia
            && win.hub.kind !== "" && win.hub.kind !== "clock"
            && win.hub.kind !== "media"

        readonly property bool leftOn:
            IslandConfig.s("leftSlot") && win.hub.leftKind !== ""

        readonly property real swallowed: Math.max(morph.value, seek.value)
        readonly property real detach: dotLife.value * (1 - stage.swallowed)
        readonly property real tail:
            stage.detach * (stage.gapPx + stage.dotSize)

        readonly property real headDetach:
            slotLife.value * (1 - stage.swallowed)
        readonly property real head:
            stage.headDetach * (stage.gapPx + stage.dotSize)

        readonly property real dotShow: stage.detach

        readonly property int gap: win.inBar
            ? Math.max(0, Math.round(
                (BarConfig.s("barHeight", win.modelData.name)
                 - stage.pillH) / 2))
            : IslandConfig.s("offsetY")

        width: stage.head + surface.width + stage.tail
        height: surface.height

        anchors.top: win.atTop ? parent.top : undefined
        anchors.bottom: win.atTop ? undefined : parent.bottom
        readonly property real dozeDrop:
            Math.max(doze.value, fold.value) * (stage.pillH - Motion.isleDozeSize) / 2

        anchors.topMargin: win.atTop ? stage.gap + stage.dozeDrop : 0
        anchors.bottomMargin: win.atTop ? 0 : stage.gap + stage.dozeDrop

        anchors.horizontalCenter:
            IslandConfig.s("align") === "center" ? parent.horizontalCenter
                                                 : undefined
        anchors.left:
            IslandConfig.s("align") === "left" ? parent.left : undefined
        anchors.right:
            IslandConfig.s("align") === "right" ? parent.right : undefined

        anchors.horizontalCenterOffset:
            IslandConfig.s("offsetX") + (stage.head - stage.tail) / 2
        anchors.leftMargin: 16 + IslandConfig.s("offsetX") - stage.head
        anchors.rightMargin: 16 - IslandConfig.s("offsetX") + stage.tail

        opacity: birth.value
        scale: (0.90 + 0.10 * birth.value)
               * (1 + (Motion.isleHoverScale - 1) * hoverLift.value)
               * (1 + (Motion.islePeekScale - 1) * peek.value)
               * (1 + (Motion.isleThrobScale - 1) * win.throb)
               * (1 - (1 - Motion.isleTapScale) * press.value
                      * (IslandConfig.s("rubber") ? 0.3 : 1))
               * (1 + 0.22 * win.breath * doze.value)
               * (1 - Motion.isleWindupScale * windup.value)
               * (1 + 0.016 * voice.value)

        readonly property real rush:
            morph.velocity * 0.16
            + seek.velocity * 0.12
            + pillWidth.velocity / 420
            + birth.velocity * 0.12
            + Math.abs(drift.velocity) * 0.10

        readonly property real jelly: IslandConfig.s("jelly")
            ? Math.max(-Motion.isleJellyCap,
                       Math.min(Motion.isleJellyCap,
                                stage.rush * Motion.isleJelly))
              * (win.bigMotion ? 0.35 : 1)
            : 0

        transform: [
            Scale {
                origin.x: stage.width / 2
                origin.y: stage.height / 2
                xScale: 1 + stage.jelly + Motion.isleSquashX * squash.value
                        + 0.016 * magP.value
                yScale: 1 - stage.jelly * Motion.isleJellyCross
                        - Motion.isleSquashY * squash.value
                        + 0.03 * magP.value
            },
            Translate {
                x: win.shakeX + drift.value * 9 + magX.value
                y: magY.value
            }
        ]

        Connections {
            target: surface
            function onWidthChanged() { goo.requestSync(); }
            function onHeightChanged() { goo.requestSync(); }
        }

        Connections {
            target: dot
            function onXChanged() { goo.requestSync(); }
            function onScaleChanged() { goo.requestSync(); }
            function onVisibleChanged() { goo.requestSync(); }
        }

        Connections {
            target: task
            function onXChanged() { goo.requestSync(); }
            function onScaleChanged() { goo.requestSync(); }
            function onVisibleChanged() { goo.requestSync(); }
        }

        Connections {
            target: win
            function onVisibleChanged() {
                if (win.visible)
                    goo.requestSync();
            }
        }

        Component.onCompleted: goo.requestSync()

        ArtTint {
            id: artTint
            x: stage.head + 4
            y: 4
            fallback: Colors.accent
        }

        ArtTint {
            id: callTint
            x: stage.head + 4
            y: 4
            source: win.hub.callIconUrl
            fallback: Colors.accent
        }

        ArtTint {
            id: iconTint
            x: stage.head + 4
            y: 4
            source: win.hub.notifIconUrl
            fallback: win.hub.notifTint
        }

        RectangularShadow {
            id: aura

            readonly property real power:
                IslandConfig.s("glowAlpha") / 100
                * (0.55 + 0.45 * morph.value + 0.55 * win.beat
                   + 0.6 * peek.value + 0.5 * win.throb
                   + 0.9 * win.breath * doze.value
                   + 1.1 * voice.value + 0.35 * magP.value)

            x: surface.x
            y: surface.y
            width: surface.width
            height: surface.height
            radius: surface.corner
            blur: 14 + 16 * morph.value + 8 * win.beat + 10 * voice.value
            spread: -1 + 3 * win.beat + 3 * voice.value
            offset.y: 2 + 4 * morph.value
            color: Colors.alpha(win.tint, Math.min(0.9, aura.power))
            visible: IslandConfig.s("glow") && aura.power > 0.005
            opacity: birth.value

            Behavior on color { ColorAnimation { duration: Motion.slow } }
        }

        Rectangle {
            id: ring

            property real grow: 0

            x: surface.x - ring.grow
            y: surface.y - ring.grow * 0.72
            width: surface.width + ring.grow * 2
            height: surface.height + ring.grow * 1.44
            radius: Math.min(height / 2, surface.corner + ring.grow)
            color: "transparent"
            antialiasing: true
            border.width: 1.5
            border.color: Colors.alpha(win.tint, 0.9)
            opacity: 0
            visible: opacity > 0.01

            ParallelAnimation {
                id: ringRun
                NumberAnimation {
                    target: ring; property: "grow"
                    from: 0; to: 16; duration: 720
                    easing.type: Easing.OutCubic
                }
                SequentialAnimation {
                    NumberAnimation {
                        target: ring; property: "opacity"
                        from: 0; to: 0.75; duration: 90
                    }
                    NumberAnimation {
                        target: ring; property: "opacity"
                        to: 0; duration: 630
                        easing.type: Easing.OutQuad
                    }
                }
            }

            Connections {
                target: win.hub
                function onFlashKindChanged() {
                    if (win.hub.flashKind !== "" && IslandConfig.s("ripple"))
                        ringRun.restart();
                }
            }
        }

        Repeater {
            model: 2

            Rectangle {
                id: leaf
                required property int index
                readonly property int depth: index + 1
                readonly property bool on:
                    win.wide && win.wideKind === "notif"
                    && win.hub.notifTotal - win.hub.notifIndex > leaf.depth
                readonly property real s: 1 - 0.06 * leaf.depth

                width: surface.width * leaf.s
                height: 40
                x: surface.x + (surface.width - width) / 2
                y: surface.y + surface.height - height + 9 * leaf.depth * leaf.show
                z: -leaf.depth
                radius: Math.min(surface.corner, height / 2)
                antialiasing: true
                color: Qt.tint(win.bodyColor, Colors.alpha(win.tint, leaf.depth === 1 ? 0.16 : 0.09))
                border.width: 1
                border.color: Colors.alpha(win.tint, leaf.depth === 1 ? 0.5 : 0.3)
                opacity: (leaf.depth === 1 ? 0.95 : 0.75) * leaf.show * morph.value

                property real show: leaf.on ? 1 : 0
                Behavior on show { SpringAnimation { spring: 3; damping: 0.32; mass: 0.8; epsilon: 0.005 } }
                visible: opacity > 0.01
            }
        }

        Blobs {
            id: goo
            host: stage
            visible: IslandConfig.s("goo") && count > 0
            fuse: Math.max(6, stage.gapPx * 1.2)
            corner: surface.corner
            stroke: IslandConfig.s("borderAlpha") > 0 || win.hearing || win.voicing ? 1.5 : 0
            shadow: IslandConfig.s("shadow")
            shadowColor: IslandConfig.s("tintShadow")
                ? Colors.alpha(Qt.darker(win.tint, 1.8), 0.40)
                : Qt.rgba(0, 0, 0, 0.32)
            fillColor: win.bodyColor
            fillAlpha: IslandConfig.s("fill") / 100
            hoverColor: win.bodyColor
            hoverAlpha: IslandConfig.s("fill") / 100
            strokeColor: win.tint
            strokeAlpha: win.edgeAlpha
        }

        Item {
            id: surface

            readonly property real bareW:
                Motion.mix(pillWidth.value, wideSpan.value, morph.value)
            readonly property real bareH:
                Motion.mix(stage.pillH, wideTall.value, morph.value)
            readonly property real seekW:
                Motion.mix(surface.bareW, IslandBus.searchW, seek.value)
            readonly property real seekH:
                Motion.mix(surface.bareH, IslandBus.searchH, seek.value)

            readonly property real dot: Math.max(doze.value, fold.value)
            width: Math.round(Motion.mix(
                Motion.mix(stage.pillH, surface.seekW, birth.value),
                Motion.isleDozeSize, surface.dot))
            height: Math.round(Motion.mix(surface.seekH,
                                          Motion.isleDozeSize, surface.dot))

            readonly property real corner:
                Math.min(IslandConfig.s("radius"), surface.height / 2)

            property bool isBlob: true

            anchors.left: stage.left
            anchors.leftMargin: stage.head
            anchors.top: stage.top

            Rectangle {
                id: plate
                anchors.fill: parent
                visible: !IslandConfig.s("goo") || goo.count <= 0
                radius: surface.corner
                antialiasing: true
                color: Colors.alpha(win.bodyColor, IslandConfig.s("fill") / 100)
                border.width: IslandConfig.s("borderAlpha") > 0 || win.hearing || win.voicing ? 1.5 : 0
                border.color: Colors.alpha(win.tint, win.edgeAlpha)

                Behavior on color { ColorAnimation { duration: Motion.base } }
                Behavior on border.color { ColorAnimation { duration: Motion.base } }

                layer.enabled: IslandConfig.s("shadow")
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: IslandConfig.s("tintShadow")
                        ? Colors.alpha(Qt.darker(win.tint, 1.8), 0.46)
                        : Colors.shadow(0.38)
                    shadowBlur: 0.62
                    shadowVerticalOffset: 4

                    Behavior on shadowColor {
                        ColorAnimation { duration: Motion.slow }
                    }
                }
            }

            Sheen {
                anchors.fill: parent
                visible: IslandConfig.s("sheen")
                radius: surface.corner
                border: false
                grain: false
                strength: 0.6
            }

            IslandRim {
                anchors.fill: parent
                radius: surface.corner
                thickness: IslandConfig.s("rimWidth")
                tint: win.tint
                value: win.rimValue
                busy: win.rimBusy
                shimmer: win.ringing || win.hub.wallBusy || win.chiming
                         || (IslandConfig.s("shimmer") && win.hub.taskLong
                             && win.hub.leftKind === "task" && win.hub.taskResult === "")
                shimmerMs: win.ringing ? 1800 : win.hub.wallBusy ? 2200
                         : win.chiming ? 2600 : 5200
            }

            HoverHandler {
                onHoveredChanged: win.pointerIn = hovered
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: (ev) => {
                    const dy = ev.angleDelta.y;
                    if (win.wide && win.wideKind === "notif" && win.hub.notifTotal > 1
                        && !(dy > 0 && win.hub.notifIndex === 0)) {
                        const now = Date.now();
                        if (now - win.wheelAt < 240)
                            return;
                        win.wheelAt = now;
                        win.hub.scrollNotif(dy < 0 ? 1 : -1);
                        return;
                    }
                    if (dy > 0 && win.wide) {
                        win.hub.mediaBig = false;
                        force.stop();
                        win.forced = false;
                        win.hushed = true;
                        win.bump();
                    } else if (dy < 0 && !win.wide && win.wideKind !== "") {
                        win.hushed = false;
                        win.forced = true;
                        force.restart();
                    }
                }
            }

            TapHandler {
                onPressedChanged: win.pressed = pressed
                onTapped: {
                    if (win.hub.kind === "call" && win.hub.callState === "live") {
                        win.hub.focusCall();
                        return;
                    }
                    if (win.hub.kind === "download") {
                        win.hub.openDownload();
                        return;
                    }
                    if (win.hub.kind === "cmd" && !win.wide && win.hub.cmd.win !== "") {
                        win.hub.focusWindow(win.hub.cmd.win);
                        win.hub.dismiss();
                        return;
                    }
                    if (win.hub.kind !== "gta"
                        && !(IslandConfig.s("tapWide") && win.wideKind !== ""))
                        return;
                    if (win.hub.kind === "gta") {
                        Quickshell.execDetached(["hyprctl", "dispatch", "global", "quickshell:gtavi"]);
                        win.hub.gtaOn = false;
                        return;
                    }
                    if (win.forced) {
                        force.stop();
                        win.forced = false;
                    } else {
                        win.forced = true;
                        force.restart();
                    }
                    win.bump();
                }
            }

            TapHandler {
                acceptedButtons: Qt.RightButton
                enabled: win.hub.kind === "call" && win.hub.callState === "live"
                onTapped: win.hub.endCall()
            }

            ClippingRectangle {
                anchors.fill: parent
                radius: surface.corner
                color: "transparent"
                opacity: Math.max(0, 1 - surface.dot * 1.6)
                visible: opacity > 0.01

                Rectangle {
                    id: gloss

                    readonly property real span:
                        Math.max(64, parent.width * 0.34)

                    width: gloss.span
                    height: parent.height * 2.4
                    anchors.verticalCenter: parent.verticalCenter
                    rotation: 16
                    transformOrigin: Item.Center
                    opacity: 0
                    visible: opacity > 0.01

                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop {
                            position: 0.5
                            color: Colors.alpha(Colors.fg,
                                                Motion.isleGlossAlpha)
                        }
                        GradientStop { position: 1.0; color: "transparent" }
                    }

                    SequentialAnimation {
                        id: shine
                        ParallelAnimation {
                            NumberAnimation {
                                target: gloss; property: "x"
                                from: -gloss.span
                                to: surface.width + gloss.span
                                duration: Motion.isleGlossMs
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.isleContent
                            }
                            SequentialAnimation {
                                NumberAnimation {
                                    target: gloss; property: "opacity"
                                    to: 1
                                    duration: Motion.isleGlossMs * 0.25
                                }
                                NumberAnimation {
                                    target: gloss; property: "opacity"
                                    to: 0
                                    duration: Motion.isleGlossMs * 0.75
                                }
                            }
                        }
                    }

                    Connections {
                        target: win
                        function onWideChanged() {
                            if (win.wide && IslandConfig.s("sheen"))
                                shine.restart();
                        }
                    }
                }

                Item {
                    id: liquid
                    anchors.fill: parent

                    property real level: 0
                    property real k: 0
                    property real phase: 0

                    visible: liquid.k > 0.005
                    readonly property real surfaceY:
                        liquid.height * (1 - liquid.level * liquid.k)
                    readonly property real amp: 2.6 * liquid.k

                    readonly property var crest: {
                        const pts = [];
                        const n = 28;
                        for (let i = 0; i <= n; i++) {
                            const x = liquid.width * i / n;
                            pts.push(Qt.point(x, liquid.surfaceY
                                + liquid.amp * Math.sin(liquid.phase + i / n * Math.PI * 3)));
                        }
                        return pts;
                    }
                    readonly property var body: liquid.crest.concat([
                        Qt.point(liquid.width, liquid.height + 2),
                        Qt.point(0, liquid.height + 2)
                    ])

                    NumberAnimation on phase {
                        running: liquid.visible
                        loops: Animation.Infinite
                        from: 0
                        to: Math.PI * 2
                        duration: 900
                    }

                    SequentialAnimation {
                        id: pour
                        NumberAnimation {
                            target: liquid; property: "k"
                            from: 0; to: 1; duration: 620
                            easing.type: Easing.OutCubic
                        }
                        PauseAnimation { duration: 700 }
                        NumberAnimation {
                            target: liquid; property: "k"
                            to: 0; duration: 700
                            easing.type: Easing.InCubic
                        }
                    }

                    Connections {
                        target: win.hub
                        function onPoured(level) {
                            if (!IslandConfig.s("liquid") || !win.mine)
                                return;
                            liquid.level = Math.max(0.12, Math.min(1, level));
                            pour.restart();
                        }
                    }

                    Vec.Shape {
                        anchors.fill: parent
                        preferredRendererType: Vec.Shape.CurveRenderer

                        Vec.ShapePath {
                            strokeColor: "transparent"
                            strokeWidth: 0
                            fillGradient: Vec.LinearGradient {
                                x1: 0; y1: liquid.surfaceY
                                x2: 0; y2: liquid.height
                                GradientStop { position: 0; color: Colors.alpha(Colors.good, 0.55) }
                                GradientStop { position: 1; color: Colors.alpha(Qt.darker(Colors.good, 1.6), 0.45) }
                            }
                            PathPolyline { path: liquid.body }
                        }

                        Vec.ShapePath {
                            strokeColor: Colors.alpha(Qt.lighter(Colors.good, 1.5), 0.85)
                            strokeWidth: 1.4
                            fillColor: "transparent"
                            PathPolyline { path: liquid.crest }
                        }
                    }
                }

                Item {
                    id: glint
                    anchors.fill: parent
                    visible: IslandConfig.s("glint")

                    function clamp(v) { return Math.max(0, Math.min(1, v)); }

                    readonly property real grow: glint.clamp(pillWidth.velocity / 520)
                    readonly property real down: glint.clamp(morph.velocity / 4)
                    readonly property real eastward:
                        glint.clamp(drift.velocity / 7 + glint.grow)
                    readonly property real westward:
                        glint.clamp(-drift.velocity / 7 + glint.grow)
                    readonly property color ink: Qt.lighter(win.tint, 1.45)
                    readonly property real depth: Math.min(16, height * 0.42)
                    readonly property real reach: Math.min(22, width * 0.18)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        height: glint.depth
                        opacity: 0.38 * glint.down
                        visible: opacity > 0.01
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: glint.ink }
                        }
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.right: parent.right
                        width: glint.reach
                        opacity: 0.45 * glint.eastward
                        visible: opacity > 0.01
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 1.0; color: glint.ink }
                        }
                    }

                    Rectangle {
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.left: parent.left
                        width: glint.reach
                        opacity: 0.45 * glint.westward
                        visible: opacity > 0.01
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: glint.ink }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                    }
                }

                Rectangle {
                    id: blot

                    property real size: 0

                    x: surface.width / 2
                       - Math.min(pill.eventW,
                                  Math.max(0, surface.width - 24 - pill.sideRoom * 2)) / 2
                       + pill.markW / 2 - blot.size / 2
                    y: surface.height / 2 - blot.size / 2
                    width: blot.size
                    height: blot.size
                    radius: blot.size / 2
                    color: win.tint
                    opacity: 0
                    visible: opacity > 0.005

                    ParallelAnimation {
                        id: blotRun
                        NumberAnimation {
                            target: blot; property: "size"
                            from: 0
                            to: Math.hypot(surface.width, surface.height) * 2.2
                            duration: 720
                            easing.type: Easing.OutCubic
                        }
                        SequentialAnimation {
                            NumberAnimation {
                                target: blot; property: "opacity"
                                to: 0.22; duration: 90
                            }
                            NumberAnimation {
                                target: blot; property: "opacity"
                                to: 0; duration: 630
                                easing.type: Easing.InQuad
                            }
                        }
                    }

                    Connections {
                        target: win.hub
                        function onFlashKindChanged() {
                            if (win.hub.flashKind !== "" && IslandConfig.s("blot") && win.mine)
                                blotRun.restart();
                        }
                        function onWallDone(tone) {
                            if (win.mine)
                                blotRun.restart();
                        }
                    }
                }

                Rectangle {
                    id: shutter
                    anchors.fill: parent
                    color: "white"
                    opacity: 0
                    visible: opacity > 0.01

                    SequentialAnimation {
                        id: shutterRun
                        NumberAnimation {
                            target: shutter; property: "opacity"
                            to: 0.9; duration: 60
                        }
                        NumberAnimation {
                            target: shutter; property: "opacity"
                            to: 0; duration: 520
                            easing.type: Easing.OutCubic
                        }
                    }

                    Connections {
                        target: win.hub
                        function onSnapped() {
                            if (win.mine)
                                shutterRun.restart();
                        }
                    }
                }

                IslandSand {
                    anchors.fill: parent
                    readonly property var tm: Timers.soonest
                    readonly property bool want: IslandConfig.on("timer") && Timers.anyRunning
                        && !win.seeking && (!win.wide || win.wideKind === "timer")
                    level: tm ? Timers.progress(tm) : 0
                    hot: tm ? Timers.left(tm) <= 10 : false
                    tint: Colors.accentAlt
                    live: opacity > 0.01
                    opacity: want ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutSine } }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: surface.corner
                    color: "transparent"
                    border.width: 1.5
                    border.color: Colors.warn
                    property real breath: 0
                    SequentialAnimation on breath {
                        running: Keyboard.caps && win.visible
                        loops: Animation.Infinite
                        NumberAnimation { to: 1; duration: 1600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0.3; duration: 1600; easing.type: Easing.InOutSine }
                    }
                    property real lit: Keyboard.caps ? 1 : 0
                    Behavior on lit { NumberAnimation { duration: 500; easing.type: Easing.InOutSine } }
                    opacity: lit * (0.35 + 0.45 * breath)
                    visible: opacity > 0.01
                }

                Rectangle {
                    anchors.fill: parent
                    radius: surface.corner
                    color: "white"
                    opacity: 0.16 * win.chimeGlow
                    visible: opacity > 0.003
                }

                IslandPill {
                    id: pill
                    anchors.centerIn: parent
                    height: stage.pillH
                    maxWidth: surface.width
                    notifApp: win.hub.notifApp
                    notifIconUrl: win.hub.notifIconUrl
                    clipImage: win.hub.flashKind === "shot" && win.hub.shotPath !== ""
                        ? "file://" + win.hub.shotPath : win.hub.clipImage
                    deskDir: win.hub.deskDir

                    tint: win.tint
                    mediaTint: win.mediaTint
                    beat: win.beat
                    readonly property bool gta: win.hub.flashKind === "" && win.hub.kind === "gta"
                    readonly property bool talk: win.hub.flashKind === "" && win.hub.kind === "call"
                    flashKind: gta ? "gta" : talk ? "call" : win.hub.flashKind
                    flashGlyph: gta ? "󰔛" : talk ? "󰏲" : win.hub.flashGlyph
                    flashText: gta ? win.hub.gtaShort
                             : talk ? (win.hub.callState === "live" ? win.hub.callClock
                                                                    : (win.hub.call ? win.hub.call.name : ""))
                             : win.hub.flashText
                    flashFraction: gta || talk ? -1 : win.hub.flashFraction
                    kind: win.hub.kind
                    stacked: win.hub.stacked
                    miniMedia: win.hub.miniMedia && !stage.minimalOn

                    readonly property real bigFade: {
                        const k = Math.max(0, Math.min(1, (0.32 - morph.value) / 0.28));
                        return k * k * (3 - 2 * k);
                    }
                    opacity: win.bigMotion && !win.seeking ? pill.bigFade
                           : win.wide || win.seeking ? 0 : 1
                    scale: win.wide || win.seeking ? 0.92 : 1
                    visible: opacity > 0.01

                    transform: Translate {
                        y: win.wide || win.seeking ? -7 : 0
                        Behavior on y {
                            NumberAnimation {
                                duration: win.wide || win.seeking ? Motion.isleHideMs
                                                   : Motion.isleRevealMs
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.isleContent
                            }
                        }
                    }

                    Behavior on opacity {
                        enabled: !win.bigMotion
                        SequentialAnimation {
                            PauseAnimation {
                                duration: win.wide || win.seeking ? 0 : Motion.isleRevealDelay
                            }
                            NumberAnimation {
                                duration: win.wide || win.seeking ? Motion.isleHideMs
                                                   : Motion.isleRevealMs
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.isleContent
                            }
                        }
                    }
                    Behavior on scale {
                        SequentialAnimation {
                            PauseAnimation {
                                duration: win.wide || win.seeking ? 0 : Motion.isleRevealDelay
                            }
                            NumberAnimation {
                                duration: win.wide || win.seeking ? Motion.isleHideMs
                                                   : Motion.isleRevealMs
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.isleContent
                            }
                        }
                    }
                }

                IslandSearch {
                    anchors.fill: parent
                    active: win.seeking
                    tint: win.tint
                    opacity: win.seeking ? Math.min(1, Math.max(0, (seek.value - 0.45) * 2.2)) : 0
                    visible: opacity > 0.01
                    Behavior on opacity {
                        enabled: !win.seeking
                        NumberAnimation { duration: 120 }
                    }
                }

                IslandBody {
                    anchors.fill: parent
                    anchors.margins: 12
                    id: body
                    kind: win.wideKind
                    tint: win.tint
                    wide: win.opened
                    big: win.big
                    opacity: {
                        if (!win.bigMotion)
                            return 1;
                        const k = Math.max(0, Math.min(1, (morph.value - 0.3) / 0.55));
                        return k * k * (3 - 2 * k);
                    }
                    notifSummary: win.hub.notifSummary
                    notifBody: win.hub.notifBody
                    notifApp: win.hub.notifApp
                    notifImage: win.hub.notifImage
                    notifIcon: win.hub.notifIcon
                    notifCount: win.hub.notifCount
                    notifLive: win.hub.notifLive
                    notifTools: win.notifTools
                    notifReplying: win.replying
                    notifNear: win.hovering
                    onNotifReply: (on) => win.hub.replyOn = on ? win.modelData.name : ""
                    onNotifDone: win.hub.doneNotif()
                    notifPage: win.hub.notifIndex
                    notifTotal: win.hub.notifTotal
                    call: win.hub.call
                    onCallAccept: win.hub.acceptCall()
                    onCallDecline: win.hub.declineCall()
                    clipImage: win.hub.clipImage
                    clipText: win.hub.flashKind === "clip" ? win.hub.flashText : ""
                    demo: win.hub.demo
                    cmd: win.hub.cmd
                    cmdTook: win.hub.cmdTook
                    shotPath: win.hub.shotPath
                    skyInfo: win.hub.skyInfo
                    onFocusWin: (w) => {
                        win.hub.focusWindow(w);
                        win.hub.dismiss();
                    }
                    onDismissed: win.hub.dismiss()
                }

                Item {
                    id: hero
                    anchors.fill: parent

                    property string mode: ""
                    property Item src: null
                    property Item dst: null
                    property bool back: false
                    property real land: 0
                    property string glyph: ""
                    property string image: ""
                    property color hue: win.tint
                    property bool waiting: false

                    property real fx: 0
                    property real fy: 0
                    property real fw: 0
                    property real fh: 0
                    property real tx: 0
                    property real ty: 0
                    property real tw: 0
                    property real th: 0
                    property real fr: 0
                    property real tr: 0

                    readonly property real t: heroRun.value
                    readonly property real k: Math.max(0, Math.min(1, hero.t))

                    MorphSpring {
                        id: heroRun
                        response: 0.50
                        damping: win.bigMotion ? 0.92 : 0.70
                        closeMs: 300
                        softClose: true
                        target: 0
                    }

                    function rectOf(it) {
                        const a = it.mapToItem(hero, 0, 0);
                        const b = it.mapToItem(hero, it.width, it.height);
                        return { x: a.x, y: a.y, w: b.x - a.x, h: b.y - a.y };
                    }

                    function pick() {
                        const k = win.wideKind;
                        if (k === "media")
                            return pill.miniMedia ? { mode: "art", src: pill.artItem } : null;
                        if (!pill.flashing || pill.flashKind !== k)
                            return null;
                        if (k === "osd" || k === "desk" || k === "keys")
                            return null;
                        if (k === "notif")
                            return { mode: win.hub.notifIconUrl !== "" ? "icon" : "letter",
                                     src: pill.markItem };
                        if (pill.thumbFlash)
                            return { mode: "thumb", src: pill.markItem };
                        return { mode: "glyph", src: pill.markItem };
                    }

                    function veil(on) {
                        if (!hero.src)
                            return;
                        if (hero.src === pill.artItem)
                            pill.artVeil = on ? 0 : 1;
                        else
                            pill.markVeil = on ? 0 : 1;
                    }

                    function release() {
                        if (hero.dst)
                            hero.dst.opacity = 1;
                        hero.veil(false);
                        hero.mode = "";
                        hero.waiting = false;
                        hero.land = 0;
                        landRun.stop();
                        giveUp.stop();
                    }

                    function launch() {
                        hero.release();
                        if (!IslandConfig.s("hero") || !win.lead)
                            return;
                        const p = hero.pick();
                        if (!p || !p.src)
                            return;
                        hero.src = p.src;
                        hero.mode = p.mode;
                        hero.back = false;
                        hero.dst = null;
                        hero.glyph = pill.flashGlyph;
                        hero.image = p.mode === "thumb" ? pill.clipImage : "";
                        hero.hue = win.tint;
                        hero.fr = p.mode === "art" ? hero.src.width * 0.3
                                : p.mode === "glyph" ? hero.src.height * 0.3
                                : hero.src.height * 0.32;
                        heroRun.settle(0);
                        hero.track();
                        hero.veil(true);
                        hero.waiting = true;
                        giveUp.restart();
                        hero.seek();
                    }

                    function seek() {
                        if (!hero.waiting)
                            return;
                        const d = body.heroItem;
                        if (d) {
                            hero.waiting = false;
                            giveUp.stop();
                            hero.dst = d;
                            d.opacity = 0;
                            hero.tr = body.heroRadius >= 0 ? body.heroRadius
                                    : d.rad !== undefined ? d.rad
                                    : d.radius !== undefined ? d.radius
                                    : d.height * 0.28;
                            hero.track();
                            heroRun.target = 1;
                        } else if (body.cardReady) {
                            hero.release();
                        }
                    }

                    function recall() {
                        if (hero.mode !== "" && hero.back)
                            return;
                        const midway = hero.mode !== "" && !hero.waiting;
                        landRun.stop();
                        if (!IslandConfig.s("hero") || !win.lead || !hero.dst || !hero.src) {
                            hero.release();
                            return;
                        }
                        const p = hero.pick();
                        if (!p || p.src !== hero.src) {
                            hero.release();
                            return;
                        }
                        hero.mode = p.mode;
                        hero.back = true;
                        hero.land = 0;
                        hero.dst.opacity = 0;
                        hero.veil(true);
                        hero.track();
                        if (!midway)
                            heroRun.settle(1);
                        heroRun.target = 0;
                    }

                    function track() {
                        if (hero.src) {
                            const a = hero.rectOf(hero.src);
                            hero.fx = a.x; hero.fy = a.y; hero.fw = a.w; hero.fh = a.h;
                        }
                        if (hero.dst && hero.dst.parent) {
                            const b = hero.rectOf(hero.dst);
                            hero.tx = b.x; hero.ty = b.y; hero.tw = b.w; hero.th = b.h;
                        } else if (!hero.dst) {
                            hero.tx = hero.fx; hero.ty = hero.fy;
                            hero.tw = hero.fw; hero.th = hero.fh;
                        }
                    }

                    Timer {
                        id: giveUp
                        interval: 420
                        onTriggered: hero.release()
                    }

                    Connections {
                        target: body
                        function onHeroItemChanged() {
                            if (hero.waiting) {
                                hero.seek();
                                return;
                            }
                            if (hero.mode !== "" && !hero.back && hero.dst !== body.heroItem)
                                hero.release();
                        }
                        function onCardReadyChanged() { hero.seek(); }
                    }

                    Connections {
                        target: win
                        function onOpenedChanged() {
                            if (win.opened)
                                hero.launch();
                            else
                                hero.recall();
                        }
                    }

                    FrameAnimation {
                        running: hero.mode !== "" && win.visible
                        onTriggered: {
                            hero.track();
                            if (hero.waiting)
                                return;
                            if (!hero.back) {
                                if (!landRun.running && hero.land === 0
                                    && heroRun.value > 0.96 && Math.abs(heroRun.velocity) < 1.2)
                                    landRun.restart();
                            } else if (!heroRun.running && heroRun.value <= 0.001) {
                                hero.release();
                            }
                        }
                    }

                    NumberAnimation {
                        id: landRun
                        target: hero; property: "land"
                        from: 0; to: 1; duration: 170
                        easing.type: Easing.InOutSine
                        onFinished: hero.release()
                    }
                    onLandChanged: if (hero.dst && hero.mode !== "") hero.dst.opacity = hero.land

                    readonly property real fcx: hero.fx + hero.fw / 2
                    readonly property real fcy: hero.fy + hero.fh / 2
                    readonly property real tcx: hero.tx + hero.tw / 2
                    readonly property real tcy: hero.ty + hero.th / 2
                    readonly property real u: hero.t
                    readonly property real cx:
                        (1 - u) * (1 - u) * hero.fcx + 2 * (1 - u) * u * hero.tcx + u * u * hero.tcx
                    readonly property real cy:
                        (1 - u) * (1 - u) * hero.fcy + 2 * (1 - u) * u * hero.fcy + u * u * hero.tcy
                    readonly property real w: Motion.mix(hero.fw, hero.tw, hero.t)
                    readonly property real h: Motion.mix(hero.fh, hero.th, hero.t)
                    readonly property real r: Math.max(0, Math.min(Math.min(hero.w, hero.h) / 2,
                                                       Motion.mix(hero.fr, hero.tr, hero.k)))

                    RectangularShadow {
                        visible: flyer.visible && hero.k > 0.02 && hero.k < 0.98
                        x: flyer.x
                        y: flyer.y
                        width: flyer.width
                        height: flyer.height
                        radius: hero.r
                        blur: 14
                        spread: 1
                        color: Colors.alpha(hero.hue, 0.55 * Math.sin(Math.PI * hero.k))
                    }

                    Item {
                        id: flyer
                        visible: hero.mode !== "" && !hero.waiting && hero.w > 1
                        x: hero.cx - hero.w / 2
                        y: hero.cy - hero.h / 2
                        width: hero.w
                        height: hero.h
                        opacity: 1 - hero.land

                        Rectangle {
                            anchors.fill: parent
                            visible: hero.mode === "glyph" || hero.mode === "letter"
                            radius: hero.r
                            antialiasing: true
                            opacity: hero.mode === "letter" ? 1 : hero.k
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.lighter(hero.hue, 1.22) }
                                GradientStop { position: 1.0; color: Qt.darker(hero.hue, 1.55) }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: hero.mode === "glyph"
                            text: hero.glyph
                            font.family: Fonts.glyph
                            font.pixelSize: Math.max(8, Math.round(Motion.mix(14, hero.th * 0.46, hero.k)))
                            color: Qt.rgba(Motion.mix(hero.hue.r, 1, hero.k),
                                           Motion.mix(hero.hue.g, 1, hero.k),
                                           Motion.mix(hero.hue.b, 1, hero.k), 1)
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: hero.mode === "letter"
                            text: NotifHistory.appLetter(win.hub.notifApp)
                            color: "white"
                            font.family: Fonts.display
                            font.pixelSize: Math.max(8, Math.round(parent.height * 0.45))
                            font.weight: Font.Bold
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            visible: hero.mode === "art" || hero.mode === "thumb" || hero.mode === "icon"
                            radius: hero.r
                            color: hero.mode === "art" ? Colors.alpha(win.mediaTint, 0.28) : "transparent"

                            Image {
                                anchors.fill: parent
                                visible: hero.mode === "art" && Media.art !== ""
                                source: hero.mode === "art" ? Media.art : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 160
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: hero.mode === "art" && Media.art === ""
                                text: "󰎈"
                                color: win.mediaTint
                                font.family: Fonts.glyph
                                font.pixelSize: Math.max(8, parent.width * 0.55)
                            }

                            Image {
                                anchors.fill: parent
                                visible: hero.mode === "thumb"
                                source: hero.mode === "thumb" ? hero.image : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: false
                                sourceSize.width: 160
                            }

                            IconImage {
                                anchors.fill: parent
                                visible: hero.mode === "icon"
                                source: hero.mode === "icon" ? win.hub.notifIconUrl : ""
                                asynchronous: true
                            }

                            Image {
                                anchors.fill: parent
                                visible: hero.mode === "icon" && win.hub.notifImage !== ""
                                opacity: hero.k
                                source: hero.mode === "icon" ? win.hub.notifImage : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 84
                            }
                        }
                    }
                }

            }
        }

        Item {
            id: trail
            anchors.fill: parent
            visible: IslandConfig.s("trail") && trail.speed > 0.02

            readonly property real speed: Math.min(1,
                Math.abs(morph.velocity) / 3 + Math.abs(pillWidth.velocity) / 800)

            property var samples: []
            property bool chasing: false
            property var echoA: ({ w: 0, h: 0 })
            property var echoB: ({ w: 0, h: 0 })

            readonly property bool moving: morph.running || pillWidth.running

            onMovingChanged: if (trail.moving) trail.chasing = true

            function at(age, now) {
                const s = trail.samples;
                let pick = s[0];
                for (const p of s) {
                    if (now - p.at >= age)
                        pick = p;
                    else
                        break;
                }
                return pick;
            }

            FrameAnimation {
                running: trail.chasing && win.visible && IslandConfig.s("trail")
                onTriggered: {
                    const now = Date.now();
                    const s = trail.samples;
                    s.push({ at: now, w: surface.width, h: surface.height });
                    while (s.length > 2 && now - s[1].at > 100)
                        s.shift();
                    const a = trail.at(45, now);
                    const b = trail.at(90, now);
                    trail.echoA = { w: a.w, h: a.h };
                    trail.echoB = { w: b.w, h: b.h };
                    if (!trail.moving && b.w === surface.width && b.h === surface.height) {
                        trail.samples = [];
                        trail.chasing = false;
                    }
                }
            }

            Repeater {
                model: 2

                Rectangle {
                    required property int index
                    readonly property var e: index === 0 ? trail.echoA : trail.echoB

                    x: stage.head + surface.width / 2 - width / 2
                    y: surface.y
                    width: Math.max(0, e.w)
                    height: Math.max(0, e.h)
                    radius: Math.min(IslandConfig.s("radius"), height / 2)
                    color: "transparent"
                    antialiasing: true
                    border.width: 1.2
                    border.color: Qt.lighter(win.tint, 1.3)
                    opacity: trail.speed * (index === 0 ? 0.55 : 0.28)
                }
            }
        }

        Repeater {
            id: waves
            model: 3

            Rectangle {
                id: wave
                required property int index
                property real grow: 0
                property color hue: win.hub.wallTone

                x: surface.x - wave.grow
                y: surface.y - wave.grow * 0.7
                width: surface.width + wave.grow * 2
                height: surface.height + wave.grow * 1.4
                radius: Math.min(height / 2, surface.corner + wave.grow)
                color: "transparent"
                antialiasing: true
                border.width: 2 - wave.index * 0.4
                border.color: Colors.alpha(wave.hue, 0.95)
                opacity: 0
                visible: opacity > 0.01

                SequentialAnimation {
                    id: waveRun
                    PauseAnimation { duration: 150 + wave.index * 210 }
                    ParallelAnimation {
                        NumberAnimation {
                            target: wave; property: "grow"
                            from: 0; to: 120 + wave.index * 30
                            duration: 1250
                            easing.type: Easing.OutCubic
                        }
                        SequentialAnimation {
                            NumberAnimation { target: wave; property: "opacity"; from: 0; to: 0.85 - wave.index * 0.18; duration: 110 }
                            NumberAnimation { target: wave; property: "opacity"; to: 0; duration: 1140; easing.type: Easing.OutQuad }
                        }
                    }
                }

                Connections {
                    target: win.hub
                    function onWallSpread(tone) {
                        if (!win.mine)
                            return;
                        wave.hue = tone;
                        waveRun.restart();
                    }
                    function onWallDone(tone) {
                        if (!win.mine || wave.index > 0)
                            return;
                        wave.hue = tone;
                        waveRun.restart();
                    }
                }
            }
        }

        IslandBurst {
            id: sparks
            autoplay: false
            count: 14
            reach: 34
            delay: Motion.isleRevealDelay + 60
            tint: win.tint
            x: stage.head + surface.width / 2
               - Math.min(pill.eventW,
                          Math.max(0, surface.width - 24 - pill.sideRoom * 2)) / 2
               + pill.markW / 2
            y: surface.y + surface.height / 2
        }

        Item {
            id: dot

            property bool isBlob: true

            property real wobP: 1
            readonly property real wob: dot.wobP >= 1 ? 0
                : Math.exp(-4.2 * dot.wobP)
                  * Math.sin(dot.wobP * Math.PI * 3.5) * 0.22
            readonly property real blobScaleX: 1 + dot.wob
            readonly property real blobScaleY: 1 - dot.wob * 0.8
            onWobChanged: goo.requestSync()

            transform: Scale {
                origin.x: dot.width / 2
                origin.y: dot.height / 2
                xScale: dot.blobScaleX
                yScale: dot.blobScaleY
            }

            NumberAnimation {
                id: dotWob
                target: dot; property: "wobP"
                from: 0; to: 1; duration: 620
            }

            property bool armed: true
            Connections {
                target: dotLife
                function onValueChanged() {
                    if (dotLife.value < 0.4)
                        dot.armed = true;
                    else if (dot.armed && dotLife.value > 0.86
                             && IslandConfig.s("goo")) {
                        dot.armed = false;
                        dotWob.restart();
                    }
                }
            }

            width: stage.dotSize
            height: stage.dotSize
            x: stage.head + surface.width - stage.dotSize
               + stage.detach * (stage.gapPx + stage.dotSize)
            anchors.verticalCenter: surface.verticalCenter

            readonly property real swallow: 1 - stage.swallowed

            visible: stage.dotShow > 0.015
            scale: (0.4 + 0.6 * dotLife.value) * dot.swallow
            opacity: Math.min(1, dotLife.value * 1.6) * dot.swallow

            Rectangle {
                anchors.fill: parent
                visible: !IslandConfig.s("goo") || goo.count <= 0
                radius: height / 2
                antialiasing: true
                color: Colors.alpha(win.bodyColor, IslandConfig.s("fill") / 100)
                border.width: IslandConfig.s("borderAlpha") > 0 ? 1 : 0
                border.color: Colors.alpha(win.tint,
                                           IslandConfig.s("borderAlpha") / 100)
            }

            IslandOrb {
                anchors.centerIn: parent
                size: Math.max(12, stage.dotSize - 6)
                tint: win.mediaTint
                live: dot.visible
            }
        }

        Item {
            id: task

            property bool isBlob: true

            property real wobP: 1
            readonly property real wob: task.wobP >= 1 ? 0
                : Math.exp(-4.2 * task.wobP)
                  * Math.sin(task.wobP * Math.PI * 3.5) * 0.22
            readonly property real blobScaleX: 1 + task.wob
            readonly property real blobScaleY: 1 - task.wob * 0.8
            onWobChanged: goo.requestSync()

            transform: Scale {
                origin.x: task.width / 2
                origin.y: task.height / 2
                xScale: task.blobScaleX
                yScale: task.blobScaleY
            }

            NumberAnimation {
                id: taskWob
                target: task; property: "wobP"
                from: 0; to: 1; duration: 620
            }

            property bool armed: true
            Connections {
                target: slotLife
                function onValueChanged() {
                    if (slotLife.value < 0.4)
                        task.armed = true;
                    else if (task.armed && slotLife.value > 0.86
                             && IslandConfig.s("goo")) {
                        task.armed = false;
                        taskWob.restart();
                    }
                }
            }

            width: stage.dotSize
            height: stage.dotSize
            x: stage.head - stage.headDetach * (stage.gapPx + stage.dotSize)
            anchors.verticalCenter: surface.verticalCenter

            readonly property real swallow: 1 - stage.swallowed

            visible: stage.headDetach > 0.015
            scale: (0.4 + 0.6 * slotLife.value) * task.swallow
            opacity: Math.min(1, slotLife.value * 1.6) * task.swallow

            readonly property color hue: {
                switch (win.hub.leftKind) {
                case "print": return Colors.accentAlt;
                case "task":
                    return win.hub.taskResult === "ok" ? Colors.good
                         : win.hub.taskResult === "bad" ? Colors.bad
                         : Colors.accentAlt;
                case "download":
                    return win.hub.downloadPhase === "ok" ? Colors.good : Colors.accent;
                case "launch":
                    return win.hub.launchPhase === "ok" ? Colors.good
                         : win.hub.launchPhase === "bad" ? Colors.bad
                         : win.hub.launch && win.hub.launch.hue ? win.hub.launch.hue
                         : Colors.accent;
                }
                return Colors.accent;
            }

            Rectangle {
                anchors.fill: parent
                visible: !IslandConfig.s("goo") || goo.count <= 0
                radius: height / 2
                antialiasing: true
                color: Colors.alpha(win.bodyColor, IslandConfig.s("fill") / 100)
                border.width: IslandConfig.s("borderAlpha") > 0 ? 1 : 0
                border.color: Colors.alpha(win.tint,
                                           IslandConfig.s("borderAlpha") / 100)
            }

            IslandSlot {
                anchors.centerIn: parent
                size: Math.max(14, stage.dotSize - 4)
                kind: win.hub.leftKind
                tint: task.hue
                live: task.visible
                taskGlyph: win.hub.taskGlyph
                result: win.hub.leftKind === "launch"
                    ? (win.hub.launchPhase === "ok" || win.hub.launchPhase === "bad"
                       ? win.hub.launchPhase : "")
                    : win.hub.leftKind === "download"
                    ? (win.hub.downloadPhase === "ok" ? "ok" : "")
                    : win.hub.taskResult
                icon: win.hub.launch ? win.hub.launch.icon : ""
            }

            TapHandler {
                enabled: win.hub.leftKind === "task" && win.hub.taskWin !== ""
                onTapped: win.hub.focusWindow(win.hub.taskWin)
            }
            HoverHandler {
                enabled: win.hub.leftKind === "task" && win.hub.taskWin !== ""
                cursorShape: Qt.PointingHandCursor
            }
        }

        Item {
            id: privacy

            readonly property bool cam: Privacy.camera
            readonly property bool on:
                IslandConfig.s("privacy") && (Privacy.mic || Privacy.camera)

            width: 7
            height: 7
            x: stage.width + 7
            anchors.verticalCenter: surface.verticalCenter
            scale: privacy.on ? 1 : 0
            visible: scale > 0.01
            Behavior on scale { SpringAnimation { spring: 4; damping: 0.3; mass: 0.7; epsilon: 0.005 } }

            readonly property color hue: privacy.cam ? Qt.rgba(0.19, 0.82, 0.35, 1)
                                                     : Qt.rgba(1.0, 0.62, 0.04, 1)

            RectangularShadow {
                anchors.fill: parent
                radius: width / 2
                blur: 8
                color: Colors.alpha(privacy.hue, 0.8)
            }

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                antialiasing: true
                color: privacy.hue
                Behavior on color { ColorAnimation { duration: Motion.base } }
            }
        }
    }
}
