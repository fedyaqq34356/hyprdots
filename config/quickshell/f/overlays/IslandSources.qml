import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: src

    required property var hub

    Connections {
        target: Feedback
        function onPulseChanged() {
            src.hub.flash("osd", Feedback.icon !== "" ? Feedback.icon : "󰕾",
                          Feedback.label !== "" ? Feedback.label
                                                : Feedback.percent(Feedback.value),
                          Feedback.showBar && !Feedback.flat
                              ? Feedback.value : -1);
        }
    }

    property string lastLayout: ""
    Connections {
        target: Keyboard
        function onCapsChanged() {
            src.hub.flash("caps", Keyboard.caps ? "󰪛" : "󰬶",
                          Keyboard.caps ? "Caps Lock" : "Caps off", -1, true);
        }
    }

    Connections {
        target: Keyboard
        function onCodeChanged() {
            const was = src.lastLayout;
            src.lastLayout = Keyboard.code;
            if (was === "")
                return;
            src.hub.flash("keys", "󰌌", Keyboard.code.toUpperCase(), -1);
        }
    }

    property int lastDesk: -1
    Connections {
        target: Hyprland
        function onFocusedWorkspaceChanged() {
            const w = Hyprland.focusedWorkspace;
            if (!w)
                return;
            const was = src.lastDesk;
            src.lastDesk = w.id;
            if (was < 0 || was === w.id)
                return;
            if (!IslandConfig.s("enabled") || !IslandConfig.on("desk"))
                return;
            const dir = w.id > was ? 1 : -1;
            src.hub.deskDir = dir;
            src.hub.deskMoved(dir);
            src.hub.flash("desk", "󰧨",
                          w.name && w.name !== "" ? w.name : String(w.id), -1);
        }
    }

    property string lastSink: ""

    Connections {
        target: Pipewire
        function onDefaultAudioSinkChanged() {
            const s = Pipewire.defaultAudioSink;
            const name = s ? s.name : "";
            const was = src.lastSink;
            src.lastSink = name;
            if (was === "" || name === "" || name === was)
                return;
            const label = s.description || s.nickname || s.name;
            const n = (s.name + " " + label).toLowerCase();
            const glyph = /blue|headphone|headset|наушн/.test(n) ? "󰋋"
                        : /hdmi|displayport/.test(n) ? "󰡁" : "󰓃";
            src.hub.flash("route", glyph, label, -1);
        }
    }

    Component.onCompleted: {
        src.lastPower = Power.plugged ? 1 : 0;
        if (src.printWatch)
            Printing.watch();
        const s = Pipewire.defaultAudioSink;
        src.lastSink = s ? s.name : "";
    }

    Binding {
        target: Privacy
        property: "watching"
        value: IslandConfig.s("enabled") && IslandConfig.s("privacy")
    }

    Connections {
        target: Dnd
        function onActiveChanged() {
            src.hub.flash("focus", Dnd.active ? "󰂛" : "󰂚",
                          I18n.t(Dnd.active ? "isle.focus.on" : "isle.focus.off"), -1);
        }
    }

    function appIcon(entry, live) {
        if (entry && entry.icon)
            return entry.icon;
        const de = live && live.desktopEntry
            ? DesktopEntries.byId(live.desktopEntry) : null;
        const app = entry ? entry.app : "";
        const guess = de || DesktopEntries.heuristicLookup(app) || src.entryByName(app);
        return guess && guess.icon ? guess.icon : "";
    }

    function entryByName(app) {
        const key = (app || "").toLowerCase().trim();
        const first = key.split(/\s+/)[0] || "";
        if (first.length < 3)
            return null;
        const list = DesktopEntries.applications.values;
        let loose = null;
        for (let i = 0; i < list.length; i++) {
            const e = list[i];
            const nm = (e.name || "").toLowerCase();
            if (nm === key)
                return e;
            if (!loose && (nm === first || (e.id || "").toLowerCase().includes(first)))
                loose = e;
        }
        return loose;
    }

    Connections {
        target: NotifHistory
        function onAdded(entry) {
            const live = NotifHistory.live;
            const e = {
                app: entry && entry.app ? entry.app : "",
                summary: entry && entry.summary ? entry.summary : "",
                body: entry && entry.body ? entry.body : "",
                image: entry && entry.image ? entry.image : "",
                icon: src.appIcon(entry, live),
                live: live
            };
            if (src.isCall(e, live)) {
                src.hub.startCall({ name: e.summary, app: e.app, image: e.image,
                                    icon: e.icon, live: live });
                return;
            }
            src.hub.arrive(e);
        }
    }

    function isCall(e, live) {
        const hints = live && live.hints ? live.hints : null;
        const cat = hints && hints.category ? String(hints.category) : "";
        if (/^(call|x-.*call)/i.test(cat) && !/ended|unanswered/i.test(cat))
            return true;
        const t = e.summary + " " + e.body;
        return /(incoming|входящ\S*)\s+(\S+\s+)?(call|звонок|вызов)|calling you|звонит вам/i.test(t);
    }

    property int lastBt: -1

    Connections {
        target: Bt
        function onConnectedCountChanged() {
            const was = src.lastBt;
            src.lastBt = Bt.connectedCount;
            if (was < 0)
                return;
            if (Bt.connectedCount > was) {
                const d = Bt.primary;
                src.hub.btOn = true;
                src.hub.flash("bt", Bt.icon(d), Bt.label(d), -1);
            } else if (Bt.connectedCount < was) {
                src.hub.btOn = false;
                src.hub.flash("bt", "󰂲", I18n.t("isle.bt.gone"), -1);
            }
        }
    }

    function periFlash() {
        src.hub.flash("peri", Peripherals.glyph,
                      (Peripherals.model !== "" ? Peripherals.model + "  " : "")
                      + Peripherals.percent + "%",
                      Peripherals.percent / 100);
    }

    Connections {
        target: Peripherals
        function onLowChanged() { if (Peripherals.low) src.periFlash(); }
        function onCriticalChanged() { if (Peripherals.critical) src.periFlash(); }
    }

    property int lastPower: -1
    property bool warnedLow: false

    Connections {
        target: Power

        function onPluggedChanged() {
            const was = src.lastPower;
            src.lastPower = Power.plugged ? 1 : 0;
            if (was < 0 || was === src.lastPower || !Power.present)
                return;
            if (Power.plugged) {
                src.warnedLow = false;
                src.hub.poured(Power.fraction);
            }
            src.hub.flash("power", Power.plugged ? "󰂄" : Power.glyph,
                          Power.percent + "%", Power.fraction);
        }

        function onLowChanged() {
            if (!Power.low) {
                src.warnedLow = false;
                return;
            }
            if (src.warnedLow)
                return;
            src.warnedLow = true;
            src.hub.flash("power", "󰂃", Power.percent + "%", Power.fraction);
        }
    }

    WeatherHold {
        active: IslandConfig.s("enabled") && IslandConfig.on("weather")
    }

    property string toldSky: ""

    Connections {
        target: Weather
        function onSoonKindChanged() { src.skyMoved(); }
        function onSoonAtChanged() { src.skyMoved(); }
    }

    function skyMoved() {
        if (Weather.soonKind === "") {
            src.toldSky = "";
            return;
        }
        const key = Weather.soonKind + "@" + Math.round(Weather.soonAt / 3600000);
        if (key === src.toldSky)
            return;
        src.toldSky = key;
        src.hub.sky(Weather.soonKind, Weather.soonAt, Weather.soonChance);
    }

    property string lastSsid: ""
    property bool primedNet: false

    Connections {
        target: Network
        function onSsidChanged() { src.netMoved(); }
        function onConnectedChanged() { src.netMoved(); }
    }

    function netMoved() {
        const now = Network.connected ? Network.ssid : "";
        if (now === src.lastSsid)
            return;
        const was = src.lastSsid;
        src.lastSsid = now;
        if (!src.primedNet) {
            src.primedNet = true;
            return;
        }
        if (now !== "")
            src.hub.flash("net", Network.glyph, now, -1);
        else if (was !== "")
            src.hub.flash("net", "󰤮", I18n.t("isle.net.gone"), -1);
    }

    property int lastVpn: -1

    Connections {
        target: Vpn
        function onUpChanged() {
            const was = src.lastVpn;
            src.lastVpn = Vpn.up ? 1 : 0;
            if (was < 0)
                return;
            src.hub.flash("vpn", Vpn.up ? "󰦝" : "󰦞",
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
            const was = src.lastJobs;
            src.lastJobs = n;
            if (was < 0)
                return;
            if (n > was)
                src.hub.flash("print", "󰐪", I18n.t("isle.print.sent"), -1);
            else if (n === 0 && was > 0) {
                src.hub.flash("print", "󰸞", I18n.t("isle.print.done"), -1);
                src.hub.sparked();
            }
        }
    }

    readonly property bool printWatch:
        IslandConfig.s("enabled") && IslandConfig.on("print")

    onPrintWatchChanged: {
        if (src.printWatch)
            Printing.watch();
        else
            Printing.unwatch();
    }

    Component.onDestruction: if (src.printWatch) Printing.unwatch()

    property string clipSig: ""
    property real clipAt: 0
    property bool clipPrimed: false

    Process {
        id: clipWatch
        running: IslandConfig.s("enabled") && IslandConfig.on("clip")
        command: ["wl-paste", "--watch",
                  Quickshell.env("HOME") + "/.config/hypr/scripts/island-clip.sh"]
        onRunningChanged: {
            src.clipPrimed = false;
            if (clipWatch.running)
                clipPrime.restart();
        }
        stdout: SplitParser {
            onRead: (line) => src.clipLine(line)
        }
    }

    Timer { id: clipPrime; interval: 1500; onTriggered: src.clipPrimed = true }

    function clipLine(line) {
        const f = line.split("\t");
        const sig = f[1] || "";
        const now = Date.now();
        if (!src.clipPrimed) {
            src.clipSig = sig;
            src.clipAt = now;
            return;
        }
        if (sig === src.clipSig && now - src.clipAt < 5000)
            return;
        src.clipSig = sig;
        src.clipAt = now;
        switch (f[0]) {
        case "txt":
            src.hub.clipImage = "";
            src.hub.flash("clip", "󰅌",
                          f.slice(2).join(" ").replace(/\uFFFD+$/, "").trim(), -1);
            break;
        case "img":
            if (now - src.hub.shotAt < 6000)
                return;
            src.hub.clipImage = "file://" + (f[2] || "");
            src.hub.flash("clip", "󰋩", I18n.t("isle.clip.image"), -1);
            break;
        case "files": {
            const n = parseInt(f[2]) || 1;
            src.hub.clipImage = "";
            src.hub.flash("clip", "󰈔", (f[3] || I18n.t("isle.clip.files"))
                                       + (n > 1 ? "  +" + (n - 1) : ""), -1);
            break;
        }
        case "secret":
            src.hub.clipImage = "";
            src.hub.flash("clip", "󰌾", I18n.t("isle.clip.secret"), -1);
            break;
        }
    }
}
