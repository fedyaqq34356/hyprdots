import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: rk

    property string glyph: ""
    property color tint: Colors.accent
    property int size: 40
    property bool playPause: false
    property bool playing: false
    signal activated()

    width: rk.size
    height: rk.size

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        antialiasing: true
        color: Colors.alpha(rk.tint, rkHover.hovered ? 0.36 : 0.24)
        scale: rkTap.pressed ? 0.86 : (rkHover.hovered ? 1.06 : 1)
        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Behavior on scale { Spring {} }

        PlayGlyph {
            anchors.centerIn: parent
            visible: rk.playPause
            playing: rk.playing
            size: Math.round(rk.size * 0.36)
            ink: Qt.lighter(rk.tint, 1.15)
        }

        Text {
            anchors.centerIn: parent
            visible: !rk.playPause
            text: rk.glyph
            color: Qt.lighter(rk.tint, 1.15)
            font.family: Fonts.glyph
            font.pixelSize: Math.round(rk.size * 0.44)
        }
    }

    HoverHandler { id: rkHover; cursorShape: Qt.PointingHandCursor }
    TapHandler { id: rkTap; onTapped: rk.activated() }
}
