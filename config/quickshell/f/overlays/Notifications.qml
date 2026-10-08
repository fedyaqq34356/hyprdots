import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import Quickshell.Wayland
import "root:/design"
import "root:/services"

Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true
        inlineReplySupported: true

        onNotification: function (n) {
            const eaten = IslandConfig.s("enabled") && IslandConfig.on("notif")
                       && IslandConfig.s("eatPopups");

            const keep = eaten && !n.transient && !Dnd.active;
            NotifHistory.live = keep ? n : null;
            if (keep)
                root.eat(n);

            if (!n.transient)
                NotifHistory.add(n);

            if (Dnd.active)
                return;

            if (keep || !eaten)
                n.tracked = true;

            if (n.transient)
                return;

            if (n.urgency === NotificationUrgency.Critical)
                Sfx.critical();
            else
                Sfx.notify();
        }
    }

    property var eaten: ({})

    function eat(n) {
        const next = Object.assign({}, root.eaten);
        next[n.id] = true;
        root.eaten = next;
        n.closed.connect(() => {
            const left = Object.assign({}, root.eaten);
            delete left[n.id];
            root.eaten = left;
        });
    }

    readonly property int popups: {
        const list = server.trackedNotifications.values;
        let k = 0;
        for (let i = 0; i < list.length; i++) {
            if (!root.eaten[list[i].id])
                k++;
        }
        return k;
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-notifications"
        id: win
        screen: Focus.screen
        visible: root.popups > 0

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
            anchors.topMargin: Prefs.barAtTop ? 42 : 12
            anchors.rightMargin: 12
            spacing: 10

            move: Transition {
                SpringAnimation {
                    properties: "y"
                    spring: Motion.panelSpring
                    damping: Motion.panelDamping
                    mass: Motion.panelMass
                    epsilon: 0.001
                }
            }

            Repeater {
                model: server.trackedNotifications

                Loader {
                    id: slot
                    required property var modelData
                    active: !root.eaten[slot.modelData.id]
                    visible: slot.active
                    sourceComponent: Component {
                        NotificationCard {
                            modelData: slot.modelData
                            onClosed: slot.modelData.dismiss()
                        }
                    }
                }
            }
        }
    }
}
