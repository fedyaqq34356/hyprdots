pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property string state: ""
    readonly property bool active: false
    readonly property bool speech: false
    readonly property string effort: "low"
    readonly property string tool: ""
    readonly property bool gaming: false
    readonly property string summary: ""
    readonly property real me: 0
    readonly property real voice: 0
    readonly property string askCmd: ""

    function answer(password) {}
    function cancel() {}
    function attach(action) {}
}
