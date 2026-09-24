import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
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
            root.flashKind = "";
            root.stacked = 0;
            root.demo = ({});
        }
    }

    property var demo: ({})
    property bool pinned: false

    IpcHandler {
        target: "island"

        function play(kind: string): void { root.playDemo(kind); }
        function pin(on: bool): void { root.pinned = on; }
    }

    function playDemo(kind) {
        switch (kind) {
        case "bt":
            root.demo = { bt: { name: "Sony Pulse Elite", battery: 0.82, on: true } };
            root.btOn = true;
            root.flash("bt", "󰋋", "Sony Pulse Elite", -1);
            break;
        case "btoff":
            root.demo = { bt: { name: "Sony Pulse Elite", battery: -1, on: false } };
            root.btOn = false;
            root.flash("bt", "󰂲", I18n.t("isle.bt.gone"), -1);
            break;
        case "power":
            root.demo = { power: { pct: 64, charging: true } };
            root.flash("power", "󰂄", "64%", 0.64);
            break;
        case "low":
            root.demo = { power: { pct: 9, charging: false } };
            root.flash("power", "󰂃", "9%", 0.09);
            break;
        case "peri":
            root.demo = { peri: { pct: 12, model: "MX Master 3S" } };
            root.flash("peri", "󰍽", "MX Master 3S  12%", 0.12);
            break;
        case "net":
            root.flash("net", "󰤨", Network.ssid !== "" ? Network.ssid : "Home", -1);
            break;
        case "vpn":
            root.flash("vpn", "󰦝", "wg0", -1);
            break;
        case "notif":
            root.notifSummary = "Остров";
            root.notifBody = "Так выглядит уведомление";
            root.notifApp = "Telegram";
            root.notifTint = NotifHistory.appColor("Telegram");
            root.flash("notif", "󰂚", root.notifSummary, -1);
            break;
        case "osd":
            Feedback.pulse++;
            break;
        default:
            root.flash(kind, "󰋽", kind, -1);
        }
    }

    function flash(kind, glyph, text, fraction) {
        if (!IslandConfig.s("enabled") || !IslandConfig.on(kind))
            return;
        if (root.flashKind !== "" && root.flashKind !== kind)
            root.stacked = Math.min(9, root.stacked + 1);
        root.flashKind = kind;
        root.flashGlyph = glyph;
        root.flashText = text;
        root.flashFraction = fraction === undefined ? -1 : fraction;
        flashLife.restart();
    }

    Connections {
        target: Feedback
        function onPulseChanged() {
            root.flash("osd", Feedback.icon !== "" ? Feedback.icon : "󰕾",
                       Feedback.label !== "" ? Feedback.label
                                             : Feedback.percent(Feedback.value),
                       Feedback.showBar && !Feedback.flat
                           ? Feedback.value : -1);
        }
    }

    property string lastLayout: ""
    Connections {
        target: Keyboard
        function onCodeChanged() {
            const was = root.lastLayout;
            root.lastLayout = Keyboard.code;
            if (was === "")
                return;
            root.flash("keys", "󰌌", Keyboard.code.toUpperCase(), -1);
        }
    }

    property int lastDesk: -1
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            const w = Hyprland.focusedWorkspace;
            if (!w)
                return;
            const was = root.lastDesk;
            root.lastDesk = w.id;
            if (was < 0)
                return;
            root.flash("desk", "󰧨",
                       w.name && w.name !== "" ? w.name : String(w.id), -1);
        }
    }

    property string lastSink: ""

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            const s = Pipewire.defaultAudioSink;
            const name = s ? s.name : "";
            const was = root.lastSink;
            root.lastSink = name;
            if (was === "" || name === "" || name === was)
                return;
            const label = s.description || s.nickname || s.name;
            const n = (s.name + " " + label).toLowerCase();
            const glyph = /blue|headphone|headset|наушн/.test(n) ? "󰋋"
                        : /hdmi|displayport/.test(n) ? "󰡁" : "󰓃";
            root.flash("route", glyph, label, -1);
        }
    }

    Component.onCompleted: {
        if (root.printWatch)
            Printing.watch();
        const s = Pipewire.defaultAudioSink;
        root.lastSink = s ? s.name : "";
    }

    Binding {
        target: Privacy
        property: "watching"
        value: IslandConfig.s("enabled") && IslandConfig.s("privacy")
    }

    Connections {
        target: Dnd
        function onActiveChanged() {
            root.flash("focus", Dnd.active ? "󰂛" : "󰂚",
                       I18n.t(Dnd.active ? "isle.focus.on" : "isle.focus.off"), -1);
        }
    }

    property string notifSummary: ""
    property string notifBody: ""
    property string notifApp: ""
    property color notifTint: Colors.accent

    Connections {
        target: NotifHistory
        function onAdded(entry) {
            root.notifSummary = entry && entry.summary ? entry.summary : "";
            root.notifBody = entry && entry.body ? entry.body : "";
            root.notifApp = entry && entry.app ? entry.app : "";
            root.notifTint = NotifHistory.appColor(root.notifApp);
            root.flash("notif", "󰂚", root.notifSummary, -1);
        }
    }

    property bool btOn: false
    property int lastBt: -1

    Connections {
        target: Bt
        function onConnectedCountChanged() {
            const was = root.lastBt;
            root.lastBt = Bt.connectedCount;
            if (was < 0)
                return;
            if (Bt.connectedCount > was) {
                const d = Bt.primary;
                root.btOn = true;
                root.flash("bt", Bt.icon(d), Bt.label(d), -1);
            } else if (Bt.connectedCount < was) {
                root.btOn = false;
                root.flash("bt", "󰂲", I18n.t("isle.bt.gone"), -1);
            }
        }
    }

    Connections {
        target: Peripherals
        function onLowChanged() {
            if (!Peripherals.low)
                return;
            root.flash("peri", Peripherals.glyph,
                       (Peripherals.model !== "" ? Peripherals.model + "  "
                                                 : "") + Peripherals.percent + "%",
                       Peripherals.percent / 100);
        }
        function onCriticalChanged() {
            if (!Peripherals.critical)
                return;
            root.flash("peri", Peripherals.glyph,
                       (Peripherals.model !== "" ? Peripherals.model + "  "
                                                 : "") + Peripherals.percent + "%",
                       Peripherals.percent / 100);
        }
    }

    readonly property bool charging: Power.charging
    readonly property int batteryPct: Power.percent

    property int lastPower: -1
    property bool warnedLow: false

    Connections {
        target: Power

        function onChargingChanged() {
            const was = root.lastPower;
            root.lastPower = Power.charging ? 1 : 0;
            if (was < 0 || !Power.present)
                return;
            if (Power.charging)
                root.warnedLow = false;
            root.flash("power", Power.glyph, Power.percent + "%",
                       Power.fraction);
        }

        function onLowChanged() {
            if (!Power.low) {
                root.warnedLow = false;
                return;
            }
            if (root.warnedLow)
                return;
            root.warnedLow = true;
            root.flash("power", "󰂃", Power.percent + "%", Power.fraction);
        }
    }

    property string lastSsid: ""
    property bool primedNet: false

    Connections {
        target: Network
        function onSsidChanged() { root.netMoved(); }
        function onConnectedChanged() { root.netMoved(); }
    }

    function netMoved() {
        const now = Network.connected ? Network.ssid : "";
        if (now === root.lastSsid)
            return;
        const was = root.lastSsid;
        root.lastSsid = now;
        if (!root.primedNet) {
            root.primedNet = true;
            return;
        }
        if (now !== "")
            root.flash("net", Network.glyph, now, -1);
        else if (was !== "")
            root.flash("net", "󰤮", I18n.t("isle.net.gone"), -1);
    }

    property int lastVpn: -1

    Connections {
        target: Vpn
        function onUpChanged() {
            const was = root.lastVpn;
            root.lastVpn = Vpn.up ? 1 : 0;
            if (was < 0)
                return;
            root.flash("vpn", Vpn.up ? "󰦝" : "󰦞",
                       Vpn.up ? (Vpn.iface !== "" ? Vpn.iface
                                                  : I18n.t("isle.vpn.on"))
                              : I18n.t("isle.vpn.off"), -1);
        }
    }

    property int lastJobs: -1

    Connections {
        target: Printing
        function onJobsChanged() {
            const n = Printing.jobs.length;
            const was = root.lastJobs;
            root.lastJobs = n;
            if (was < 0)
                return;
            if (n > was)
                root.flash("print", "󰐪", I18n.t("isle.print.sent"), -1);
            else if (n === 0 && was > 0)
                root.flash("print", "󰸞", I18n.t("isle.print.done"), -1);
        }
    }

    readonly property bool printWatch:
        IslandConfig.s("enabled") && IslandConfig.on("print")

    onPrintWatchChanged: {
        if (root.printWatch)
            Printing.watch();
        else
            Printing.unwatch();
    }

    Component.onDestruction: if (root.printWatch) Printing.unwatch()

    readonly property string kind: {
        if (!IslandConfig.s("enabled"))
            return "";
        if (IslandConfig.on("alarm") && Timers.anyRinging)
            return "alarm";
        if (root.flashKind !== "")
            return root.flashKind;
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
        if (IslandConfig.on("print") && Printing.jobs.length > 0)
            return "print";
        if (IslandConfig.on("timer") && Timers.anyRunning)
            return "timer";
        return "";
    }

    readonly property bool miniMedia:
        IslandConfig.s("enabled") && IslandConfig.on("media")
        && Media.has && Media.playing

    Variants {
        model: Quickshell.screens

        PanelWindow {
            WlrLayershell.namespace: "qs-island"
            id: win
            required property var modelData
            screen: modelData

            readonly property bool mine:
                IslandConfig.s("where") === "all"
                || (Focus.screen && Focus.screen.name === modelData.name)

            readonly property bool blocked: {
                if (!IslandConfig.s("hideFull"))
                    return false;
                const list = ToplevelManager.toplevels
                    ? ToplevelManager.toplevels.values : [];
                for (const t of list) {
                    if (t && t.fullscreen)
                        return true;
                }
                return false;
            }

            readonly property bool wanted:
                root.kind !== "" || root.miniMedia || root.leftKind !== ""

            visible: IslandConfig.s("enabled")
                     && ((win.mine && !win.blocked && win.wanted)
                         || birth.value > 0.01)

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

            Timer {
                id: force
                interval: IslandConfig.s("autoWideMs")
                onTriggered: win.forced = false
            }

            readonly property bool bigEvent:
                root.kind === "notif" || root.kind === "alarm"
                || root.kind === "bt" || root.kind === "peri"
                || root.kind === "power"
                || root.kind === "net" || root.kind === "vpn"

            Connections {
                target: root
                function onKindChanged() {
                    if (root.kind === "")
                        return;
                    win.bump();
                    if (!IslandConfig.s("autoWide") || !win.bigEvent)
                        return;
                    win.forced = true;
                    force.restart();
                    if (IslandConfig.s("sfx"))
                        Sfx.tick();
                }
            }

            readonly property string wideKind: {
                if (win.bigEvent)
                    return root.kind;
                if (root.kind === "timer" || root.kind === "record"
                    || root.kind === "osd"
                    || root.kind === "net" || root.kind === "vpn"
                    || root.kind === "print")
                    return root.kind;
                if (Media.has)
                    return "media";
                return "";
            }

            readonly property bool wide:
                win.wideKind !== ""
                && (root.pinned || win.forced
                    || (win.hovering && IslandConfig.s("hoverWide")
                        && !win.hushed))

            property bool hushed: false
            onHoveringChanged: if (!win.hovering) win.hushed = false

            readonly property color mediaTint:
                IslandConfig.s("artTint") && artTint.found ? artTint.color
                                                           : Colors.accent

            readonly property color bodyColor:
                IslandConfig.s("black") ? Qt.rgba(0, 0, 0, 1) : Colors.bg

            readonly property color tint: {
                if (!IslandConfig.s("tintEdge"))
                    return Colors.outline;
                if (win.wide && win.wideKind === "media")
                    return win.mediaTint;
                switch (root.kind) {
                case "alarm":  return Colors.bad;
                case "record": return Colors.bad;
                case "notif":  return root.notifTint;
                case "osd":    return Feedback.channel === "source"
                                      ? Colors.accentAlt : Colors.accent;
                case "timer":  return Colors.accentAlt;
                case "desk":   return Colors.accentAlt;
                case "peri":   return Peripherals.critical ? Colors.bad
                                                           : Colors.warn;
                case "power":  return root.charging ? Colors.good
                                    : (root.batteryPct <= 15 ? Colors.bad
                                                             : Colors.accent);
                case "bt":     return root.btOn ? Colors.good : Colors.fgDim;
                case "vpn":    return Vpn.up ? Colors.good : Colors.fgDim;
                case "net":    return Network.connected ? Colors.accentAlt
                                                        : Colors.fgDim;
                case "print":  return Colors.accentAlt;
                case "focus":  return Dnd.active ? Qt.rgba(0.37, 0.36, 0.90, 1)
                                                 : Colors.fgDim;
                case "route":  return Colors.accent;
                case "media":  return win.mediaTint;
                default:       return root.miniMedia ? win.mediaTint
                                                     : Colors.accent;
                }
            }

            MorphSpring {
                id: morph
                target: win.wide ? 1 : 0
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
                target: win.mine && !win.blocked && win.wanted ? 1 : 0
            }

            MorphSpring {
                id: wideTall
                springBack: true
                response: Motion.isleWidthResponse
                damping: 0.78
                epsilon: 0.25
                target: win.wideKind === "media" ? IslandConfig.s("mediaHeight")
                                                 : IslandConfig.s("wideHeight")
                Component.onCompleted: wideTall.land()
            }

            property real beat: 0

            Connections {
                target: Cava
                enabled: IslandConfig.s("glow") && root.miniMedia && win.visible
                function onSmoothChanged() {
                    const l = Cava.smooth;
                    win.beat = Math.min(1, ((l[0] || 0) + (l[1] || 0)
                                            + (l[2] || 0)) / 2.4);
                }
            }

            Connections {
                target: root
                function onMiniMediaChanged() {
                    if (!root.miniMedia)
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
                switch (root.kind) {
                case "peri":
                case "power":
                    return root.flashFraction;
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
                root.kind === "alarm"
                || (root.kind === "record" && !win.wide)

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

            Item {
                id: stage

                readonly property int pillH: IslandConfig.s("pillHeight")
                readonly property int dotSize: stage.pillH
                readonly property int gapPx: IslandConfig.s("minimalGap")

                readonly property bool minimalOn:
                    IslandConfig.s("minimal") && root.miniMedia
                    && root.kind !== "" && root.kind !== "clock"
                    && root.kind !== "media"

                readonly property bool leftOn:
                    IslandConfig.s("leftSlot") && root.leftKind !== ""

                readonly property real detach: dotLife.value * (1 - morph.value)
                readonly property real tail:
                    stage.detach * (stage.gapPx + stage.dotSize)

                readonly property real headDetach:
                    slotLife.value * (1 - morph.value)
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
                anchors.topMargin: win.atTop ? stage.gap : 0
                anchors.bottomMargin: win.atTop ? 0 : stage.gap

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
                       * (1 - (1 - Motion.isleTapScale) * press.value)

                readonly property real rush:
                    morph.velocity * 0.16
                    + pillWidth.velocity / 420
                    + birth.velocity * 0.12

                readonly property real jelly: IslandConfig.s("jelly")
                    ? Math.max(-Motion.isleJellyCap,
                               Math.min(Motion.isleJellyCap,
                                        stage.rush * Motion.isleJelly))
                    : 0

                transform: Scale {
                    origin.x: stage.width / 2
                    origin.y: stage.height / 2
                    xScale: 1 + stage.jelly
                    yScale: 1 - stage.jelly * Motion.isleJellyCross
                }

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

                RectangularShadow {
                    id: aura

                    readonly property real power:
                        IslandConfig.s("glowAlpha") / 100
                        * (0.55 + 0.45 * morph.value + 0.55 * win.beat
                           + 0.6 * peek.value + 0.5 * win.throb)

                    x: surface.x
                    y: surface.y
                    width: surface.width
                    height: surface.height
                    radius: surface.corner
                    blur: 14 + 16 * morph.value + 8 * win.beat
                    spread: -1 + 3 * win.beat
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
                        target: root
                        function onFlashKindChanged() {
                            if (root.flashKind !== "" && IslandConfig.s("ripple"))
                                ringRun.restart();
                        }
                    }
                }

                Blobs {
                    id: goo
                    host: stage
                    visible: IslandConfig.s("goo") && count > 0
                    fuse: Math.max(3, Math.min(8, stage.gapPx / 2 - 1))
                    corner: surface.corner
                    stroke: IslandConfig.s("borderAlpha") > 0 ? 1 : 0
                    shadow: IslandConfig.s("shadow")
                    shadowColor: IslandConfig.s("tintShadow")
                        ? Colors.alpha(Qt.darker(win.tint, 1.8), 0.40)
                        : Qt.rgba(0, 0, 0, 0.32)
                    fillColor: win.bodyColor
                    fillAlpha: IslandConfig.s("fill") / 100
                    hoverColor: win.bodyColor
                    hoverAlpha: IslandConfig.s("fill") / 100
                    strokeColor: win.tint
                    strokeAlpha: IslandConfig.s("borderAlpha") / 100
                }

                Item {
                    id: surface

                    readonly property real bareW:
                        Motion.mix(pillWidth.value, IslandConfig.s("wideWidth"),
                                   morph.value)
                    readonly property real bareH:
                        Motion.mix(stage.pillH, wideTall.value, morph.value)

                    width: Math.round(Motion.mix(stage.pillH, surface.bareW,
                                                 birth.value))
                    height: Math.round(surface.bareH)

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
                        border.width: IslandConfig.s("borderAlpha") > 0 ? 1 : 0
                        border.color: Colors.alpha(win.tint,
                                                   IslandConfig.s("borderAlpha") / 100)

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
                    }

                    HoverHandler {
                        onHoveredChanged: win.pointerIn = hovered
                    }

                    WheelHandler {
                        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                        onWheel: (ev) => {
                            const dy = ev.angleDelta.y;
                            if (dy > 0 && win.wide) {
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
                        enabled: IslandConfig.s("tapWide") && win.wideKind !== ""
                        onPressedChanged: win.pressed = pressed
                        onTapped: {
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

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: surface.corner
                        color: "transparent"

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

                        IslandPill {
                            id: pill
                            anchors.centerIn: parent
                            height: stage.pillH
                            maxWidth: surface.width
                            notifApp: root.notifApp

                            tint: win.tint
                            mediaTint: win.mediaTint
                            beat: win.beat
                            flashKind: root.flashKind
                            flashGlyph: root.flashGlyph
                            flashText: root.flashText
                            flashFraction: root.flashFraction
                            kind: root.kind
                            stacked: root.stacked
                            miniMedia: root.miniMedia && !stage.minimalOn

                            opacity: win.wide ? 0 : 1
                            scale: win.wide ? 0.92 : 1
                            visible: opacity > 0.01

                            transform: Translate {
                                y: win.wide ? -7 : 0
                                Behavior on y {
                                    NumberAnimation {
                                        duration: win.wide ? Motion.isleHideMs
                                                           : Motion.isleRevealMs
                                        easing.type: Easing.Bezier
                                        easing.bezierCurve: Motion.isleContent
                                    }
                                }
                            }

                            Behavior on opacity {
                                SequentialAnimation {
                                    PauseAnimation {
                                        duration: win.wide ? 0 : Motion.isleRevealDelay
                                    }
                                    NumberAnimation {
                                        duration: win.wide ? Motion.isleHideMs
                                                           : Motion.isleRevealMs
                                        easing.type: Easing.Bezier
                                        easing.bezierCurve: Motion.isleContent
                                    }
                                }
                            }
                            Behavior on scale {
                                SequentialAnimation {
                                    PauseAnimation {
                                        duration: win.wide ? 0 : Motion.isleRevealDelay
                                    }
                                    NumberAnimation {
                                        duration: win.wide ? Motion.isleHideMs
                                                           : Motion.isleRevealMs
                                        easing.type: Easing.Bezier
                                        easing.bezierCurve: Motion.isleContent
                                    }
                                }
                            }
                        }

                        IslandBody {
                            anchors.fill: parent
                            anchors.margins: 12
                            kind: win.wideKind
                            tint: win.tint
                            wide: win.wide
                            notifSummary: root.notifSummary
                            notifBody: root.notifBody
                            notifApp: root.notifApp
                            demo: root.demo
                        }

                    }
                }

                Item {
                    id: dot

                    property bool isBlob: true

                    width: stage.dotSize
                    height: stage.dotSize
                    x: stage.head + surface.width - stage.dotSize
                       + stage.detach * (stage.gapPx + stage.dotSize)
                    anchors.verticalCenter: surface.verticalCenter

                    readonly property real swallow: 1 - morph.value

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

                    width: stage.dotSize
                    height: stage.dotSize
                    x: stage.head - stage.headDetach * (stage.gapPx + stage.dotSize)
                    anchors.verticalCenter: surface.verticalCenter

                    readonly property real swallow: 1 - morph.value

                    visible: stage.headDetach > 0.015
                    scale: (0.4 + 0.6 * slotLife.value) * task.swallow
                    opacity: Math.min(1, slotLife.value * 1.6) * task.swallow

                    readonly property color hue:
                        root.leftKind === "print" ? Colors.accentAlt
                                                  : Colors.accent

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
                        kind: root.leftKind
                        tint: task.hue
                        live: task.visible
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
    }
}
