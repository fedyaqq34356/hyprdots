pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Singleton {
    id: root

    readonly property bool enabled: Prefs.idleEnabled
    readonly property int lockAfter: Prefs.idleLockSec
    readonly property int screenOffAfter: Prefs.idleScreenOffSec

    readonly property int dimLead: Prefs.idleDimLeadSec
    readonly property int dimAfter:
        root.screenOffAfter > 0 && root.dimLead > 0
            ? Math.max(1, root.screenOffAfter - root.dimLead) : 0

    property bool dimming: false

    readonly property string guard:
        Quickshell.env("HOME") + "/.config/hypr/scripts/idle-guard.sh"

    property bool screenOff: false

    function run(action) {
        Quickshell.execDetached([root.guard, action]);
    }

    function wake() {
        if (!root.screenOff)
            return;
        root.screenOff = false;
        Quickshell.execDetached(["hyprctl", "dispatch", "dpms", "on"]);
    }

    IdleMonitor {
        enabled: root.enabled && root.lockAfter > 0
        timeout: root.lockAfter
        respectInhibitors: true

        onIsIdleChanged: {
            if (isIdle)
                root.run("lock");
        }
    }

    IdleMonitor {
        enabled: root.enabled && root.dimAfter > 0
        timeout: root.dimAfter
        respectInhibitors: true

        onIsIdleChanged: root.dimming = isIdle
    }

    IdleMonitor {
        enabled: root.enabled && root.screenOffAfter > 0
        timeout: root.screenOffAfter
        respectInhibitors: true

        onIsIdleChanged: {
            if (isIdle) {
                root.screenOff = true;
                root.run("dpms-off");
            } else {
                root.wake();
            }
        }
    }
}
