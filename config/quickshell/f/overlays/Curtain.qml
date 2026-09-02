import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "root:/design"

Scope {
    id: root

    property bool showing: false

    readonly property string shot:
        "file://" + Quickshell.env("XDG_RUNTIME_DIR") + "/lock-bg.png"

    function up() {
        if (root.showing)
            return;
        root.showing = true;
    }

    IpcHandler {
        target: "curtain"

        function up(): string {
            root.up();
            return "ok";
        }
    }

    LazyLoader {
        active: root.showing

        PanelWindow {
            id: win
            WlrLayershell.namespace: "qs-curtain"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            color: "transparent"
            mask: Region {}

            Item {
                id: sheet
                anchors.fill: parent

                transform: Translate {
                    id: slide
                    y: 0
                    x: 0
                }

                Image {
                    anchors.fill: parent
                    source: root.shot
                    fillMode: Image.PreserveAspectCrop
                    cache: false
                    asynchronous: true
                }

                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
                }

                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 2
                    color: Colors.accent
                    opacity: 0.75
                }
            }

            ParallelAnimation {
                id: leave
                running: true

                NumberAnimation {
                    target: slide
                    property: "y"
                    from: 0
                    to: -win.height - 8
                    duration: 620
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation {
                    target: slide
                    property: "x"
                    from: 0
                    to: Math.round(win.width * 0.06)
                    duration: 620
                    easing.type: Easing.InOutCubic
                }

                NumberAnimation {
                    target: sheet
                    property: "opacity"
                    from: 1
                    to: 0.85
                    duration: 620
                    easing.type: Easing.InQuad
                }

                onFinished: root.showing = false
            }
        }
    }
}
