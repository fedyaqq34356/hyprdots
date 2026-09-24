pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property var dev: UPower.displayDevice
    readonly property bool present: root.dev !== null && root.dev.isLaptopBattery

    readonly property real fraction: root.dev ? root.dev.percentage : 0
    readonly property int percent: Math.round(root.fraction * 100)

    readonly property bool charging:
        root.dev !== null && root.dev.state === UPowerDeviceState.Charging
    readonly property bool full:
        root.dev !== null && root.dev.state === UPowerDeviceState.FullyCharged

    readonly property int lowAt: 15
    readonly property bool low: root.present && !root.charging
                                && root.percent <= root.lowAt

    readonly property string glyph: {
        if (root.charging)
            return "󰂄";
        if (!root.present)
            return "󰚥";
        const steps = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        const i = Math.max(0, Math.min(10, Math.round(root.percent / 10)));
        return steps[i];
    }

    readonly property string timeLabel: {
        if (!root.dev)
            return "";
        const t = root.charging ? root.dev.timeToFull : root.dev.timeToEmpty;
        if (!t || t <= 0)
            return "";
        const h = Math.floor(t / 3600);
        const m = Math.floor((t % 3600) / 60);
        return (h > 0 ? h + I18n.t("unit.hourSpace") : "") + m + I18n.t("unit.min");
    }
}
