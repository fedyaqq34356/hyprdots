import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick

ShellRoot {

    PwObjectTracker {
        objects: {
            const list = [];
            if (Pipewire.defaultAudioSink) list.push(Pipewire.defaultAudioSink);
            if (Pipewire.defaultAudioSource) list.push(Pipewire.defaultAudioSource);
            return list;
        }
    }

    Bar {}
    Osd {}
    Notifications {}
    FullscreenFlash {}

    Launcher { id: launcher }
    Clipboard { id: clipboard }
    WallpaperPicker { id: wallpapers }
    AudioPanel { id: audioPanel }

    GlobalShortcut {
        appid: "quickshell"
        name: "launcher"
        onPressed: launcher.toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "clipboard"
        onPressed: clipboard.toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "wallpapers"
        onPressed: wallpapers.toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volumeUp"
        onPressed: {
            const a = Pipewire.defaultAudioSink?.audio;
            if (a) { a.muted = false; a.volume = Math.min(1, a.volume + 0.05); }
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volumeDown"
        onPressed: {
            const a = Pipewire.defaultAudioSink?.audio;
            if (a) a.volume = Math.max(0, a.volume - 0.05);
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "volumeMute"
        onPressed: {
            const a = Pipewire.defaultAudioSink?.audio;
            if (a) a.muted = !a.muted;
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "audioPanel"
        onPressed: audioPanel.toggle()
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "micUp"
        onPressed: {
            const a = Pipewire.defaultAudioSource?.audio;
            if (a) { a.muted = false; a.volume = Math.min(1, a.volume + 0.05); }
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "micDown"
        onPressed: {
            const a = Pipewire.defaultAudioSource?.audio;
            if (a) a.volume = Math.max(0, a.volume - 0.05);
        }
    }

    GlobalShortcut {
        appid: "quickshell"
        name: "micMute"
        onPressed: {
            const a = Pipewire.defaultAudioSource?.audio;
            if (a) a.muted = !a.muted;
        }
    }
}
