pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    readonly property int chip: 12
    readonly property int field: 16
    readonly property int card: 28
    readonly property int modal: 32

    readonly property int detail: 6

    readonly property int padTight: 10
    readonly property int padBase: 16
    readonly property int padLoose: 28
}
