pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    signal failed(string glyph, string text)
    signal finished(string glyph, string text)

    property bool searching: false
    property string searchScreen: ""
    property string query: ""
    property int cursor: 0
    property string mode: "app"
    property string calc: ""
    property string hint: ""
    property string hintGlyph: ""
    property color hue: "#ffffff"
    property bool hueOn: false

    readonly property int searchW: 600
    readonly property int searchH: 44

    signal keyed(int dir)
    signal nomatch()

    property real isleX: 0
    property real isleY: 0
    property real isleW: 0
    property real isleH: 0
    property string isleScreen: ""

    signal launching(var info)

    signal wallApplied(string path, color tone)
}
