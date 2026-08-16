pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property color bg:        "{{colors.surface.default.hex}}"
    readonly property color bgAlt:     "{{colors.surface_variant.default.hex}}"
    readonly property color fg:        "{{colors.on_surface.default.hex}}"
    readonly property color fgDim:     "{{colors.on_surface_variant.default.hex}}"
    readonly property color outline:   "{{colors.outline.default.hex}}"
    readonly property color outlineFaint: "{{colors.outline_variant.default.hex}}"
    readonly property color accent:    "{{colors.primary.default.hex}}"
    readonly property color accentAlt: "{{colors.tertiary.default.hex}}"
    readonly property color accentText:  "{{colors.on_primary.default.hex}}"

    readonly property color good: "#a6e3a1"
    readonly property color warn: "#f5c777"
    readonly property color bad:  "#f38ba8"
}
