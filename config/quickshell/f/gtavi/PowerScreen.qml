import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "root:/services"

Scope {
    id: root

    property string phase: "closed"
    property var targetScreen: null

    function pickScreen() {
        const m = Hyprland.focusedMonitor;
        if (m)
            for (const s of Quickshell.screens)
                if (s.name === m.name)
                    return s;
        return Quickshell.screens.length > 0 ? Quickshell.screens[0] : null;
    }

    function toggle() { phase === "open" ? close() : open(); }

    function open() {
        if (phase === "open")
            return;
        targetScreen = pickScreen();
        if (!targetScreen)
            return;
        if (phase === "closing") {
            phase = "closed";
            Qt.callLater(() => { root.phase = "open"; });
        } else {
            phase = "open";
        }
        Sfx.panel(true);
    }

    function close() {
        if (phase !== "open")
            return;
        phase = "closing";
        Sfx.panel(false);
        if (scene.item)
            scene.item.leave(null);
        else
            phase = "closed";
    }

    function finished() {
        if (phase === "closing")
            phase = "closed";
    }

    Process { id: runner }

    function run(action) {
        phase = "closed";
        if (action.farewell) {
            Sfx.sessionExit();
            Bye.run(action.run);
        } else {
            Sfx.tapAlt();
            runner.command = action.run;
            runner.running = true;
        }
    }

    property string uptimeText: ""
    Process {
        id: uptime
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeText = text.trim().replace(/^up\s+/, "")
        }
    }
    onPhaseChanged: if (phase === "open") uptime.running = true

    PanelWindow {
        WlrLayershell.namespace: "qs-gtavi-power"
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
            sourceComponent: PowerScene {
                ctl: root
            }
        }
    }

    IpcHandler {
        target: "gtaviPower"
        function toggle(): string { root.toggle(); return root.phase; }
        function open(): string { root.open(); return root.phase; }
        function close(): string { root.close(); return root.phase; }
        function select(i: int): string {
            if (scene.item) scene.item.selected = i;
            return root.phase;
        }
    }
}
