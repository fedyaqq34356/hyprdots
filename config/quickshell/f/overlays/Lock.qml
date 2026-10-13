import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool locked: false

    WeatherHold { active: root.locked }

    signal unlocked()

    readonly property string shot:
        "file://" + Quickshell.env("XDG_RUNTIME_DIR") + "/lock-bg.png"

    readonly property string mono: Fonts.mono

    function lock() {
        if (root.locked) return;
        root.locked = true;
    }

    IpcHandler {
        target: "lock"

        function lock(): string {
            root.lock();
            return "locked";
        }

        function state(): string {
            return root.locked ? "locked" : "unlocked";
        }

        function preview(on: bool): string {
            previewHost.locked = on;
            return on ? "preview" : "closed";
        }
        function type(n: int): void { if (previewLoader.item) previewLoader.item.view.simType(n); }
        function fail(): void { if (previewLoader.item) previewLoader.item.view.simFail(); }
        function ok(): void { if (previewLoader.item) previewLoader.item.view.simOk(); }
        function wake(on: bool): void { if (previewLoader.item) previewLoader.item.view.simWake(on); }
    }

    QtObject {
        id: previewHost
        property bool locked: false
        signal unlocked()
    }

    LazyLoader {
        id: previewLoader
        active: previewHost.locked

        PanelWindow {
            id: previewWin
            readonly property alias view: previewView
            WlrLayershell.namespace: "qs-lock-preview"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            screen: Focus.screen
            anchors { top: true; bottom: true; left: true; right: true }
            exclusiveZone: -1
            color: "black"

            LockView {
                id: previewView
                anchors.fill: parent
                host: previewHost
                screen: previewWin.screen
                preview: true
            }
        }
    }

    WlSessionLock {
        id: session
        locked: root.locked

        surface: WlSessionLockSurface {
            id: lockSurface
            color: "transparent"

            LockView {
                anchors.fill: parent
                host: root
                screen: lockSurface.screen
            }
        }
    }
}
