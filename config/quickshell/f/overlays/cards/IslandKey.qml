import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: key

    property string glyph: ""
    property int size: 22
    property color ink: Colors.fg
    property bool playPause: false
    property bool playing: false
    signal activated()

    width: key.size + 18
    height: key.size + 18
    opacity: key.enabled ? 1 : 0.3

    Rectangle {
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: width / 2
        antialiasing: true
        color: Colors.alpha(key.ink, keyTap.pressed ? 0.16 : 0.08)
        opacity: keyHover.hovered ? 1 : 0
        scale: keyHover.hovered ? 1 : 0.6
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        Behavior on scale { Spring {} }
    }

    PlayGlyph {
        anchors.centerIn: parent
        visible: key.playPause
        playing: key.playing
        size: Math.round(key.size * 0.78)
        ink: key.ink
        scale: keyTap.pressed ? 0.8 : 1
        Behavior on scale { Spring {} }
    }

    Text {
        anchors.centerIn: parent
        visible: !key.playPause
        text: key.glyph
        color: key.ink
        font.family: Fonts.glyph
        font.pixelSize: key.size
        scale: keyTap.pressed ? 0.8 : 1
        Behavior on scale { Spring {} }
    }

    HoverHandler { id: keyHover; cursorShape: Qt.PointingHandCursor }
    TapHandler {
        id: keyTap
        onTapped: key.activated()
    }
}
