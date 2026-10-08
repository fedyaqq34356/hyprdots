import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick

Scope {
    id: root

    property string phase: "closed"
    readonly property bool shown: phase === "open"

    property real releaseMs: GtaConfig.releaseFallbackMs
    property bool releaseResolved: false

    property real nowOffset: GtaConfig.debugNowOffsetMs

    property int session: 0
    property var targetScreen: null
    property real lastToggle: 0

    Instantiator {
        model: ["BarlowCondensed-Medium", "BarlowCondensed-SemiBold", "BarlowCondensed-Bold",
                "BarlowCondensed-ExtraBold", "BarlowCondensed-Black",
                "Lexend-Regular", "Lexend-Medium", "Lexend-SemiBold", "Lexend-Bold"]
        delegate: FontLoader {
            required property string modelData
            source: Qt.resolvedUrl("assets/fonts/" + modelData + ".ttf")
            onStatusChanged: if (status === FontLoader.Error)
                root.log("font failed to load: " + modelData)
        }
    }

    function log(msg) {
        const line = new Date().toISOString() + " " + msg + "\n";
        Quickshell.execDetached(["sh", "-c", "mkdir -p \"$1\" && printf '%s' \"$2\" >> \"$3\"",
                                 "sh", GtaConfig.cacheDir, line, GtaConfig.logPath]);
    }

    function pickScreen() {
        const m = Hyprland.focusedMonitor;
        if (m) {
            for (const s of Quickshell.screens)
                if (s.name === m.name)
                    return s;
        }
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function toggle() {
        const now = Date.now();
        if (now - lastToggle < 140)
            return;
        lastToggle = now;
        if (phase === "open")
            close();
        else
            open();
    }

    function open() {
        if (phase === "open")
            return;
        const s = pickScreen();
        if (!s) {
            log("open: no screen available");
            return;
        }
        targetScreen = s;
        session += 1;
        log("open #" + session + " on " + s.name);
        if (phase === "closing") {
            phase = "closed";
            Qt.callLater(() => { root.phase = "open"; });
        } else {
            phase = "open";
        }
    }

    function close() {
        if (phase !== "open")
            return;
        log("close requested");
        phase = "closing";
        if (scene.item)
            scene.item.leave();
        else
            phase = "closed";
    }

    function finished() {
        if (phase === "closing")
            phase = "closed";
    }

    Connections {
        target: Quickshell
        function onScreensChanged() {
            if (root.phase === "closed" || !root.targetScreen)
                return;
            for (const s of Quickshell.screens)
                if (s === root.targetScreen)
                    return;
            root.log("screen disconnected while open; closing");
            root.phase = "closed";
        }
    }

    Process {
        id: resolveRelease
        running: true
        command: ["date", "-d", "TZ=\"" + GtaConfig.timezone + "\" " + GtaConfig.releaseLocal, "+%s%3N"]
        stdout: StdioCollector {
            onStreamFinished: {
                const v = Number(text.trim());
                if (isFinite(v) && v > 1e12) {
                    root.releaseMs = v;
                    root.releaseResolved = true;
                    if (v !== GtaConfig.releaseFallbackMs)
                        root.log("release resolved to " + v + " (fallback constant differs: "
                                 + GtaConfig.releaseFallbackMs + ")");
                } else {
                    root.log("release: could not resolve '" + GtaConfig.releaseLocal + "' in "
                             + GtaConfig.timezone + "; using fallback constant");
                }
            }
        }
    }

    Timer {
        running: true
        interval: 15000
        onTriggered: prepare.running = true
    }

    Process {
        id: prepare
        command: [Qt.resolvedUrl("scripts/prepare.sh").toString().replace("file://", ""),
                  GtaConfig.videoPath, String(GtaConfig.videoSeek),
                  GtaConfig.wallpaperPath, GtaConfig.cacheDir]
        stdout: StdioCollector { onStreamFinished: if (text.trim()) root.log(text.trim()) }
        stderr: StdioCollector { onStreamFinished: if (text.trim()) root.log(text.trim()) }
    }

    function applyWallpaper() {
        if (!GtaConfig.applyWallpaper)
            return;
        Quickshell.execDetached(["sh", "-c",
            "\"$0\" \"$1\" \"$2\" \"$3\" >> \"$4\" 2>&1",
            Qt.resolvedUrl("scripts/wallpaper.sh").toString().replace("file://", ""),
            GtaConfig.wallpaperPath, GtaConfig.wallpaperTheme ? "1" : "0",
            String(GtaConfig.themeDelayMs), GtaConfig.logPath]);
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-gtavi"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.phase === "open" ? WlrKeyboardFocus.Exclusive
                                                          : WlrKeyboardFocus.None

        screen: root.targetScreen
        visible: root.phase !== "closed"

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"

        Loader {
            id: scene
            anchors.fill: parent
            active: root.phase !== "closed"
            focus: true

            sourceComponent: Experience {
                ctl: root
                session: root.session
            }
        }
    }

    IpcHandler {
        target: "gtavi"

        function toggle(): string { root.toggle(); return root.phase; }
        function open(): string { root.open(); return root.phase; }
        function close(): string { root.close(); return root.phase; }
        function skip(): string {
            if (scene.item) scene.item.skipIntro();
            return root.phase;
        }
        function preview(secondsBefore: string): string {
            if (secondsBefore === "off" || secondsBefore === "") {
                root.nowOffset = GtaConfig.debugNowOffsetMs;
                return "clock restored";
            }
            const s = Number(secondsBefore);
            if (!isFinite(s))
                return "usage: preview <seconds-before-release>|off";
            root.nowOffset = (root.releaseMs - s * 1000) - Date.now();
            return "now = release - " + s + "s";
        }
        function status(): string {
            const it = scene.item;
            return JSON.stringify({
                phase: root.phase,
                session: root.session,
                screen: root.targetScreen ? root.targetScreen.name : null,
                releaseMs: root.releaseMs,
                releaseResolved: root.releaseResolved,
                nowOffset: root.nowOffset,
                stage: it ? it.stage : null,
                remainingMs: it ? it.remainingMs : null,
                display: it ? it.displayText : null,
                media: it ? it.mediaState : null,
                sourceMs: it ? Math.round(it.sourceMs) : null
            });
        }
    }
}
