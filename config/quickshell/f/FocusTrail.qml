import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Scope {
    id: root

    property real fromX: -1
    property real fromY: -1
    property real toX: -1
    property real toY: -1
    property bool drawing: false

    readonly property int dur: 420

    Process {
        id: probe
        command: ["hyprctl", "activewindow", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                let w;
                try {
                    w = JSON.parse(this.text);
                } catch (e) {
                    return;
                }
                if (!w || !w.at || !w.size)
                    return;

                const mon = Hyprland.focusedMonitor;
                const ox = mon ? mon.x : 0;
                const oy = mon ? mon.y : 0;

                const cx = w.at[0] - ox + w.size[0] / 2;
                const cy = w.at[1] - oy + w.size[1] / 2;

                if (root.toX >= 0 && (Math.abs(cx - root.toX) > 8
                                   || Math.abs(cy - root.toY) > 8)) {
                    root.fromX = root.toX;
                    root.fromY = root.toY;
                    root.toX = cx;
                    root.toY = cy;
                    root.drawing = false;
                    root.drawing = true;
                } else {
                    root.toX = cx;
                    root.toY = cy;
                }
            }
        }
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "activewindowv2" || event.name === "activewindow")
                probe.running = true;
        }
    }

    LazyLoader {
        active: root.drawing

        PanelWindow {
            id: win
            WlrLayershell.namespace: "qs-focustrail"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            screen: Focus.screen

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            color: "transparent"
            mask: Region {}

            readonly property real dx: root.toX - root.fromX
            readonly property real dy: root.toY - root.fromY
            readonly property real len: Math.sqrt(dx * dx + dy * dy)
            readonly property real ang: Math.atan2(dy, dx) * 180 / Math.PI

            Item {
                id: path
                x: root.fromX
                y: root.fromY - 1.5
                width: win.len
                height: 3
                opacity: 0

                transformOrigin: Item.Left
                rotation: win.ang

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.0) }
                        GradientStop { position: 0.45; color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.85) }
                        GradientStop { position: 1.0; color: Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g, Colors.accentAlt.b, 0.0) }
                    }
                }
            }

            Rectangle {
                id: dot
                width: 0
                height: width
                radius: width / 2
                x: root.toX - width / 2
                y: root.toY - width / 2
                color: "transparent"
                border.width: 2
                border.color: Colors.accent
                opacity: 0
            }

            ParallelAnimation {
                running: true

                SequentialAnimation {
                    NumberAnimation { target: path; property: "opacity"; from: 0; to: 1; duration: 110; easing.type: Easing.OutCubic }
                    NumberAnimation { target: path; property: "opacity"; to: 0; duration: root.dur - 110; easing.type: Easing.InCubic }
                }

                SequentialAnimation {
                    PauseAnimation { duration: 80 }
                    ParallelAnimation {
                        NumberAnimation { target: dot; property: "width"; from: 6; to: 86; duration: 340; easing.type: Easing.OutCubic }
                        SequentialAnimation {
                            NumberAnimation { target: dot; property: "opacity"; from: 0; to: 0.7; duration: 90 }
                            NumberAnimation { target: dot; property: "opacity"; to: 0; duration: 250 }
                        }
                    }
                }

                onFinished: root.drawing = false
            }
        }
    }
}
