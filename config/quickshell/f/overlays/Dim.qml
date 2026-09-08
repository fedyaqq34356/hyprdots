import Quickshell
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/services"

Scope {
    id: root

    readonly property real depth: 0.55

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win
            required property var modelData

            WlrLayershell.namespace: "qs-dim"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore

            screen: modelData
            color: "transparent"

            visible: shade.opacity > 0.001

            anchors { top: true; bottom: true; left: true; right: true }

            mask: Region {}

            Rectangle {
                id: shade
                anchors.fill: parent
                color: "black"
                opacity: Idle.dimming ? root.depth : 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: Idle.dimming ? Motion.lazy * 2 : Motion.base
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }
}
