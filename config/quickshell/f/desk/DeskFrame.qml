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
    required property string screenName

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

    readonly property bool stretchy: widget.item !== null && widget.item.stretchy === true
    property bool stretching: false
    property real liveW: 0
    property real liveH: 0
    property real stretchDX: 0
    property real stretchDY: 0

    function grow(delta) {
        DeskLayout.resize(frame.entry.key, delta, frame.minSize, frame.maxSize);
    }

    readonly property bool dragging: dragArea.held

    property real dragX: 0
    property real dragY: 0

    x: dragging ? dragX : entry.x * fieldWidth - width / 2 + stretchDX
    y: dragging ? dragY : entry.y * fieldHeight - height / 2 + stretchDY

    width: content.width * entry.size
    height: content.height * entry.size

    Behavior on x { enabled: !frame.dragging && !frame.stretching; NumberAnimation { duration: Motion.base } }
    Behavior on y { enabled: !frame.dragging && !frame.stretching; NumberAnimation { duration: Motion.base } }

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
                case "lyrics": return lyricsFace;
                case "notes": return notesFace;
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
        Component { id: notesFace;   DeskNotes   { variant: frame.entry.face } }
        Component {
            id: lyricsFace
            DeskLyrics {
                variant: frame.entry.face
                zoom: frame.entry.size
                boxWidth: frame.stretching ? frame.liveW : (frame.entry.w || 0)
                boxHeight: frame.stretching ? frame.liveH : (frame.entry.h || 0)
            }
        }
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
        cursorShape: dragArea.held ? Qt.ClosedHandCursor : Qt.OpenHandCursor

        property bool held: false

        property real rawX: 0
        property real rawY: 0
        property real pressSceneX: 0
        property real pressSceneY: 0

        property bool wasStuck: false

        onPressed: (mouse) => {
            DeskLayout.selected = frame.entry.key;
            dragArea.held = false;
            dragArea.wasStuck = false;

            const p = dragArea.mapToItem(frame.parent, mouse.x, mouse.y);
            dragArea.pressSceneX = p.x;
            dragArea.pressSceneY = p.y;
            dragArea.rawX = frame.x;
            dragArea.rawY = frame.y;
            Sfx.pick();
        }

        onPositionChanged: (mouse) => {
            if (!dragArea.pressed)
                return;

            const p = dragArea.mapToItem(frame.parent, mouse.x, mouse.y);
            const dx = p.x - dragArea.pressSceneX;
            const dy = p.y - dragArea.pressSceneY;

            if (!dragArea.held) {
                if (Math.abs(dx) < 2 && Math.abs(dy) < 2)
                    return;
                frame.dragX = frame.x;
                frame.dragY = frame.y;
                dragArea.held = true;
            }

            dragArea.rawX = frame.entry.x * frame.fieldWidth - frame.width / 2 + dx;
            dragArea.rawY = frame.entry.y * frame.fieldHeight - frame.height / 2 + dy;

            const cx = dragArea.rawX + frame.width / 2;
            const cy = dragArea.rawY + frame.height / 2;

            const free = (mouse.modifiers & Qt.AltModifier) !== 0;

            const mx = free ? { at: cx, guide: -1 }
                            : DeskLayout.magnet("x", cx, frame.fieldWidth,
                                                frame.entry.key, frame.screenName);
            const my = free ? { at: cy, guide: -1 }
                            : DeskLayout.magnet("y", cy, frame.fieldHeight,
                                                frame.entry.key, frame.screenName);

            frame.dragX = mx.at - frame.width / 2;
            frame.dragY = my.at - frame.height / 2;

            DeskLayout.guideScreen = frame.screenName;
            DeskLayout.guideX = mx.guide;
            DeskLayout.guideY = my.guide;

            const stuck = mx.at !== cx || my.at !== cy;
            if (stuck && !dragArea.wasStuck)
                Sfx.pick();
            else if (!stuck)
                Sfx.tick();
            dragArea.wasStuck = stuck;
        }

        onReleased: {
            DeskLayout.clearGuides();
            if (!dragArea.held)
                return;

            const nx = (frame.dragX + frame.width / 2) / frame.fieldWidth;
            const ny = (frame.dragY + frame.height / 2) / frame.fieldHeight;

            DeskLayout.update(frame.entry.key, {
                x: Math.max(0, Math.min(1, nx)),
                y: Math.max(0, Math.min(1, ny))
            });
            dragArea.held = false;
            DeskLayout.save();
            Sfx.fill();
        }

        onCanceled: {
            dragArea.held = false;
            DeskLayout.clearGuides();
        }

        onWheel: (wheel) => {
            frame.grow(wheel.angleDelta.y > 0 ? 0.1 : -0.1);
            Sfx.tick();
        }
    }

    component Grip: MouseArea {
        id: grip

        property bool horiz: false
        property bool vert: false

        property real pressX: 0
        property real pressY: 0
        property real startW: 0
        property real startH: 0

        enabled: frame.editing && frame.selected && frame.stretchy
        visible: enabled
        hoverEnabled: true
        preventStealing: true
        cursorShape: horiz && vert ? Qt.SizeFDiagCursor
                   : horiz ? Qt.SizeHorCursor : Qt.SizeVerCursor

        onPressed: (mouse) => {
            const p = grip.mapToItem(frame.parent, mouse.x, mouse.y);
            grip.pressX = p.x;
            grip.pressY = p.y;
            grip.startW = content.width;
            grip.startH = content.height;
            frame.liveW = grip.startW;
            frame.liveH = grip.startH;
            frame.stretchDX = 0;
            frame.stretchDY = 0;
            frame.stretching = true;
            Sfx.pick();
        }

        onPositionChanged: (mouse) => {
            if (!grip.pressed)
                return;
            const p = grip.mapToItem(frame.parent, mouse.x, mouse.y);
            const s = frame.entry.size;
            const it = widget.item;
            if (grip.horiz) {
                const w = Math.max(it.minWidth || 120, grip.startW + (p.x - grip.pressX) / s);
                frame.liveW = Math.round(w);
                frame.stretchDX = (frame.liveW - grip.startW) * s / 2;
            }
            if (grip.vert) {
                const h = Math.max(it.minHeight || 40, grip.startH + (p.y - grip.pressY) / s);
                frame.liveH = Math.round(h);
                frame.stretchDY = (frame.liveH - grip.startH) * s / 2;
            }
        }

        onReleased: {
            const key = frame.entry.key;
            const changes = {
                w: frame.liveW,
                h: frame.liveH,
                x: Math.max(0, Math.min(1, (frame.x + frame.width / 2) / frame.fieldWidth)),
                y: Math.max(0, Math.min(1, (frame.y + frame.height / 2) / frame.fieldHeight))
            };
            frame.stretchDX = 0;
            frame.stretchDY = 0;
            frame.stretching = false;
            Sfx.fill();
            DeskLayout.update(key, changes);
            DeskLayout.save();
        }

        onCanceled: {
            frame.stretchDX = 0;
            frame.stretchDY = 0;
            frame.stretching = false;
        }

        Rectangle {
            anchors.centerIn: parent
            width: grip.horiz && !grip.vert ? 5 : grip.vert && !grip.horiz ? 36 : 12
            height: grip.vert && !grip.horiz ? 5 : grip.horiz && !grip.vert ? 36 : 12
            radius: Math.min(width, height) / 2
            color: Colors.accent
            opacity: grip.pressed ? 1 : grip.containsMouse ? 0.9 : 0.6
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }
    }

    Grip {
        horiz: true
        x: parent.width + 10 - width / 2
        y: 0
        width: 18
        height: parent.height
    }

    Grip {
        vert: true
        x: 0
        y: parent.height + 10 - height / 2
        width: parent.width
        height: 18
    }

    Grip {
        horiz: true
        vert: true
        x: parent.width + 10 - width / 2
        y: parent.height + 10 - height / 2
        width: 22
        height: 22
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
