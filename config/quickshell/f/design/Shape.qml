pragma Singleton

import Quickshell
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property int knob: root.compress(Prefs.cornerRadius)

    function compress(value) {
        const v = Number(value);
        if (!isFinite(v) || v < 0)
            return 12;
        return Math.floor(v <= 24 ? v : 24 + Math.pow(v - 24, 0.55));
    }

    readonly property int chip: Scaler.s(root.knob)
    readonly property int field: Scaler.s(root.knob * 4 / 3)
    readonly property int card: Scaler.s(root.knob * 7 / 3)
    readonly property int modal: Scaler.s(root.knob * 8 / 3)

    readonly property int detail: Scaler.s(root.knob / 2)

    readonly property int padTight: Scaler.s(10)
    readonly property int padBase: Scaler.s(16)
    readonly property int padLoose: Scaler.s(28)
}
