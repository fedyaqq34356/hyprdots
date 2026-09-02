import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: frame

    required property var entry
    required property real fieldWidth
    required property real fieldHeight

    readonly property bool editing: DeskLayout.editing
    readonly property bool selected: DeskLayout.selected === entry.key

    x: entry.x * fieldWidth - width / 2
    y: entry.y * fieldHeight - height / 2

    width: content.width * entry.size
    height: content.height * entry.size

    Behavior on x { enabled: !dragArea.drag.active; NumberAnimation { duration: Motion.base } }
    Behavior on y { enabled: !dragArea.drag.active; NumberAnimation { duration: Motion.base } }

    Item {
        id: content

        width: widget.implicitWidth > 0 ? widget.implicitWidth : 1
        height: widget.implicitHeight > 0 ? widget.implicitHeight : 1

        transform: Scale {
            xScale: frame.entry.size
            yScale: frame.entry.size
        }

        Loader {
            id: widget

            sourceComponent: {
                switch (frame.entry.type) {
                case "clock": return clockFace;
                case "media": return mediaFace;
                case "weather": return weatherFace;
                case "usage": return usageFace;
                case "screentime": return timeFace;
                }
                return null;
            }
        }

        Component { id: clockFace;   DeskClock   { variant: frame.entry.face } }
        Component { id: mediaFace;   DeskMedia   { variant: frame.entry.face } }
        Component { id: weatherFace; DeskWeather { variant: frame.entry.face } }
        Component { id: usageFace;   DeskUsage   { variant: frame.entry.face } }
        Component { id: timeFace;    DeskTime    { variant: frame.entry.face } }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -10
        radius: 18
        color: frame.selected
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.10)
            : "transparent"
        border.width: 1
        border.color: frame.selected
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.8)
            : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.35)

        opacity: frame.editing ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: Motion.base } }
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    MouseArea {
        id: dragArea
        anchors.fill: parent
        anchors.margins: -10
        enabled: frame.editing
        visible: frame.editing
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        drag.target: frame
        drag.threshold: 2

        property bool moved: false

        onPressed: {
            DeskLayout.selected = frame.entry.key;
            dragArea.moved = false;
            Sfx.pick();
        }

        onPositionChanged: {
            if (!drag.active)
                return;
            dragArea.moved = true;
            Sfx.tick();
        }

        onReleased: {
            if (!dragArea.moved)
                return;
            DeskLayout.update(frame.entry.key, {
                x: (frame.x + frame.width / 2) / frame.fieldWidth,
                y: (frame.y + frame.height / 2) / frame.fieldHeight
            });
            DeskLayout.save();
            Sfx.fill();
        }

        onWheel: (wheel) => {
            DeskLayout.resize(frame.entry.key, wheel.angleDelta.y > 0 ? 0.1 : -0.1);
            Sfx.tick();
        }
    }

    Row {
        id: tools

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 18
        spacing: 8

        opacity: frame.editing && frame.selected ? 1 : 0
        visible: opacity > 0.01
        scale: frame.editing && frame.selected ? 1 : 0.9
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.base
                easing.type: Easing.Bezier
                easing.bezierCurve: Motion.snap
            }
        }

        IconButton {
            glyph: "󰑓"
            tip: I18n.t("act.face")
            tint: Colors.accent
            onActivated: DeskLayout.cycleFace(frame.entry.key)
        }

        IconButton {
            glyph: "󰐕"
            tip: I18n.t("act.bigger")
            tint: Colors.accentAlt
            onActivated: DeskLayout.resize(frame.entry.key, 0.15)
        }

        IconButton {
            glyph: "󰍴"
            tip: I18n.t("act.smaller")
            tint: Colors.accentAlt
            onActivated: DeskLayout.resize(frame.entry.key, -0.15)
        }

        IconButton {
            glyph: "󰩹"
            tip: I18n.t("act.remove")
            tint: Colors.bad
            onActivated: DeskLayout.remove(frame.entry.key)
        }
    }
}
