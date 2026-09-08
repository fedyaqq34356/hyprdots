pragma Singleton

import Quickshell
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property string display: Prefs.fontDisplay
    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string glyph: "JetBrainsMono Nerd Font"

    readonly property var displayChoices: [
        { value: "Adwaita Sans",  label: "adwaita" },
        { value: "SF Pro Display", label: "sf pro" },
        { value: "JetBrainsMono Nerd Font", label: "mono only" }
    ]

    readonly property real titleSize: Scaler.f(17)
    readonly property real headingSize: Scaler.f(14)
    readonly property real bodySize: Scaler.f(12)
    readonly property real smallSize: Scaler.f(10)
}
