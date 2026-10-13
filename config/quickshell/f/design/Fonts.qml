pragma Singleton

import Quickshell
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property string display: Prefs.apple ? "SF Pro Display" : Prefs.fontDisplay
    readonly property string mono: Prefs.apple ? "SF Pro Display" : "JetBrainsMono Nerd Font"
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

    readonly property int tiny:   10
    readonly property int small:  11
    readonly property int text:   12
    readonly property int medium: 14
    readonly property int large:  17
    readonly property int larger: 20
    readonly property int big:    24
    readonly property int bigger: 28
    readonly property int huge:   34
    readonly property int giant:  40

    readonly property var nums: ({ "tnum": 1 })
}
