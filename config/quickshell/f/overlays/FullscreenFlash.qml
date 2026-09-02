import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/services"

Scope {
    id: root

    property bool entering: true

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name !== "fullscreen")
                return;
            root.entering = event.data.trim() === "1";
            flash.restart();
        }
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-flash"
        id: win
        screen: Focus.screen
        visible: flash.running

        WlrLayershell.layer: WlrLayer.Overlay

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        mask: Region {}

        Rectangle {
            id: frame
            property real inset: 0

            anchors.centerIn: parent
            width: parent.width - inset * 2
            height: parent.height - inset * 2
            radius: root.entering ? 0 : 22
            color: "transparent"
            border.width: 3
            border.color: Colors.accent
            opacity: 0

            Rectangle {
                anchors.fill: parent
                anchors.margins: 6
                radius: parent.radius > 0 ? parent.radius - 4 : 0
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                      Colors.accentAlt.b, 0.55)
            }
        }

        ParallelAnimation {
            id: flash

            NumberAnimation {
                target: frame
                property: "inset"
                from: root.entering ? 90 : 0
                to: root.entering ? 0 : 90
                duration: 420
                easing.type: Easing.OutCubic
            }

            SequentialAnimation {
                NumberAnimation {
                    target: frame; property: "opacity"
                    from: 0; to: 0.9
                    duration: 130
                }
                NumberAnimation {
                    target: frame; property: "opacity"
                    to: 0
                    duration: 320
                    easing.type: Easing.InCubic
                }
            }
        }
    }
}
