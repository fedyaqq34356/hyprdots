pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/services"

Singleton {
    id: root

    property bool shown: false
    property var pending: null

    readonly property int hold: 500

    function run(command) {
        if (root.shown)
            return;
        root.pending = command;
        root.shown = true;
    }

    Process { id: runner }

    Timer {
        id: fire
        interval: root.hold
        repeat: false
        onTriggered: {
            if (root.pending) {
                runner.command = root.pending;
                runner.running = true;
                root.pending = null;
            }
        }
    }

    LazyLoader {
        active: root.shown

        PanelWindow {
            WlrLayershell.namespace: "qs-bye"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: -1
            color: "transparent"

            Rectangle {
                id: veil
                anchors.fill: parent
                color: Colors.bg
                opacity: 0

                NumberAnimation on opacity {
                    from: 0
                    to: 1
                    duration: 220
                    easing.type: Easing.OutCubic
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 10
                opacity: 0

                NumberAnimation on opacity {
                    from: 0
                    to: 1
                    duration: 260
                    easing.type: Easing.OutCubic
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Bye"
                    color: Colors.accent
                    font.family: "JetBrainsMono Nerd Font ExtraBold"
                    font.pixelSize: 64

                    transform: Scale {
                        id: pop
                        origin.x: 0
                        origin.y: 0
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 90
                    height: 2
                    radius: 1
                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.45)
                }
            }

            Component.onCompleted: fire.start()
        }
    }
}
