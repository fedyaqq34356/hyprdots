import Quickshell
import QtQuick
import QtQuick.Effects
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

    readonly property real minSize: {
        const it = widget.item;
        const w = content.width;
        const h = content.height;
        if (!it || w <= 0 || h <= 0)
            return 0.5;
        let lo = 0.5;
        if (it.minWidth !== undefined && it.minWidth > 0)
            lo = Math.max(lo, it.minWidth / w);
        if (it.minHeight !== undefined && it.minHeight > 0)
            lo = Math.max(lo, it.minHeight / h);
        return Math.min(lo, 3.0);
    }

    readonly property real maxSize: {
        const it = widget.item;
        const w = content.width;
        const h = content.height;
        if (!it || w <= 0 || h <= 0)
            return 3.0;
        let hi = 3.0;
        if (it.maxWidth !== undefined && it.maxWidth > 0)
            hi = Math.min(hi, it.maxWidth / w);
        if (it.maxHeight !== undefined && it.maxHeight > 0)
            hi = Math.min(hi, it.maxHeight / h);
        return Math.max(hi, frame.minSize);
    }

    function grow(delta) {
        DeskLayout.resize(frame.entry.key, delta, frame.minSize, frame.maxSize);
    }

    x: entry.x * fieldWidth - width / 2
    y: entry.y * fieldHeight - height / 2

    width: content.width * entry.size
    height: content.height * entry.size

    Behavior on x { enabled: !dragArea.drag.active; NumberAnimation { duration: Motion.base } }
    Behavior on y { enabled: !dragArea.drag.active; NumberAnimation { duration: Motion.base } }

    Bloom {
        target: frame
        tint: Colors.shadowTone
        tintAlt: Colors.shadowTone
        amount: 0.30
        inset: -Math.min(frame.width, frame.height) * 0.35
        radius: Math.min(frame.width, frame.height) * 0.5
        blurMax: 64
    }

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
                case "visualizer": return vizFace;
                case "timer": return timerFace;
                case "calendar": return calFace;
                case "battery": return battFace;
                case "disk": return diskFace;
                case "net": return netFace;
                case "notifs": return notifsFace;
                case "updates": return updatesFace;
                }
                return null;
            }
        }

        Component { id: clockFace;   DeskClock   { variant: frame.entry.face } }
        Component { id: mediaFace;   DeskMedia   { variant: frame.entry.face } }
        Component { id: weatherFace; DeskWeather { variant: frame.entry.face } }
        Component { id: usageFace;   DeskUsage   { variant: frame.entry.face } }
        Component { id: timeFace;    DeskTime    { variant: frame.entry.face } }
        Component { id: vizFace;     DeskVisualizer { variant: frame.entry.face } }
        Component { id: timerFace;   DeskTimer   { variant: frame.entry.face } }
        Component { id: calFace;     DeskCalendar { variant: frame.entry.face } }
        Component { id: battFace;    DeskBattery { variant: frame.entry.face } }
        Component { id: diskFace;    DeskDisk    { variant: frame.entry.face } }
        Component { id: netFace;     DeskNet     { variant: frame.entry.face } }
        Component { id: notifsFace;  DeskNotifs  { variant: frame.entry.face } }
        Component { id: updatesFace; DeskUpdates { variant: frame.entry.face } }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -10
        radius: Shape.field
        color: frame.selected ? Colors.alpha(Colors.accent, 0.10) : "transparent"
        border.width: 1
        border.color: frame.selected
            ? Colors.alpha(Colors.accent, 0.8)
            : Colors.alpha(Colors.outline, 0.35)

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
            frame.grow(wheel.angleDelta.y > 0 ? 0.1 : -0.1);
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

        FaceBadge {
            anchors.verticalCenter: parent.verticalCenter
            entry: frame.entry
        }

        IconButton {
            glyph: "󰐕"
            tip: I18n.t("act.bigger")
            tint: Colors.accentAlt
            onActivated: frame.grow(0.15)
        }

        IconButton {
            glyph: "󰍴"
            tip: I18n.t("act.smaller")
            tint: Colors.accentAlt
            onActivated: frame.grow(-0.15)
        }

        IconButton {
            glyph: "󰩹"
            tip: I18n.t("act.remove")
            tint: Colors.bad
            onActivated: DeskLayout.remove(frame.entry.key)
        }
    }
}
