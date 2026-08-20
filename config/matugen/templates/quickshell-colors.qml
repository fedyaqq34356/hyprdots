pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color bg:        "{{colors.surface.default.hex}}";
    readonly property color bgAlt:     "{{colors.surface_variant.default.hex}}";
    readonly property color fg:        "{{colors.on_surface.default.hex}}";
    readonly property color fgDim:     "{{colors.on_surface_variant.default.hex}}";
    readonly property color outline:   "{{colors.outline.default.hex}}";
    readonly property color outlineFaint: "{{colors.outline_variant.default.hex}}";
    readonly property color accent:    "{{colors.primary.default.hex}}";
    readonly property color accentAlt: "{{colors.tertiary.default.hex}}";
    readonly property color accentText:  "{{colors.on_primary.default.hex}}";

    readonly property color bad: "{{colors.error.default.hex}}"

    readonly property real statusSat:
        Math.max(0.45, Math.min(0.85, bad.hslSaturation))
    readonly property real statusLight:
        Math.max(0.55, Math.min(0.80, bad.hslLightness))

    readonly property color warn: Qt.hsla(0.11, statusSat, statusLight, 1)
    readonly property color good: Qt.hsla(0.36, statusSat, statusLight, 1)
}
