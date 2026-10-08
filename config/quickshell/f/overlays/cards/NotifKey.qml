import QtQuick
import "root:/design"

Rectangle {
    id: key
    property string label: ""
    property color tint: Colors.accent
    property bool lead: false

    signal hit()

    radius: height / 2
    antialiasing: true
    color: key.lead
        ? Colors.alpha(key.tint, hov.hovered ? 0.55 : 0.38)
        : Colors.alpha(Colors.fg, hov.hovered ? 0.18 : 0.10)
    scale: tap.pressed ? 0.94 : 1

    Behavior on color { ColorAnimation { duration: Motion.fast } }
    Behavior on scale { Spring {} }

    Text {
        anchors.centerIn: parent
        width: Math.min(implicitWidth, key.width - 16)
        text: key.label
        color: Colors.fg
        elide: Text.ElideRight
        font.family: Fonts.display
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: tap; onTapped: key.hit() }
}
