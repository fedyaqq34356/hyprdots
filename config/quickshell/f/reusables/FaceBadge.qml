import QtQuick
import "root:/design"
import "root:/services"

Rectangle {
    id: badge

    property var entry: null
    property string mono: Fonts.mono

    readonly property var faces: badge.entry && DeskLayout.registry[badge.entry.type]
        ? DeskLayout.registry[badge.entry.type].faces : []
    readonly property int index: badge.entry
        ? Math.max(0, badge.faces.indexOf(badge.entry.face)) : 0

    implicitWidth: row.implicitWidth + 22
    implicitHeight: 30
    width: implicitWidth
    height: implicitHeight
    radius: Shape.chip
    antialiasing: true

    color: hover.hovered
        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.20)
        : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.65)
    Behavior on color { ColorAnimation { duration: Motion.fast } }

    border.width: 1
    border.color: hover.hovered
        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45)
        : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.16)
    Behavior on border.color { ColorAnimation { duration: Motion.fast } }

    scale: tap.pressed ? 0.94 : (hover.hovered ? 1.04 : 1)
    Behavior on scale { NumberAnimation { duration: Motion.fast } }

    function step(dir) {
        if (!badge.entry || badge.faces.length === 0)
            return;
        const n = badge.faces.length;
        const next = badge.faces[((badge.index + dir) % n + n) % n];
        DeskLayout.update(badge.entry.key, { face: next });
        DeskLayout.save();
        Sfx.pick();
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onTapped: (point, button) => badge.step(button === Qt.RightButton ? -1 : 1)
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => badge.step(event.angleDelta.y > 0 ? -1 : 1)
    }

    Row {
        id: row

        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰑓"
            color: Colors.accent
            opacity: hover.hovered ? 1 : 0.75
            font.family: badge.mono
            font.pixelSize: 12
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: badge.entry ? badge.entry.face : ""
            color: hover.hovered ? Colors.fg : Colors.fgDim
            opacity: hover.hovered ? 1 : 0.8
            font.family: badge.mono
            font.pixelSize: 11
        }

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 3

            Repeater {
                model: badge.faces.length

                Rectangle {
                    required property int index

                    anchors.verticalCenter: parent.verticalCenter
                    width: index === badge.index ? 8 : 3
                    height: 3
                    radius: 1.5
                    antialiasing: true
                    color: index === badge.index
                        ? Colors.accent
                        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.35)

                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.base
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.snap
                        }
                    }
                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                }
            }
        }
    }
}
