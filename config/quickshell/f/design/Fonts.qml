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

    readonly property int titleSize: 17
    readonly property int headingSize: 14
    readonly property int bodySize: 12
    readonly property int smallSize: 10
}
