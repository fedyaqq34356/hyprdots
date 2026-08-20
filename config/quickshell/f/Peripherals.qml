pragma Singleton

import Quickshell
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property int threshold: 40

    readonly property var glyphs: ({
        [UPowerDeviceType.Mouse]:      "󰍽",
        [UPowerDeviceType.Keyboard]:   "󰌌",
        [UPowerDeviceType.Headset]:    "󰋎",
        [UPowerDeviceType.Headphones]: "󰋋",
        [UPowerDeviceType.GamingInput]: "󰊴"
    })

    readonly property var watched: {
        const out = [];
        const list = UPower.devices ? UPower.devices.values : [];
        for (const d of list) {
            if (!d || !d.ready || !d.isPresent) continue;
            if (d.isLaptopBattery) continue;
            if (glyphs[d.type] === undefined) continue;
            out.push(d);
        }
        return out;
    }

    readonly property var lowest: {
        let worst = null;
        for (const d of watched) {
            const pct = d.percentage * 100;
            if (pct > root.threshold) continue;
            if (!worst || pct < worst.percentage * 100) worst = d;
        }
        return worst;
    }

    readonly property bool low: lowest !== null
    readonly property int percent: low ? Math.round(lowest.percentage * 100) : 0
    readonly property string glyph: low ? (glyphs[lowest.type] || "󰂑") : ""
    readonly property string model: low && lowest.model ? lowest.model : ""
    readonly property bool critical: low && percent <= 15
}
