import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/services"

Scope {
    id: root

    Component.onCompleted: IslandBus.pourReady = true
    Component.onDestruction: IslandBus.pourReady = false

    property string path: ""
    property string screenName: ""
    property real sx: 0
    property real sy: 0
    property real progress: 0
    property real fade: 1
    property bool dry: false
    readonly property bool active: root.path !== ""

    readonly property string setterPath:
        Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper/set-wallpaper.sh"

    Connections {
        target: IslandBus
        function onWallPour(path, screen, x, y) { root.pour(path, screen, x, y); }
    }

    function pour(path, screen, x, y) {
        root.dry = false;
        if (root.active) {
            pourRun.stop();
            finish.stop();
            root.commit(root.path, false);
        }
        root.progress = 0;
        root.fade = 1;
        root.sx = x;
        root.sy = y;
        root.screenName = screen;
        root.path = path;
        guard.restart();
    }

    Timer {
        id: guard
        interval: 2500
        onTriggered: if (root.active && root.progress === 0) root.abort()
    }

    function abort() {
        const p = root.path;
        root.path = "";
        IslandBus.pouring = false;
        plain.command = [root.setterPath, p];
        plain.running = true;
    }

    function start() {
        guard.stop();
        IslandBus.pouring = true;
        Sfx.swoosh();
        pourRun.restart();
    }

    function commit(p, wait) {
        setter.wait = wait;
        setter.command = ["env", "WALL_INSTANT=1", root.setterPath, p];
        setter.running = true;
    }

    NumberAnimation {
        id: pourRun
        target: root; property: "progress"
        from: 0; to: 1; duration: 1900
        easing.type: Easing.Linear
        onFinished: root.dry ? finish.restart() : root.commit(root.path, true)
    }

    Process {
        id: setter
        property bool wait: true
        onExited: if (setter.wait) finish.restart()
    }
    Process { id: plain }

    SequentialAnimation {
        id: finish
        PauseAnimation { duration: 220 }
        ScriptAction { script: IslandBus.pouring = false }
        NumberAnimation { target: root; property: "fade"; to: 0; duration: 380; easing.type: Easing.InOutCubic }
        ScriptAction { script: root.path = "" }
    }

    IpcHandler {
        target: "wallPour"
        function demo(): void {
            cur.running = true;
        }
        function preview(path: string): void {
            const s = Focus.screen;
            root.pour(path, s.name, IslandBus.isleW > 0 ? IslandBus.isleX + IslandBus.isleW / 2 : s.width / 2,
                      IslandBus.isleW > 0 ? IslandBus.isleY + IslandBus.isleH / 2 : 16);
            root.dry = true;
        }
    }
    Process {
        id: cur
        command: ["cat", Quickshell.env("HOME") + "/.config/hypr/current-wallpaper"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim();
                const s = Focus.screen;
                if (p !== "" && s)
                    root.pour(p, s.name, IslandBus.isleW > 0 ? IslandBus.isleX + IslandBus.isleW / 2 : s.width / 2,
                              IslandBus.isleW > 0 ? IslandBus.isleY + IslandBus.isleH / 2 : 16);
            }
        }
    }

    LazyLoader {
        active: root.active

        PanelWindow {
            id: win

            WlrLayershell.namespace: "qs-wallpour"
            WlrLayershell.layer: WlrLayer.Bottom
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            screen: {
                const all = Quickshell.screens;
                for (let i = 0; i < all.length; i++)
                    if (all[i].name === root.screenName) return all[i];
                return Focus.screen;
            }
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            mask: Region {}

            Image {
                id: img
                visible: false
                source: root.path !== "" ? "file://" + root.path : ""
                asynchronous: true
                cache: false
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(win.screen ? win.screen.width : 1920,
                                    win.screen ? win.screen.height : 1080)
                onStatusChanged: {
                    if (img.status === Image.Ready && root.progress === 0 && !pourRun.running)
                        startLater.restart();
                    else if (img.status === Image.Error)
                        root.abort();
                }
            }
            Timer { id: startLater; interval: 50; onTriggered: root.start() }

            ShaderEffect {
                anchors.fill: parent
                visible: img.status === Image.Ready
                opacity: root.fade
                fragmentShader: "root:/design/shaders/wallpour2.frag.qsb"
                blending: true

                property var source: img
                property vector2d size: Qt.vector2d(width, height)
                property vector2d picSize: Qt.vector2d(Math.max(1, img.implicitWidth),
                                                       Math.max(1, img.implicitHeight))
                property vector2d sink: Qt.vector2d(root.sx, root.sy)
                property real progress: root.progress
                property color tone: Colors.accent
            }
        }
    }
}
