pragma Singleton

import Quickshell
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property real uiScale: root.clamp(Prefs.uiScale)

    readonly property var monitorScales:
        Prefs.monitorScales && typeof Prefs.monitorScales === "object"
            ? Prefs.monitorScales : ({})

    readonly property string focusedScreen:
        Focus.screen ? Focus.screen.name : ""

    function clamp(value) {
        const v = Number(value);
        if (!isFinite(v) || v <= 0)
            return 1.0;
        return Math.max(0.5, Math.min(3.0, v));
    }

    function forScreen(name) {
        if (name && root.monitorScales[name] !== undefined)
            return root.clamp(root.monitorScales[name]);
        return root.uiScale;
    }

    function s(value, screenName) {
        return Math.round(value * root.forScreen(screenName !== undefined
                                                 ? screenName
                                                 : root.focusedScreen));
    }

    function f(value, screenName) {
        return value * root.forScreen(screenName !== undefined
                                      ? screenName
                                      : root.focusedScreen);
    }
}
