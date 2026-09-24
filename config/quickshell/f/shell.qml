import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "root:/bar"
import "root:/design"
import "root:/desk"
import "root:/overlays"
import "root:/panels"
import "root:/services"

ShellRoot {
    id: root

    Connections {
        target: Quickshell
        function onReloadCompleted() { Quickshell.inhibitReloadPopup(); }
        function onReloadFailed(error) { Quickshell.inhibitReloadPopup(); }
    }

    PwObjectTracker {
        objects: {
            const list = [];
            if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink);
            if (Pipewire.defaultAudioSource) list.push(Pipewire.defaultAudioSource);
            return list;
        }
    }

    Process {
        id: micTarget
        command: ["sh", "-c", ""]
    }

    function setMicTarget(vol) {
        const pct = Math.round(Math.max(0, Math.min(1, vol)) * 100);
        micTarget.command = [
            Quickshell.env("HOME") + "/.config/hypr/scripts/mic-target.sh",
            String(pct)
        ];
        micTarget.running = true;
    }

    Bar {
        panels: ({
            media: mediaL,
            calendar: calendarL,
            net: netL,
            notifCenter: notifCenterL,
            timer: timerL,
            audio: audioPanelL
        })
    }
    Osd {}
    Notifications {}
    FullscreenFlash {}
    RecordingBadge {}

    LazyLoader { id: launcherL; loading: true; Launcher {} }
    LazyLoader { id: clipboardL; loading: true; Clipboard {} }
    LazyLoader { id: wallpapersL; WallpaperPicker {} }
    LazyLoader { id: audioPanelL; AudioPanel {} }
    LazyLoader { id: powerMenuL; PowerMenu {} }
    LazyLoader { id: netL; NetPanel {} }
    LazyLoader { id: overviewL; Overview {} }
    LazyLoader { id: notifCenterL; loading: true; NotifCenter {} }
    LazyLoader { id: filesL; Files {} }
    LazyLoader { id: printL; PrintPanel {} }
    LazyLoader { id: mediaL; MediaPanel {} }
    LazyLoader { id: calendarL; loading: true; Calendar {} }
    LazyLoader { id: sysRingsL; SysRings {} }
    LazyLoader { id: timerL; TimerPanel {} }
    LazyLoader { id: settingsL; Settings {} }
    LazyLoader { id: guideL; Guide {} }
    LazyLoader { id: eqL; Eq {} }
    LazyLoader { id: barBuilderL; BarBuilder {} }
    LazyLoader { id: islandL; IslandPanel {} }

    readonly property var launcher: launcherL.item
    readonly property var clipboard: clipboardL.item
    readonly property var wallpapers: wallpapersL.item
    readonly property var audioPanel: audioPanelL.item
    readonly property var powerMenu: powerMenuL.item
    readonly property var net: netL.item
    readonly property var overview: overviewL.item
    readonly property var notifCenter: notifCenterL.item
    readonly property var files: filesL.item
    readonly property var printPanel: printL.item
    readonly property var media: mediaL.item
    readonly property var calendar: calendarL.item
    readonly property var sysRings: sysRingsL.item
    readonly property var timer: timerL.item
    readonly property var settings: settingsL.item
    readonly property var guide: guideL.item
    readonly property var eq: eqL.item
    readonly property var barBuilder: barBuilderL.item
    readonly property var islandPanel: islandL.item

    Lock {
        id: lock
        onUnlocked: curtain.up()
    }
    Curtain { id: curtain }

    IpcHandler {
        target: "diag"
        function phase(): string { return "holders=" + Phase.holders; }
        function cava(): string {
            return "watchers=" + Cava.watchers + " active=" + Cava.active;
        }
        function weather(): string {
            return "watchers=" + Weather.watchers
                 + " wanted=" + Weather.wanted
                 + " everyMin=" + (Weather.every / 60000)
                 + " age=" + (Weather.fetchedAt > 0
                     ? Math.round((Date.now() - Weather.fetchedAt) / 1000) + "s"
                     : "never");
        }
    }

    IpcHandler {
        target: "printing"

        function file(path: string): string {
            if (!path)
                return "нужен путь к файлу";
            panelDo(printL, p => p.open(path));
            return "ок";
        }

        function open(): string {
            panelDo(printL, p => p.toggle());
            return "ок";
        }
    }

    Process {
        running: true
        command: [Quickshell.env("HOME") + "/.local/bin/qs-solo"]
    }

    function panelDo(loader, fn) {
        if (loader.item) {
            fn(loader.item);
            return;
        }
        loader.active = true;
        Qt.callLater(() => {
            if (loader.item)
                fn(loader.item);
        });
    }
    Process { id: roundingProc }

    function pushWindowRounding() {
        roundingProc.running = false;
        roundingProc.command = [
            "sh", "-c",
            "printf '$winRounding = %s\\n' \"$1\" "
                + "> \"$HOME/.config/hypr/config/shape.conf\" && "
                + "hyprctl keyword decoration:rounding \"$1\"",
            "sh", String(Shape.window)
        ];
        roundingProc.running = true;
    }

    Connections {
        target: Prefs
        function onCornerRadiusChanged() { root.pushWindowRounding(); }
    }

    Component.onCompleted: root.pushWindowRounding()

    FocusTrail {}
    Greeting {}
    Dim {}

    LazyLoader {
        active: IslandConfig.s("enabled")
        Island {}
    }

    LazyLoader {
        id: deskLoader
        active: Prefs.widgetsEnabled
        Desk {}
    }

    LazyLoader {
        id: dockLoader
        active: Prefs.dockEnabled
        Dock {}
    }

    LazyLoader {
        id: drawLoader
        active: Prefs.drawEnabled
        Draw {}
    }

    LazyLoader {
        id: quickLoader
        active: Prefs.quickActionsEnabled

        Quick {
            draw: drawLoader.item
            dock: dockLoader.item
            desk: deskLoader.item
            timerLoader: timerL
        }
    }

    LazyLoader {
        active: Prefs.polkitEnabled
        Polkit {}
    }

    Binding {
        target: Wellbeing
        property: "paused"
        value: lock.locked || Idle.screenOff
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        onPressed: panelDo(launcherL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "dnd"
        onPressed: {
            Dnd.toggle();
            Feedback.flash(Dnd.active ? "󰂛" : "󰂚", 0, false,
                      Dnd.active ? I18n.t("notif.dnd") : I18n.t("notif.dndOff"), true);
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "notifCenter"
        onPressed: panelDo(notifCenterL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "files"
        onPressed: panelDo(filesL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "print"
        onPressed: panelDo(printL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcherCalc"
        onPressed: panelDo(launcherL, p => p.toggleCalc())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "clipboard"
        onPressed: panelDo(clipboardL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "wallpapers"
        onPressed: panelDo(wallpapersL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volumeUp"
        onPressed: {
            const a = Pipewire.defaultAudioSink?.audio;
            if (!a) return;
            a.muted = false;
            if (a.volume >= 0.999) {
                Sfx.limit();
                return;
            }
            a.volume = Math.min(1, a.volume + 0.05);
            Sfx.tick();
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volumeDown"
        onPressed: {
            const a = Pipewire.defaultAudioSink?.audio;
            if (!a) return;
            if (a.volume <= 0.001) {
                Sfx.limit();
                return;
            }
            a.volume = Math.max(0, a.volume - 0.05);
            Sfx.tick();
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volumeMute"
        onPressed: {
            const a = Pipewire.defaultAudioSink?.audio;
            if (!a) return;
            a.muted = !a.muted;
            Sfx.flip(!a.muted);
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "overview"
        onPressed: panelDo(overviewL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "media"
        onPressed: panelDo(mediaL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "calendar"
        onPressed: panelDo(calendarL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "sysRings"
        onPressed: panelDo(sysRingsL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "mediaToggle"
        onPressed: Media.toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "mediaNext"
        onPressed: Media.next()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "mediaPrev"
        onPressed: Media.previous()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "wifi"
        onPressed: panelDo(netL, p => p.toggle("wifi"))
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "bluetooth"
        onPressed: panelDo(netL, p => p.toggle("bt"))
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "powerMenu"
        onPressed: panelDo(powerMenuL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "brightnessUp"
        onPressed: {
            if (Brightness.available) { Brightness.change(0.05); Sfx.tick(); }
            else Feedback.flash("󰃞", 0, false, I18n.t("bar.noBacklight"));
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "brightnessDown"
        onPressed: {
            if (Brightness.available) { Brightness.change(-0.05); Sfx.tick(); }
            else Feedback.flash("󰃞", 0, false, I18n.t("bar.noBacklight"));
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "audioPanel"
        onPressed: panelDo(audioPanelL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "micUp"
        onPressed: {
            const a = Pipewire.defaultAudioSource?.audio;
            if (a) {
                a.muted = false;
                a.volume = Math.min(1, a.volume + 0.05);
                setMicTarget(a.volume);
                Sfx.tick();
            }
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "micDown"
        onPressed: {
            const a = Pipewire.defaultAudioSource?.audio;
            if (a) {
                a.volume = Math.max(0, a.volume - 0.05);
                setMicTarget(a.volume);
                Sfx.tick();
            }
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "micMute"
        onPressed: {
            const a = Pipewire.defaultAudioSource?.audio;
            if (!a) return;
            a.muted = !a.muted;
            Sfx.flip(!a.muted);
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "settings"
        onPressed: panelDo(settingsL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "timer"
        onPressed: panelDo(timerL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "timerDismiss"
        onPressed: {
            if (Timers.anyRinging)
                Timers.dismissAll();
            else if (Timers.soonest)
                Timers.toggle(Timers.soonest.id);
            else
                panelDo(timerL, p => p.open("count"));
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "eq"
        onPressed: panelDo(eqL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "guide"
        onPressed: panelDo(guideL, p => p.open())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "deskEdit"
        onPressed: if (deskLoader.item) deskLoader.item.toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "barBuilder"
        onPressed: panelDo(barBuilderL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "island"
        onPressed: panelDo(islandL, p => p.toggle())
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "draw"
        onPressed: if (drawLoader.item) drawLoader.item.toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "dock"
        onPressed: if (dockLoader.item) dockLoader.item.toggle()
    }
}
