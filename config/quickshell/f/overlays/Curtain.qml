import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "root:/design"
import "root:/services"

Scope {
    id: root

    property bool armed: false
    property bool showing: false
    property bool peek: false

    function up() {
        if (root.showing)
            return;
        root.showing = true;
        absorb.restart();
    }

    IpcHandler {
        target: "curtain"

        function up(): string {
            root.up();
            return "ok";
        }

        function peek(on: bool): string {
            root.peek = on;
            return on ? "shown" : "hidden";
        }
    }

    property real k: 0

    SequentialAnimation {
        id: absorb
        ScriptAction { script: root.k = 0 }
        PauseAnimation { duration: 60 }
        NumberAnimation {
            target: root; property: "k"
            from: 0; to: 1; duration: 760
            easing.type: Easing.InOutCubic
        }
        ScriptAction {
            script: {
                Emergence.launch();
                root.showing = false;
                root.k = 0;
            }
        }
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-curtain"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        screen: Focus.screen
        visible: root.armed || root.showing || root.peek

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"
        mask: Region {}

        readonly property real tw: IslandConfig.s("pillMin")
        readonly property real th: IslandConfig.s("pillHeight")
        readonly property real tcx: win.width / 2 + IslandConfig.s("offsetX")
        readonly property real tcy: IslandConfig.s("inBar")
            ? BarConfig.s("barHeight", win.screen ? win.screen.name : "") / 2
            : IslandConfig.s("offsetY") + win.th / 2

        readonly property real e: root.k
        readonly property real ew: Math.pow(win.e, 0.85)
        readonly property real eh: Math.pow(win.e, 1.15)

        ClippingRectangle {
            id: shell

            width: Motion.mix(win.width, win.tw, win.ew)
            height: Motion.mix(win.height, win.th, win.eh)
            x: Motion.mix(win.width / 2, win.tcx, win.e) - width / 2
            y: Motion.mix(win.height / 2, win.tcy, win.e) - height / 2
            radius: Motion.mix(0, win.th / 2, Math.min(1, win.e * 1.6))
                    + Math.sin(win.e * Math.PI) * 60 * (1 - win.e)
            color: "black"
            opacity: win.e < 0.82 ? 1 : Math.max(0, 1 - (win.e - 0.82) / 0.18)

            LockFace {
                width: win.width
                height: win.height
                x: (shell.width - width) / 2
                y: (shell.height - height) / 2
                live: root.armed || root.showing || root.peek
                scale: Math.max(shell.width / win.width, shell.height / win.height)
            }

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: Math.max(0, (win.e - 0.45) / 0.55)
            }
        }
    }
}
