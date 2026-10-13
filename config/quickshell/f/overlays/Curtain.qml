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
        faceTex.scheduleUpdate();
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
            from: 0; to: 1; duration: 1500
            easing.type: Easing.Linear
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

        Item {
            id: faceBox
            anchors.fill: parent

            LockFace {
                anchors.fill: parent
                live: root.armed || root.showing || root.peek
            }
        }

        ShaderEffectSource {
            id: faceTex
            sourceItem: faceBox
            hideSource: true
            live: root.peek
            visible: false
        }

        ShaderEffect {
            anchors.fill: parent
            fragmentShader: "root:/design/shaders/melt.frag.qsb"
            blending: true

            property var source: faceTex
            property real progress: root.k
            property vector2d sink: Qt.vector2d(win.tcx / Math.max(1, win.width),
                                                (win.tcy + win.th * 0.25) / Math.max(1, win.height))
            property real aspect: win.width / Math.max(1, win.height)
            property color rimColor: Colors.accent
        }
    }
}
