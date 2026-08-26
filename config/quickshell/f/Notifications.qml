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

            // Apps that push transient progress updates (volume, download
            // percentages) would otherwise chirp on every step.
            if (n.transient)
                return;

            // Sfx rate-limits, so a burst of notifications does not turn
            // into a burst of overlapping blips.
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

            // Cards below a dismissed one slide up rather than jumping.
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

                // NotificationCard declares `required property var modelData`,
                // so the Repeater injects the model row into it directly.
                NotificationCard {
                    // The card plays its leave animation first, then asks to go.
                    onClosed: modelData.dismiss()
                }
            }
        }
    }
}
