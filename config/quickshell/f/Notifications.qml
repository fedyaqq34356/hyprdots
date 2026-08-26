import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import Quickshell.Wayland

Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: function (n) {
            n.tracked = true;

            if (n.transient)
                return;

            if (n.urgency === NotificationUrgency.Critical)
                Sfx.critical();
            else
                Sfx.notify();
        }
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-notifications"
        id: win
        screen: Focus.screen

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusiveZone: 0
        color: "transparent"

        mask: Region { item: col }

        Column {
            id: col
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 42
            anchors.rightMargin: 12
            spacing: 8

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 320
                    easing.type: Easing.OutBack
                    easing.overshoot: 0.9
                }
            }

            Repeater {
                model: server.trackedNotifications

                NotificationCard {
                    onClosed: modelData.dismiss()
                }
            }
        }
    }
}
