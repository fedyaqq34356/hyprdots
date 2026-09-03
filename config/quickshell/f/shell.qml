import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import "root:/bar"
import "root:/desk"
import "root:/overlays"
import "root:/panels"
import "root:/services"

ShellRoot {

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

    Bar {}
    Osd {}
    Notifications {}
    FullscreenFlash {}
    RecordingBadge {}

    LazyLoader { id: launcherL; loading: true; Launcher {} }
    LazyLoader { id: clipboardL; loading: true; Clipboard {} }
    LazyLoader { id: wallpapersL; WallpaperPicker {} }
    LazyLoader { id: audioPanelL; loading: true; AudioPanel {} }
    LazyLoader { id: powerMenuL; loading: true; PowerMenu {} }
    LazyLoader { id: netL; loading: true; NetPanel {} }
    LazyLoader { id: overviewL; loading: true; Overview {} }
    LazyLoader { id: notifCenterL; loading: true; NotifCenter {} }
    LazyLoader { id: filesL; Files {} }
    LazyLoader { id: mediaL; loading: true; MediaPanel {} }
    LazyLoader { id: calendarL; loading: true; Calendar {} }
    LazyLoader { id: sysRingsL; loading: true; SysRings {} }
    LazyLoader { id: timerL; loading: true; TimerPanel {} }
    LazyLoader { id: settingsL; Settings {} }
    LazyLoader { id: guideL; Guide {} }
    LazyLoader { id: eqL; Eq {} }

    readonly property var launcher: launcherL.item
    readonly property var clipboard: clipboardL.item
    readonly property var wallpapers: wallpapersL.item
    readonly property var audioPanel: audioPanelL.item
    readonly property var powerMenu: powerMenuL.item
    readonly property var net: netL.item
    readonly property var overview: overviewL.item
    readonly property var notifCenter: notifCenterL.item
    readonly property var files: filesL.item
    readonly property var media: mediaL.item
    readonly property var calendar: calendarL.item
    readonly property var sysRings: sysRingsL.item
    readonly property var timer: timerL.item
    readonly property var settings: settingsL.item
    readonly property var guide: guideL.item
    readonly property var eq: eqL.item

    Lock { id: lock }
    Curtain { id: curtain }

    function panel(loader) {
        if (!loader.item)
            loader.active = true;
        return loader.item;
    }
    FocusTrail {}
    Greeting {}

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
            timerPanel: timerL.item
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
        onPressed: panel(launcherL).toggle()
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
        onPressed: panel(notifCenterL).toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "files"
        onPressed: panel(filesL).toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcherCalc"
        onPressed: panel(launcherL).toggleCalc()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "clipboard"
        onPressed: panel(clipboardL).toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "wallpapers"
        onPressed: panel(wallpapersL).toggle()
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
        onPressed: panel(overviewL).toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "media"
        onPressed: panel(mediaL).toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "calendar"
        onPressed: panel(calendarL).toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "sysRings"
        onPressed: panel(sysRingsL).toggle()
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
        onPressed: panel(netL).toggle("wifi")
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "bluetooth"
        onPressed: panel(netL).toggle("bt")
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "powerMenu"
        onPressed: panel(powerMenuL).toggle()
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
        onPressed: panel(audioPanelL).toggle()
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
        onPressed: panel(settingsL).toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "timer"
        onPressed: panel(timerL).toggle()
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
                panel(timerL).open("count");
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "eq"
        onPressed: panel(eqL).toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "guide"
        onPressed: panel(guideL).open()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "deskEdit"
        onPressed: if (deskLoader.item) deskLoader.item.toggle()
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
