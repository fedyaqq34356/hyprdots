pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string statePath:
        (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/dnd-mode"

    property bool active: false

    Process { id: writer }

    Component.onCompleted: root.sync()

    function sync() {
        writer.running = false;
        writer.command = root.active
            ? ["sh", "-c", "touch '" + root.statePath + "'"]
            : ["sh", "-c", "rm -f '" + root.statePath + "'"];
        writer.running = true;
    }

    function toggle() {
        root.active = !root.active;
        root.sync();
    }
}
