import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property string view: "count"

    property int focusId: -1

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    function open(which) {
        if (which)
            root.view = which;
        root.shown = true;
    }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (root.shown)
            root.focusId = -1;
    }

    readonly property string mono: Fonts.mono

    readonly property var focused: {
        const picked = root.focusId >= 0 ? Timers.find(root.focusId) : null;
        return picked || Timers.soonest;
    }

    property int compH: 0
    property int compM: 25
    property int compS: 0
    property string compLabel: ""

    readonly property int composed: root.compH * 3600 + root.compM * 60 + root.compS

    signal labelConsumed()

    function compGet(i) {
        return i === 0 ? root.compH : (i === 1 ? root.compM : root.compS);
    }

    function compSet(i, v) {
        const max = i === 0 ? 23 : 59;
        const wrapped = ((v % (max + 1)) + max + 1) % (max + 1);
        if (i === 0) root.compH = wrapped;
        else if (i === 1) root.compM = wrapped;
        else root.compS = wrapped;
    }

    function compFrom(seconds) {
        root.compH = Math.floor(seconds / 3600);
        root.compM = Math.floor((seconds % 3600) / 60);
        root.compS = seconds % 60;
    }

    function startComposed() {
        if (root.composed <= 0) {
            Sfx.limit();
            return;
        }
        root.focusId = Timers.start(root.composed, root.compLabel);
        root.compLabel = "";
        root.labelConsumed();
        Sfx.fill();
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-timer"
        WlrLayershell.layer: WlrLayer.Overlay

        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Glass {
            id: card

            anchors.centerIn: parent
            width: 812
            height: 560
            radius: Shape.modal
            elevation: 3

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                NumberAnimation {
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.snap
                }
            }

            focus: root.shown

            Keys.onEscapePressed: root.close()
            Keys.onSpacePressed: {
                if (root.view === "watch")
                    Timers.stopwatchToggle();
                else if (Timers.anyRinging)
                    Timers.dismissAll();
                else if (root.focused)
                    Timers.toggle(root.focused.id);
                else
                    root.startComposed();
            }
            Keys.onReturnPressed: root.startComposed()
            Keys.onEnterPressed: root.startComposed()

            Rectangle {
                anchors.fill: parent
                radius: card.radius
                color: "transparent"
                border.width: 2
                border.color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.55)
                antialiasing: true
                opacity: Timers.anyRinging ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Motion.base } }

                SequentialAnimation on border.width {
                    running: Timers.anyRinging
                    loops: Animation.Infinite
                    NumberAnimation { to: 3.5; duration: 620; easing.type: Easing.OutQuad }
                    NumberAnimation { to: 1.5; duration: 620; easing.type: Easing.InQuad }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 18

                Item {
                    width: parent.width
                    height: 30

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.t("timer.title")
                        color: Colors.fg
                        font.family: Fonts.display
                        font.pixelSize: Fonts.titleSize
                    }

                    Segment {
                        anchors.centerIn: parent
                        options: [
                            { value: "count", label: I18n.t("timer.tabCount") },
                            { value: "watch", label: I18n.t("timer.tabWatch") },
                            { value: "prefs", label: I18n.t("timer.tabSound") }
                        ]
                        auto: false
                        current: root.view
                        onPicked: (value) => root.view = value
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Timers.anyRinging
                                ? I18n.t("timer.done")
                                : (Timers.running > 0
                                    ? I18n.count("timer.running", Timers.running)
                                    : I18n.t("timer.idle"))
                            color: Timers.anyRinging ? Colors.bad
                                 : (Timers.running > 0 ? Colors.accent : Colors.fgDim)
                            opacity: Timers.running > 0 || Timers.anyRinging ? 0.9 : 0.45
                            font.family: root.mono
                            font.pixelSize: 11
                        }

                        IconButton {
                            glyph: "󰒲"
                            tip: I18n.t("timer.hush")
                            tint: Colors.warn
                            visible: Timers.anyRinging
                            onActivated: Timers.hush()
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 442
                    spacing: 26
                    visible: root.view === "count"

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 300
                        spacing: 16

                        TimerDial {
                            id: dial

                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 290
                            height: 290

                            readonly property int secs:
                                root.focused ? Timers.left(root.focused) : root.composed

                            progress: root.focused
                                ? Timers.progress(root.focused)
                                : (root.composed > 0 ? 1 : 0)
                            running: root.focused ? root.focused.running : false
                            ringing: root.focused ? root.focused.ringing : false
                            remaining: secs
                            urgentAt: Math.max(3, Prefs.timerTickSec)
                            tint: root.focused ? Colors.accent : Colors.accentAlt

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                RollText {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: Timers.clock(dial.secs)
                                    color: dial.live
                                    family: root.mono
                                    pixelSize: dial.secs >= 3600 ? 38 : 46
                                    weight: Font.Medium
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 200
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: root.focused && root.focused.label !== ""
                                        ? root.focused.label
                                        : (root.focused ? "" : I18n.t("timer.ready"))
                                    color: Colors.fg
                                    opacity: 0.75
                                    font.family: Fonts.display
                                    font.pixelSize: 13
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: !root.focused ? Timers.human(root.composed)
                                        : root.focused.ringing ? I18n.t("timer.done")
                                        : root.focused.running ? Timers.human(root.focused.total)
                                        : I18n.t("timer.paused")
                                    color: Colors.fgDim
                                    opacity: 0.5
                                    font.family: root.mono
                                    font.pixelSize: 10
                                }
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 8

                            IconButton {
                                glyph: "󰐊"
                                tip: I18n.t("timer.start")
                                tint: Colors.accentAlt
                                visible: !root.focused
                                onActivated: root.startComposed()
                            }

                            IconButton {
                                glyph: root.focused && root.focused.running ? "󰏤" : "󰐊"
                                tip: root.focused && root.focused.running
                                    ? I18n.t("timer.pause") : I18n.t("timer.resume")
                                tint: Colors.accent
                                visible: root.focused && !root.focused.ringing
                                onActivated: Timers.toggle(root.focused.id)
                            }

                            IconButton {
                                glyph: "󰅐"
                                tip: "+1" + I18n.t("unit.min")
                                tint: Colors.accentAlt
                                visible: root.focused && !root.focused.ringing
                                onActivated: Timers.nudge(root.focused.id, 60)
                            }

                            IconButton {
                                glyph: "󰑐"
                                tip: I18n.t("timer.restart")
                                tint: Colors.accentAlt
                                visible: root.focused && !root.focused.ringing
                                onActivated: Timers.restart(root.focused.id)
                            }

                            IconButton {
                                glyph: "󰅖"
                                tip: I18n.t("timer.cancel")
                                tint: Colors.bad
                                visible: root.focused && !root.focused.ringing
                                onActivated: {
                                    Timers.cancel(root.focused.id);
                                    root.focusId = -1;
                                }
                            }

                            Rectangle {
                                width: 118
                                height: 36
                                radius: Shape.chip
                                visible: root.focused && root.focused.ringing
                                color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b,
                                               stopTap.pressed ? 0.5 : 0.28)
                                border.width: 1
                                border.color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.6)
                                scale: stopTap.pressed ? 0.96 : 1
                                Behavior on scale { Spring {} }
                                Behavior on color { ColorAnimation { duration: Motion.fast } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰂛  " + I18n.t("timer.dismiss")
                                    color: Colors.fg
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }

                                TapHandler {
                                    id: stopTap
                                    onTapped: {
                                        Timers.dismiss(root.focused.id);
                                        root.focusId = -1;
                                        Sfx.tapAlt();
                                    }
                                }
                            }

                            Rectangle {
                                width: 118
                                height: 36
                                radius: Shape.chip
                                visible: root.focused && root.focused.ringing
                                color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b,
                                               snoozeTap.pressed ? 0.9 : 0.6)
                                border.width: 1
                                border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                      Colors.outline.b, 0.2)
                                scale: snoozeTap.pressed ? 0.96 : 1
                                Behavior on scale { Spring {} }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰒲  +" + Timers.human(Prefs.timerSnoozeSec)
                                    color: Colors.fgDim
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }

                                TapHandler {
                                    id: snoozeTap
                                    onTapped: {
                                        Timers.snooze(root.focused.id, Prefs.timerSnoozeSec);
                                        Sfx.tap();
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        id: rightPane

                        width: parent.width - 326
                        height: parent.height
                        spacing: 12

                        Text {
                            text: I18n.t("timer.presets")
                            color: Colors.fgDim
                            opacity: 0.55
                            font.family: Fonts.display
                            font.pixelSize: Fonts.smallSize
                        }

                        Flow {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: Timers.presets

                                Rectangle {
                                    id: chip

                                    required property int modelData

                                    width: chipText.implicitWidth + 24
                                    height: 30
                                    radius: Shape.chip
                                    antialiasing: true
                                    color: chipHover.hovered
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2)
                                        : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
                                    border.width: 1
                                    border.color: chipHover.hovered
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45)
                                        : "transparent"
                                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                                    Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                                    scale: chipTap.pressed ? 0.94 : 1
                                    Behavior on scale { Spring {} }

                                    HoverHandler { id: chipHover }

                                    Text {
                                        id: chipText
                                        anchors.centerIn: parent
                                        text: Timers.human(chip.modelData)
                                        color: chipHover.hovered ? Colors.accent : Colors.fgDim
                                        font.family: root.mono
                                        font.pixelSize: 11
                                    }

                                    TapHandler {
                                        id: chipTap
                                        acceptedButtons: Qt.LeftButton
                                        onTapped: {
                                            root.compFrom(chip.modelData);
                                            root.focusId = Timers.start(chip.modelData,
                                                                        root.compLabel);
                                            root.compLabel = "";
                                            root.labelConsumed();
                                            Sfx.fill();
                                        }
                                    }

                                    TapHandler {
                                        acceptedButtons: Qt.RightButton
                                        onTapped: {
                                            Timers.removePreset(chip.modelData);
                                            Sfx.toggleOff();
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                width: 34
                                height: 30
                                radius: Shape.chip
                                color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.35)
                                border.width: 1
                                border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                      Colors.outline.b, 0.18)
                                scale: addTap.pressed ? 0.94 : 1
                                Behavior on scale { Spring {} }

                                Text {
                                    anchors.centerIn: parent
                                    text: "+"
                                    color: Colors.fgDim
                                    opacity: 0.7
                                    font.family: root.mono
                                    font.pixelSize: 13
                                }

                                TapHandler {
                                    id: addTap
                                    onTapped: {
                                        if (Timers.addPreset(root.composed))
                                            Sfx.tapAlt();
                                        else
                                            Sfx.limit();
                                    }
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 108
                            radius: Shape.field
                            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.35)

                            Sheen {
                                anchors.fill: parent
                                radius: parent.radius
                                edgeOpacity: 0.12
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 4

                                Repeater {
                                    model: [
                                        { index: 0, unit: I18n.t("unit.hourShort") },
                                        { index: 1, unit: I18n.t("unit.minShort") },
                                        { index: 2, unit: I18n.t("unit.secShort") }
                                    ]

                                    Row {
                                        id: unitRow

                                        required property var modelData

                                        spacing: 4

                                        Item {
                                            width: 76
                                            height: 92

                                            Column {
                                                anchors.centerIn: parent
                                                spacing: 2

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: "󰅃"
                                                    color: upTap.pressed ? Colors.accent : Colors.fgDim
                                                    opacity: wheelHover.hovered ? 0.9 : 0.3
                                                    font.family: root.mono
                                                    font.pixelSize: 12
                                                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                                                    TapHandler {
                                                        id: upTap
                                                        onTapped: {
                                                            root.compSet(unitRow.modelData.index,
                                                                root.compGet(unitRow.modelData.index) + 1);
                                                            Sfx.tick();
                                                        }
                                                    }
                                                }

                                                RollText {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: String(root.compGet(unitRow.modelData.index))
                                                        .padStart(2, "0")
                                                    color: root.compGet(unitRow.modelData.index) > 0
                                                        ? Colors.fg : Qt.rgba(Colors.fgDim.r,
                                                            Colors.fgDim.g, Colors.fgDim.b, 0.45)
                                                    family: root.mono
                                                    pixelSize: 30
                                                    weight: Font.Medium
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: "󰅀"
                                                    color: downTap.pressed ? Colors.accent : Colors.fgDim
                                                    opacity: wheelHover.hovered ? 0.9 : 0.3
                                                    font.family: root.mono
                                                    font.pixelSize: 12
                                                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                                                    TapHandler {
                                                        id: downTap
                                                        onTapped: {
                                                            root.compSet(unitRow.modelData.index,
                                                                root.compGet(unitRow.modelData.index) - 1);
                                                            Sfx.tick();
                                                        }
                                                    }
                                                }
                                            }

                                            Text {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.bottom: parent.bottom
                                                text: unitRow.modelData.unit
                                                color: Colors.fgDim
                                                opacity: 0.4
                                                font.family: root.mono
                                                font.pixelSize: 9
                                            }

                                            HoverHandler { id: wheelHover }

                                            WheelHandler {
                                                acceptedDevices: PointerDevice.Mouse
                                                    | PointerDevice.TouchPad
                                                onWheel: (event) => {
                                                    const step = event.angleDelta.y > 0 ? 1 : -1;
                                                    root.compSet(unitRow.modelData.index,
                                                        root.compGet(unitRow.modelData.index) + step);
                                                    Sfx.tick();
                                                }
                                            }

                                            DragHandler {
                                                id: wheelDrag

                                                property real anchorValue: 0
                                                property real anchorY: 0

                                                target: null
                                                xAxis.enabled: false
                                                yAxis.enabled: true

                                                onActiveChanged: {
                                                    if (wheelDrag.active) {
                                                        wheelDrag.anchorValue =
                                                            root.compGet(unitRow.modelData.index);
                                                        wheelDrag.anchorY = wheelDrag.centroid.position.y;
                                                    } else {
                                                        Sfx.tap();
                                                    }
                                                }

                                                onCentroidChanged: {
                                                    if (!wheelDrag.active)
                                                        return;
                                                    const moved = wheelDrag.anchorY
                                                        - wheelDrag.centroid.position.y;
                                                    const next = wheelDrag.anchorValue
                                                        + Math.round(moved / 12);
                                                    if (next === root.compGet(unitRow.modelData.index))
                                                        return;
                                                    root.compSet(unitRow.modelData.index, next);
                                                    Sfx.tick();
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: unitRow.modelData.index < 2
                                            text: ":"
                                            color: Colors.fgDim
                                            opacity: 0.3
                                            font.family: root.mono
                                            font.pixelSize: 24
                                        }
                                    }
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 8

                            Field {
                                id: nameField

                                width: parent.width - 138
                                height: 40
                                placeholder: I18n.t("timer.label")
                                onTextChanged: root.compLabel = nameField.text
                                onAccepted: root.startComposed()

                                Connections {
                                    target: root
                                    function onLabelConsumed() { nameField.clear(); }
                                }
                            }

                            Rectangle {
                                width: 130
                                height: 40
                                radius: Shape.chip
                                antialiasing: true
                                color: root.composed > 0
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b,
                                              goTap.pressed ? 0.55 : (goHover.hovered ? 0.42 : 0.3))
                                    : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.4)
                                border.width: 1
                                border.color: root.composed > 0
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.6)
                                    : "transparent"
                                Behavior on color { ColorAnimation { duration: Motion.fast } }

                                scale: goTap.pressed ? 0.96 : 1
                                Behavior on scale { Spring {} }

                                HoverHandler { id: goHover }

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰔟  " + I18n.t("timer.start")
                                    color: root.composed > 0 ? Colors.fg
                                        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.4)
                                    font.family: root.mono
                                    font.pixelSize: 12
                                }

                                TapHandler {
                                    id: goTap
                                    onTapped: root.startComposed()
                                }
                            }
                        }

                        Item {
                            width: parent.width
                            height: Math.max(96, rightPane.height - y)

                            Text {
                                id: listHead
                                text: I18n.t("timer.active")
                                color: Colors.fgDim
                                opacity: 0.55
                                font.family: Fonts.display
                                font.pixelSize: Fonts.smallSize
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: Timers.items.length === 0
                                text: I18n.t("timer.empty")
                                color: Colors.fgDim
                                opacity: 0.3
                                font.family: root.mono
                                font.pixelSize: 11
                            }

                            ListView {
                                anchors.fill: parent
                                anchors.topMargin: 22
                                clip: true
                                spacing: 6
                                model: Timers.items

                                delegate: Rectangle {
                                    id: row

                                    required property var modelData

                                    readonly property bool isFocus:
                                        root.focused && root.focused.id === modelData.id

                                    width: ListView.view.width
                                    height: 40
                                    radius: Shape.chip
                                    color: row.isFocus
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.12)
                                        : (rowHover.hovered
                                            ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.6)
                                            : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.3))
                                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                                    HoverHandler { id: rowHover }

                                    Rectangle {
                                        anchors.left: parent.left
                                        anchors.top: parent.top
                                        anchors.bottom: parent.bottom
                                        width: parent.width * Timers.progress(row.modelData)
                                        radius: parent.radius
                                        color: row.modelData.ringing
                                            ? Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.28)
                                            : Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                      Colors.accent.b, row.modelData.running ? 0.18 : 0.08)
                                        Behavior on width {
                                            NumberAnimation { duration: 950; easing.type: Easing.Linear }
                                        }
                                    }

                                    Row {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12
                                        anchors.rightMargin: 8
                                        spacing: 10

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: row.modelData.ringing ? "󰂚"
                                                : (row.modelData.running ? "󰔟" : "󰏤")
                                            color: row.modelData.ringing ? Colors.bad
                                                : (row.modelData.running ? Colors.accent : Colors.fgDim)
                                            font.family: root.mono
                                            font.pixelSize: 13
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            width: parent.width - 210
                                            elide: Text.ElideRight
                                            text: row.modelData.label !== ""
                                                ? row.modelData.label
                                                : Timers.human(row.modelData.total)
                                            color: Colors.fg
                                            opacity: 0.85
                                            font.family: Fonts.display
                                            font.pixelSize: 12
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Timers.clock(Timers.left(row.modelData))
                                            color: row.modelData.ringing ? Colors.bad : Colors.fg
                                            font.family: root.mono
                                            font.pixelSize: 13
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: row.modelData.running ? "󰏤" : "󰐊"
                                            color: pauseHover.hovered ? Colors.accent : Colors.fgDim
                                            opacity: pauseHover.hovered ? 1 : 0.5
                                            font.family: root.mono
                                            font.pixelSize: 12

                                            HoverHandler { id: pauseHover }
                                            TapHandler {
                                                onTapped: {
                                                    Timers.toggle(row.modelData.id);
                                                    Sfx.icon();
                                                }
                                            }
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰅖"
                                            color: killHover.hovered ? Colors.bad : Colors.fgDim
                                            opacity: killHover.hovered ? 1 : 0.5
                                            font.family: root.mono
                                            font.pixelSize: 12

                                            HoverHandler { id: killHover }
                                            TapHandler {
                                                onTapped: {
                                                    if (root.focusId === row.modelData.id)
                                                        root.focusId = -1;
                                                    Timers.cancel(row.modelData.id);
                                                    Sfx.toggleOff();
                                                }
                                            }
                                        }
                                    }

                                    TapHandler {
                                        onTapped: {
                                            root.focusId = row.modelData.id;
                                            Sfx.pick();
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 442
                    spacing: 26
                    visible: root.view === "prefs"

                    Column {
                        width: 380
                        spacing: 14

                        Text {
                            text: I18n.t("set.timerSound")
                            color: Colors.fgDim
                            opacity: 0.55
                            font.family: Fonts.display
                            font.pixelSize: Fonts.smallSize
                        }

                        Flow {
                            width: parent.width
                            spacing: 6

                            Repeater {
                                model: Sfx.alarmNames

                                Rectangle {
                                    id: voice

                                    required property string modelData

                                    readonly property bool active: Prefs.timerSound === modelData

                                    width: voiceText.implicitWidth + 26
                                    height: 32
                                    radius: Shape.chip
                                    antialiasing: true
                                    color: voice.active
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.22)
                                        : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.45)
                                    border.width: 1
                                    border.color: voice.active
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.5)
                                        : "transparent"
                                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                                    scale: voiceTap.pressed ? 0.95 : 1
                                    Behavior on scale { Spring {} }

                                    Text {
                                        id: voiceText
                                        anchors.centerIn: parent
                                        text: voice.modelData === "none"
                                            ? I18n.t("set.timerNone")
                                            : I18n.t("timer.voice." + voice.modelData)
                                        color: voice.active ? Colors.accent : Colors.fgDim
                                        font.family: root.mono
                                        font.pixelSize: 11
                                    }

                                    TapHandler {
                                        id: voiceTap
                                        onTapped: {
                                            Prefs.set("timerSound", voice.modelData);
                                            if (voice.modelData === "none")
                                                Sfx.toggleOff();
                                            else
                                                Sfx.timerPreview(voice.modelData);
                                        }
                                    }
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Item {
                                width: parent.width
                                height: 16

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: I18n.t("set.timerVolume")
                                    color: Colors.fg
                                    opacity: 0.8
                                    font.family: Fonts.display
                                    font.pixelSize: 12
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Math.round(Prefs.timerVolume * 100) + "%"
                                    color: Colors.accent
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }
                            }

                            Slider {
                                width: parent.width
                                value: Prefs.timerVolume
                                tint: Colors.accent
                                onMoved: (value) => Prefs.set("timerVolume", value)
                                onReleased: Sfx.timerPreview(Prefs.timerSound)
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: I18n.t("set.timerRing")
                                color: Colors.fg
                                opacity: 0.8
                                font.family: Fonts.display
                                font.pixelSize: 12
                            }

                            Segment {
                                auto: false
                                current: String(Prefs.timerRingSec)
                                options: [
                                    { value: "30",  label: "30" + I18n.t("unit.sec") },
                                    { value: "120", label: "2" + I18n.t("unit.min") },
                                    { value: "300", label: "5" + I18n.t("unit.min") },
                                    { value: "0",   label: "∞" }
                                ]
                                onPicked: (value) => Prefs.set("timerRingSec", parseInt(value, 10))
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: I18n.t("timer.snooze")
                                color: Colors.fg
                                opacity: 0.8
                                font.family: Fonts.display
                                font.pixelSize: 12
                            }

                            Segment {
                                auto: false
                                current: String(Prefs.timerSnoozeSec)
                                tint: Colors.accentAlt
                                options: [
                                    { value: "60",  label: "1" + I18n.t("unit.min") },
                                    { value: "300", label: "5" + I18n.t("unit.min") },
                                    { value: "600", label: "10" + I18n.t("unit.min") }
                                ]
                                onPicked: (value) => Prefs.set("timerSnoozeSec", parseInt(value, 10))
                            }
                        }
                    }

                    Column {
                        width: parent.width - 406
                        spacing: 10

                        Repeater {
                            model: [
                                { key: "timerLoop",    title: I18n.t("set.timerLoop") },
                                { key: "timerTicking", title: I18n.t("set.timerTicking") },
                                { key: "timerHalfway", title: I18n.t("set.timerHalfway") },
                                { key: "timerNotify",  title: I18n.t("set.timerNotify") }
                            ]

                            Item {
                                id: prefRow

                                required property var modelData

                                width: parent.width
                                height: 42

                                Rectangle {
                                    anchors.fill: parent
                                    anchors.margins: -6
                                    radius: Shape.chip
                                    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                                   Colors.bgAlt.b, prefHover.hovered ? 0.4 : 0)
                                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                                }

                                HoverHandler { id: prefHover }

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 70
                                    elide: Text.ElideRight
                                    text: prefRow.modelData.title
                                    color: Colors.fg
                                    opacity: 0.85
                                    font.family: Fonts.display
                                    font.pixelSize: 12
                                }

                                Switch {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    checked: Prefs[prefRow.modelData.key]
                                    onToggled: (value) => Prefs.set(prefRow.modelData.key, value)
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8
                            opacity: Prefs.timerTicking ? 1 : 0.35
                            Behavior on opacity { NumberAnimation { duration: Motion.base } }

                            Text {
                                text: I18n.t("timer.tickWindow")
                                color: Colors.fg
                                opacity: 0.8
                                font.family: Fonts.display
                                font.pixelSize: 12
                            }

                            Segment {
                                auto: false
                                current: String(Prefs.timerTickSec)
                                tint: Colors.accentAlt
                                options: [
                                    { value: "3",  label: "3" + I18n.t("unit.sec") },
                                    { value: "5",  label: "5" + I18n.t("unit.sec") },
                                    { value: "10", label: "10" + I18n.t("unit.sec") },
                                    { value: "30", label: "30" + I18n.t("unit.sec") }
                                ]
                                onPicked: (value) => Prefs.set("timerTickSec", parseInt(value, 10))
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Text {
                                text: I18n.t("set.timerCommand")
                                color: Colors.fg
                                opacity: 0.8
                                font.family: Fonts.display
                                font.pixelSize: 12
                            }

                            Text {
                                text: I18n.t("set.timerCommandHint")
                                color: Colors.fgDim
                                opacity: 0.45
                                font.family: root.mono
                                font.pixelSize: 10
                            }

                            Field {
                                id: cmdField

                                width: parent.width
                                height: 40
                                placeholder: "notify-send done"
                                tint: Colors.accentAlt
                                onAccepted: (value) => {
                                    Prefs.set("timerCommand", value);
                                    Sfx.tapAlt();
                                }

                                onFocusedChanged: if (!cmdField.focused)
                                    Prefs.set("timerCommand", cmdField.text)

                                Component.onCompleted: cmdField.text = Prefs.timerCommand

                                Connections {
                                    target: Prefs
                                    function onLoadedChanged() {
                                        if (Prefs.loaded && !cmdField.focused)
                                            cmdField.text = Prefs.timerCommand;
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width
                    height: 442
                    spacing: 26
                    visible: root.view === "watch"

                    Column {
                        width: 440
                        spacing: 22

                        Item {
                            width: parent.width
                            height: 240

                            TimerDial {
                                anchors.centerIn: parent
                                width: 240
                                height: 240
                                marks: 60
                                tint: Colors.accentAlt
                                running: Timers.stopwatchRunning
                                progress: (Timers.stopwatchMs % 60000) / 60000

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 4

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Timers.stopwatchText(Timers.stopwatchMs)
                                        color: Timers.stopwatchRunning ? Colors.accentAlt : Colors.fg
                                        font.family: root.mono
                                        font.pixelSize: 34
                                        font.weight: Font.Medium
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: Timers.laps.length > 0
                                            ? I18n.count("timer.laps", Timers.laps.length)
                                            : I18n.t("timer.noLaps")
                                        color: Colors.fgDim
                                        opacity: 0.5
                                        font.family: root.mono
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 10

                            Rectangle {
                                width: 140
                                height: 42
                                radius: Shape.chip
                                color: Timers.stopwatchRunning
                                    ? Qt.rgba(Colors.warn.r, Colors.warn.g, Colors.warn.b, 0.3)
                                    : Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                              Colors.accentAlt.b, 0.3)
                                border.width: 1
                                border.color: Timers.stopwatchRunning
                                    ? Qt.rgba(Colors.warn.r, Colors.warn.g, Colors.warn.b, 0.55)
                                    : Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                              Colors.accentAlt.b, 0.55)
                                Behavior on color { ColorAnimation { duration: Motion.fast } }

                                scale: swTap.pressed ? 0.96 : 1
                                Behavior on scale { Spring {} }

                                Text {
                                    anchors.centerIn: parent
                                    text: Timers.stopwatchRunning
                                        ? "󰏤  " + I18n.t("timer.stop")
                                        : "󰐊  " + I18n.t("timer.start")
                                    color: Colors.fg
                                    font.family: root.mono
                                    font.pixelSize: 12
                                }

                                TapHandler {
                                    id: swTap
                                    onTapped: {
                                        Timers.stopwatchToggle();
                                        Sfx.fill();
                                    }
                                }
                            }

                            IconButton {
                                glyph: "󰓾"
                                tip: I18n.t("timer.lap")
                                tint: Colors.accent
                                width: 42
                                height: 42
                                onActivated: {
                                    if (Timers.stopwatchMs > 0)
                                        Timers.lap();
                                }
                            }

                            IconButton {
                                glyph: "󰑐"
                                tip: I18n.t("timer.reset")
                                tint: Colors.bad
                                width: 42
                                height: 42
                                onActivated: Timers.stopwatchReset()
                            }
                        }
                    }

                    Item {
                        id: lapPane

                        width: parent.width - 466
                        height: parent.height

                        readonly property real slowest: {
                            let m = 1;
                            for (const l of Timers.laps)
                                m = Math.max(m, l.split);
                            return m;
                        }

                        Text {
                            id: lapHead
                            text: I18n.t("timer.laps.title")
                            color: Colors.fgDim
                            opacity: 0.55
                            font.family: Fonts.display
                            font.pixelSize: Fonts.smallSize
                        }

                        ListView {
                            anchors.fill: parent
                            anchors.topMargin: 24
                            clip: true
                            spacing: 4
                            model: Timers.laps

                            delegate: Item {
                                id: lap

                                required property var modelData
                                required property int index

                                width: ListView.view.width
                                height: 32

                                Rectangle {
                                    anchors.fill: parent
                                    radius: Shape.chip
                                    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                                   Colors.bgAlt.b, 0.28)
                                }

                                Rectangle {
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width * (lap.modelData.split
                                        / lapPane.slowest)
                                    radius: Shape.chip
                                    color: Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                                   Colors.accentAlt.b, lap.index === 0 ? 0.28 : 0.14)
                                }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 26
                                        text: "#" + lap.modelData.index
                                        color: Colors.fgDim
                                        opacity: 0.6
                                        font.family: root.mono
                                        font.pixelSize: 10
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 130
                                        text: Timers.stopwatchText(lap.modelData.split)
                                        color: Colors.fg
                                        opacity: 0.9
                                        font.family: root.mono
                                        font.pixelSize: 12
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: Timers.stopwatchText(lap.modelData.at)
                                        color: Colors.fgDim
                                        opacity: 0.5
                                        font.family: root.mono
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
