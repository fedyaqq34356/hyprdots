import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: {
        Sfx.panel(root.shown);
        root.shown ? Weather.hold() : Weather.release();
        if (root.shown) {
            input.text = "";
            root.sel = root.today;
            root.view = root.monthOf(root.today);
            input.forceActiveFocus();
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property date today: new Date(clock.date.getFullYear(), clock.date.getMonth(), clock.date.getDate())

    property date sel: new Date()
    property date view: root.monthOf(new Date())

    function monthOf(d) { return new Date(d.getFullYear(), d.getMonth(), 1); }
    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
    }
    function addDays(d, n) { return new Date(d.getFullYear(), d.getMonth(), d.getDate() + n); }

    function select(d) {
        const was = root.monthOf(root.view);
        root.sel = d;
        const now = root.monthOf(d);
        if (now.getTime() !== was.getTime())
            root.flipTo(now, now > was ? 1 : -1);
        else
            Sfx.tick();
    }

    function stepMonth(dir) {
        const d = root.sel;
        const last = new Date(d.getFullYear(), d.getMonth() + dir + 1, 0).getDate();
        root.select(new Date(d.getFullYear(), d.getMonth() + dir, Math.min(d.getDate(), last)));
    }

    property int dir: 1
    function flipTo(month, dir) {
        root.dir = dir;
        root.pendingView = month;
        drip.lean(dir);
        Sfx.pick();
        swap.restart();
    }
    property date pendingView: new Date()

    readonly property var months: I18n.list("cal.months")
    readonly property var monthsGen: I18n.list("cal.monthsGen")
    readonly property var weekdays: I18n.list("cal.weekdays")
    readonly property var weekdaysFull: I18n.list("cal.weekdaysFull")

    function relDay(d) {
        const n = Math.round((d.getTime() - root.today.getTime()) / 86400000);
        if (n === 0) return I18n.t("cal.today");
        if (n === 1) return I18n.t("cal.tomorrow");
        if (n === -1) return I18n.t("cal.yesterday");
        return (n > 0 ? I18n.t("cal.inDays") : I18n.t("cal.daysAgo")).replace("{n}", Math.abs(n));
    }

    readonly property int lead: (root.view.getDay() + 6) % 7
    readonly property date gridStart: new Date(root.view.getFullYear(), root.view.getMonth(), 1 - root.lead)

    function cellOf(d) {
        const i = Math.round((new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
                              - root.gridStart.getTime()) / 86400000);
        return i >= 0 && i < 42 ? i : -1;
    }

    property var activity: ({})
    property int activityMax: 1

    FileView {
        id: activityFile
        path: Quickshell.env("HOME") + "/.cache/git-activity.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            let parsed;
            try {
                parsed = JSON.parse(activityFile.text());
            } catch (e) {
                return;
            }
            const days = parsed.days || {};
            let peak = 1;
            for (const key in days)
                peak = Math.max(peak, days[key]);
            root.activity = days;
            root.activityMax = peak;
        }
    }

    Process { id: activityScan }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            activityScan.command = [
                Quickshell.env("HOME") + "/.config/hypr/scripts/tools/git-activity.py",
                "--quiet"
            ];
            activityScan.running = true;
        }
    }

    function commitsOn(d) {
        const n = root.activity[Qt.formatDate(d, "yyyy-MM-dd")];
        return n === undefined ? 0 : n;
    }

    readonly property var sky: {
        if (!Weather.ready)
            return null;
        const key = Qt.formatDate(root.sel, "yyyy-MM-dd");
        const f = (Weather.forecast || []).find(d => d.date === key);
        if (root.sameDay(root.sel, root.today))
            return { code: Weather.code, temp: Math.round(Weather.temp),
                     min: f ? f.min : NaN, max: f ? f.max : NaN, day: Weather.day };
        if (!f)
            return null;
        return { code: f.code, temp: f.max, min: f.min, max: f.max, day: true };
    }

    readonly property color skyHue: {
        const s = root.sky;
        if (!s)
            return Colors.accent;
        const c = s.code;
        if (c >= 386 && c <= 395) return "#9b7bff";
        if (c === 179 || c === 182 || c === 185 || c === 227 || c === 230
            || (c >= 317 && c <= 377 && c !== 353 && c !== 356 && c !== 359))
            return "#bfe4ff";
        if (c >= 176) return "#5d9bff";
        if (c === 113) return s.day ? "#ffb15c" : "#8f9cff";
        if (c === 116) return s.day ? "#ffc98a" : "#8f9cff";
        return "#a9b8cc";
    }

    readonly property var dayItems: {
        Reminders.items;
        return Reminders.onDay(root.sel);
    }

    readonly property var preview: input.text.trim() !== "" ? Reminders.parse(input.text, root.sel) : null

    function addReminder() {
        const r = Reminders.add(input.text, root.sel);
        if (!r)
            return;
        input.text = "";
        Sfx.isleOk();
        const d = new Date(r.at);
        if (!root.sameDay(d, root.sel))
            root.select(new Date(d.getFullYear(), d.getMonth(), d.getDate()));
    }

    Connections {
        target: IslandBus
        function onCalendarAt(ms) {
            const d = new Date(ms);
            if (!root.shown)
                root.shown = true;
            Qt.callLater(() => root.select(new Date(d.getFullYear(), d.getMonth(), d.getDate())));
        }
    }

    IpcHandler {
        target: "calendar"
        function toggle(): void { root.toggle(); }
        function day(n: int): void { root.select(root.addDays(root.sel, n)); }
        function month(n: int): void { root.stepMonth(n); }
        function today(): void { root.select(root.today); }
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-calendar"
        id: win

        screen: Focus.screen
        visible: root.shown || drip.living
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: root.shown ? 0.22 : 0
            Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        IsleDrip {
            id: drip
            anchors.fill: parent
            open: root.shown
            cardW: 820
            cardH: 470
            radius: 34
            glow: root.skyHue

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                property real acc: 0
                onWheel: (ev) => {
                    acc += ev.angleDelta.y || -ev.angleDelta.x;
                    if (Math.abs(acc) < 120 || wheelRest.running)
                        return;
                    root.stepMonth(acc < 0 ? 1 : -1);
                    acc = 0;
                    wheelRest.restart();
                }
            }
            Timer { id: wheelRest; interval: 260 }

            PhaseHold { active: root.shown; slow: true }

            MouseArea { anchors.fill: parent }

            Item {
                id: hero
                x: 34
                y: 30
                width: 300
                height: parent.height - 60

                Text {
                    id: weekday
                    text: (root.weekdaysFull[root.sel.getDay()] || "").toUpperCase()
                    color: Qt.lighter(Colors.accent, 1.2)
                    font.family: Fonts.display
                    font.features: { "tnum": 1 }
                    font.pixelSize: Fonts.medium
                    font.weight: Font.DemiBold
                    font.letterSpacing: 2.4
                }

                RectangularShadow {
                    x: -10
                    y: dayNum.y + 20
                    width: 170
                    height: 90
                    radius: 45
                    blur: 70
                    color: Colors.alpha(Colors.accent, 0.20 + 0.06 * (root.shown ? Math.sin(Phase.ts * 0.5) : 0))
                }

                RollText {
                    id: dayNum
                    y: weekday.height + 2
                    x: -4
                    text: String(root.sel.getDate())
                    color: "white"
                    family: Fonts.display
                    pixelSize: 104
                    weight: Font.DemiBold
                    rollDuration: 420
                    overshoot: 0.6
                }

                Item {
                    id: skyBox
                    x: dayNum.x + dayNum.width + 22
                    y: dayNum.y + 22
                    width: 120
                    height: 70
                    opacity: root.sky ? 1 : 0
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutCubic } }

                    RectangularShadow {
                        x: -6
                        y: 2
                        width: 44
                        height: 44
                        radius: 22
                        blur: 30
                        color: Colors.alpha(root.skyHue, 0.55)
                    }

                    Text {
                        id: skyGlyph
                        text: root.sky ? Weather.glyphFor(root.sky.code, root.sky.day) : ""
                        color: Qt.lighter(root.skyHue, 1.15)
                        font.family: Fonts.glyph
                        font.pixelSize: Fonts.huge
                        y: root.shown ? 3 * Math.sin(Phase.ts * 0.9) : 0
                    }

                    Column {
                        anchors.left: skyGlyph.right
                        anchors.leftMargin: 10
                        y: 0
                        spacing: 0
                        Text {
                            text: root.sky ? root.sky.temp + "°" : ""
                            color: "white"
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.bigger
                            font.weight: Font.DemiBold
                        }
                        Text {
                            visible: root.sky !== null && !isNaN(root.sky.min)
                            text: root.sky ? root.sky.min + "° · " + root.sky.max + "°" : ""
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.text
                        }
                    }
                }

                Row {
                    id: monthLine
                    y: dayNum.y + dayNum.height - 6
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.monthsGen[root.sel.getMonth()] + " " + root.sel.getFullYear()
                        color: Qt.rgba(1, 1, 1, 0.62)
                        font.family: Fonts.display
                        font.features: { "tnum": 1 }
                        font.pixelSize: Fonts.large
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 22
                        width: relText.implicitWidth + 18
                        radius: 11
                        color: Colors.alpha(Colors.accent, 0.16)
                        border.width: 1
                        border.color: Colors.alpha(Colors.accent, 0.30)
                        Text {
                            id: relText
                            anchors.centerIn: parent
                            text: root.relDay(root.sel)
                            color: Qt.lighter(Colors.accent, 1.3)
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.small
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Column {
                    id: dayList
                    y: monthLine.y + 44
                    width: parent.width
                    spacing: 6

                    Text {
                        visible: root.dayItems.length === 0
                        text: I18n.t("cal.empty")
                        color: Qt.rgba(1, 1, 1, 0.28)
                        font.family: Fonts.display
                        font.features: { "tnum": 1 }
                        font.pixelSize: Fonts.medium
                        opacity: 0
                        Component.onCompleted: opacity = 1
                        Behavior on opacity { NumberAnimation { duration: 500 } }
                    }

                    Repeater {
                        model: root.dayItems.slice(0, 4)

                        Item {
                            id: row
                            required property var modelData
                            required property int index
                            width: dayList.width
                            height: 36

                            opacity: 0
                            transform: Translate { id: rowIn; y: 8 }
                            Component.onCompleted: rowAppear.start()
                            ParallelAnimation {
                                id: rowAppear
                                SequentialAnimation {
                                    PauseAnimation { duration: 60 * row.index }
                                    NumberAnimation { target: row; property: "opacity"; to: 1; duration: 420; easing.type: Easing.OutCubic }
                                }
                                SequentialAnimation {
                                    PauseAnimation { duration: 60 * row.index }
                                    NumberAnimation { target: rowIn; property: "y"; to: 0; duration: 520; easing.type: Easing.OutCubic }
                                }
                            }

                            readonly property bool past: row.modelData.at < Date.now()
                            readonly property bool done: row.modelData.done

                            Rectangle {
                                anchors.fill: parent
                                radius: 12
                                color: rowHover.hovered ? Qt.rgba(1, 1, 1, 0.07) : Qt.rgba(1, 1, 1, 0.035)
                                Behavior on color { ColorAnimation { duration: 180 } }
                            }

                            Rectangle {
                                id: tick
                                x: 10
                                anchors.verticalCenter: parent.verticalCenter
                                width: 16
                                height: 16
                                radius: 8
                                color: row.done ? Colors.alpha(Colors.good, 0.85) : "transparent"
                                border.width: 1.5
                                border.color: row.done ? Colors.good : Colors.alpha(Colors.warn, 0.8)
                                Behavior on color { ColorAnimation { duration: 220 } }
                                Text {
                                    anchors.centerIn: parent
                                    visible: row.done
                                    text: "󰄬"
                                    color: "black"
                                    font.family: Fonts.glyph
                                    font.pixelSize: Fonts.small
                                }
                            }

                            Text {
                                id: when
                                x: 36
                                anchors.verticalCenter: parent.verticalCenter
                                text: Qt.formatDateTime(new Date(row.modelData.at), "HH:mm")
                                color: row.done ? Qt.rgba(1, 1, 1, 0.3) : Colors.warn
                                font.family: Fonts.mono
                                font.features: { "tnum": 1 }
                                font.pixelSize: Fonts.text
                                font.weight: Font.Bold
                            }

                            Text {
                                anchors.left: when.right
                                anchors.leftMargin: 10
                                anchors.right: del.left
                                anchors.rightMargin: 6
                                anchors.verticalCenter: parent.verticalCenter
                                text: row.modelData.title
                                color: row.done ? Qt.rgba(1, 1, 1, 0.35) : "white"
                                font.family: Fonts.display
                                font.features: { "tnum": 1 }
                                font.pixelSize: Fonts.medium
                                font.strikeout: row.done
                                elide: Text.ElideRight
                            }

                            Text {
                                id: del
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰅖"
                                color: Qt.rgba(1, 1, 1, delHover.hovered ? 0.8 : 0.35)
                                opacity: rowHover.hovered ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                                font.family: Fonts.glyph
                                font.pixelSize: Fonts.medium
                                HoverHandler { id: delHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: { Reminders.remove(row.modelData.id); Sfx.tapAlt(); } }
                            }

                            HoverHandler { id: rowHover }
                            TapHandler {
                                onTapped: (pt) => {
                                    if (pt.position.x < del.x - 4) {
                                        Reminders.toggle(row.modelData.id);
                                        Sfx.flip(!row.done);
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        visible: root.dayItems.length > 4
                        text: I18n.t("cal.more").replace("{n}", root.dayItems.length - 4)
                        color: Qt.rgba(1, 1, 1, 0.4)
                        font.family: Fonts.display
                        font.features: { "tnum": 1 }
                        font.pixelSize: Fonts.text
                        leftPadding: 10
                    }
                }

                Rectangle {
                    id: field
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 46
                    radius: 23
                    color: Qt.rgba(1, 1, 1, input.activeFocus ? 0.075 : 0.05)
                    border.width: 1
                    border.color: input.text !== "" ? Colors.alpha(Colors.warn, 0.45) : Qt.rgba(1, 1, 1, 0.08)
                    Behavior on border.color { ColorAnimation { duration: 260 } }

                    Text {
                        id: bellGlyph
                        x: 16
                        anchors.verticalCenter: parent.verticalCenter
                        text: "󰂚"
                        color: input.text !== "" ? Colors.warn : Qt.rgba(1, 1, 1, 0.4)
                        font.family: Fonts.glyph
                        font.pixelSize: Fonts.medium
                        Behavior on color { ColorAnimation { duration: 260 } }
                    }

                    TextInput {
                        id: input
                        anchors.left: bellGlyph.right
                        anchors.leftMargin: 10
                        anchors.right: chip.left
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: "white"
                        font.family: Fonts.display
                        font.features: { "tnum": 1 }
                        font.pixelSize: Fonts.medium
                        clip: true
                        selectByMouse: true
                        selectionColor: Colors.alpha(Colors.warn, 0.35)
                        focus: true

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: input.text === ""
                            text: I18n.t("cal.remindHint")
                            color: Qt.rgba(1, 1, 1, 0.32)
                            font: input.font
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Keys.onReturnPressed: root.addReminder()
                        Keys.onEnterPressed: root.addReminder()
                        Keys.onPressed: (e) => {
                            const empty = input.text === "";
                            const shift = e.modifiers & Qt.ShiftModifier;
                            if (e.key === Qt.Key_Escape) {
                                if (empty) root.close(); else input.text = "";
                            } else if (e.key === Qt.Key_PageUp || (shift && e.key === Qt.Key_Left)) {
                                root.stepMonth(-1);
                            } else if (e.key === Qt.Key_PageDown || (shift && e.key === Qt.Key_Right)) {
                                root.stepMonth(1);
                            } else if (empty && e.key === Qt.Key_Left) {
                                root.select(root.addDays(root.sel, -1));
                            } else if (empty && e.key === Qt.Key_Right) {
                                root.select(root.addDays(root.sel, 1));
                            } else if (e.key === Qt.Key_Up) {
                                root.select(root.addDays(root.sel, -7));
                            } else if (e.key === Qt.Key_Down) {
                                root.select(root.addDays(root.sel, 7));
                            } else if (empty && e.key === Qt.Key_Home) {
                                root.select(root.today);
                            } else {
                                return;
                            }
                            e.accepted = true;
                        }
                    }

                    Rectangle {
                        id: chip
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        height: 30
                        radius: 15
                        width: root.preview ? chipText.implicitWidth + 22 : 0
                        opacity: root.preview ? 1 : 0
                        color: Colors.alpha(Colors.warn, 0.16)
                        Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                        clip: true

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: root.preview
                                ? root.relDay(new Date(new Date(root.preview.at).setHours(0, 0, 0, 0)))
                                  + " · " + Qt.formatDateTime(new Date(root.preview.at), "HH:mm")
                                : ""
                            color: Qt.lighter(Colors.warn, 1.2)
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.text
                            font.weight: Font.DemiBold
                        }
                    }
                }
            }

            Item {
                id: monthSide
                readonly property real cw: 60
                readonly property real ch: 50
                width: monthSide.cw * 7
                height: parent.height - 60
                x: parent.width - width - 30
                y: 30

                Item {
                    id: head
                    width: parent.width
                    height: 34

                    Row {
                        id: title
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10
                        opacity: gridFace.opacity
                        transform: Translate { x: gridFace.shift * 0.5 }

                        Text {
                            text: root.months[root.view.getMonth()] || ""
                            color: "white"
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.big
                            font.weight: Font.DemiBold
                        }
                        Text {
                            text: root.view.getFullYear()
                            color: Qt.rgba(1, 1, 1, 0.4)
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.big
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.rightMargin: 4
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Rectangle {
                            id: todayChip
                            readonly property bool away: !root.sameDay(root.sel, root.today)
                            anchors.verticalCenter: parent.verticalCenter
                            height: 26
                            radius: 13
                            width: away ? todayText.implicitWidth + 20 : 0
                            opacity: away ? 1 : 0
                            clip: true
                            color: todayHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.06)
                            Behavior on width { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 220 } }
                            Text {
                                id: todayText
                                anchors.centerIn: parent
                                text: I18n.t("cal.today")
                                color: "white"
                                font.family: Fonts.display
                                font.features: { "tnum": 1 }
                                font.pixelSize: Fonts.text
                                font.weight: Font.DemiBold
                            }
                            HoverHandler { id: todayHover; cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: root.select(root.today) }
                        }

                        Repeater {
                            model: [-1, 1]
                            Rectangle {
                                required property int modelData
                                anchors.verticalCenter: parent.verticalCenter
                                width: 30
                                height: 30
                                radius: 15
                                color: navHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : Qt.rgba(1, 1, 1, 0.05)
                                Behavior on color { ColorAnimation { duration: 160 } }
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData < 0 ? "󰅁" : "󰅂"
                                    color: "white"
                                    font.family: Fonts.glyph
                                    font.pixelSize: Fonts.large
                                }
                                HoverHandler { id: navHover; cursorShape: Qt.PointingHandCursor }
                                TapHandler { onTapped: root.stepMonth(modelData) }
                            }
                        }
                    }
                }

                Row {
                    id: wdRow
                    y: head.height + 14
                    Repeater {
                        model: root.weekdays
                        Text {
                            required property var modelData
                            required property int index
                            width: monthSide.cw
                            horizontalAlignment: Text.AlignHCenter
                            text: String(modelData).toUpperCase()
                            color: index >= 5 ? Colors.alpha(Colors.accentAlt, 0.7) : Qt.rgba(1, 1, 1, 0.35)
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.small
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.2
                        }
                    }
                }

                Item {
                    id: gridArea
                    y: wdRow.y + 26
                    width: parent.width
                    height: monthSide.ch * 6

                    readonly property int selCell: root.cellOf(root.sel)
                    readonly property real tx: (selCell % 7) * monthSide.cw + monthSide.cw / 2
                    readonly property real ty: Math.floor(selCell / 7) * monthSide.ch + monthSide.ch / 2

                    MorphSpring { id: leadX; springBack: true; response: 0.30; damping: 0.86; epsilon: 0.05 }
                    MorphSpring { id: leadY; springBack: true; response: 0.30; damping: 0.86; epsilon: 0.05 }
                    MorphSpring { id: trailX; springBack: true; response: 0.52; damping: 0.9; epsilon: 0.05 }
                    MorphSpring { id: trailY; springBack: true; response: 0.52; damping: 0.9; epsilon: 0.05 }

                    function aim() {
                        if (gridArea.selCell < 0)
                            return;
                        leadX.target = gridArea.tx;
                        leadY.target = gridArea.ty;
                        trailX.target = gridArea.tx;
                        trailY.target = gridArea.ty;
                    }
                    onTxChanged: gridArea.aim()
                    onTyChanged: gridArea.aim()
                    Component.onCompleted: {
                        gridArea.aim();
                        leadX.land(); leadY.land(); trailX.land(); trailY.land();
                    }
                    Connections {
                        target: root
                        function onShownChanged() {
                            if (!root.shown)
                                return;
                            gridArea.aim();
                            leadX.land(); leadY.land(); trailX.land(); trailY.land();
                            gooKick.restart();
                        }
                    }
                    Timer { id: gooKick; interval: 60; onTriggered: selGoo.applySync() }
                    Connections {
                        target: drip.card
                        function onVisibleChanged() { selGoo.applySync(); }
                    }

                    Item {
                        id: blobHost
                        anchors.fill: parent

                        Item {
                            property bool isBlob: true
                            readonly property real size: 40
                            width: size
                            height: size
                            x: trailX.value - size / 2
                            y: trailY.value - size / 2
                            onXChanged: selGoo.applySync()
                            onYChanged: selGoo.applySync()
                        }
                        Item {
                            property bool isBlob: true
                            readonly property real size: 42
                            width: size
                            height: size
                            x: leadX.value - size / 2
                            y: leadY.value - size / 2
                            onXChanged: selGoo.applySync()
                            onYChanged: selGoo.applySync()
                        }
                    }

                    RectangularShadow {
                        x: leadX.value - 24
                        y: leadY.value - 24
                        width: 48
                        height: 48
                        radius: 24
                        blur: 26
                        color: Colors.alpha(Colors.accent, 0.55)
                        visible: gridArea.selCell >= 0
                    }

                    Blobs {
                        id: selGoo
                        host: blobHost
                        fuse: 16
                        corner: 16
                        stroke: 0
                        shadow: false
                        fillColor: Colors.accent
                        fillAlpha: 0.92
                        hoverColor: Colors.accent
                        hoverAlpha: 0.92
                        strokeAlpha: 0
                        visible: gridArea.selCell >= 0
                    }

                    Item {
                        id: gridFace
                        anchors.fill: parent
                        property real shift: 0
                        property real haze: 0
                        transform: Translate { x: gridFace.shift }
                        layer.enabled: gridFace.haze > 0.01
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blurMax: 32
                            blur: gridFace.haze
                            autoPaddingEnabled: false
                        }

                        Repeater {
                            model: 42

                            Item {
                                id: cell
                                required property int index
                                readonly property date d: root.addDays(root.gridStart, cell.index)
                                readonly property bool inMonth: cell.d.getMonth() === root.view.getMonth()
                                readonly property bool isToday: root.sameDay(cell.d, root.today)
                                readonly property bool isSel: root.sameDay(cell.d, root.sel)
                                readonly property int reminds: Reminders.perDay[Reminders.dayKey(cell.d)] || 0
                                readonly property real work: Math.min(1, root.commitsOn(cell.d) / root.activityMax)

                                x: (cell.index % 7) * monthSide.cw
                                y: Math.floor(cell.index / 7) * monthSide.ch
                                width: monthSide.cw
                                height: monthSide.ch

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 34
                                    height: 34
                                    radius: 17
                                    visible: cell.work > 0 && !cell.isSel
                                    color: Colors.alpha(Colors.accentAlt, 0.05 + 0.16 * cell.work)
                                }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 40
                                    height: 40
                                    radius: 20
                                    visible: cell.isToday && !cell.isSel
                                    color: "transparent"
                                    border.width: 1.5
                                    border.color: Colors.alpha(Colors.accent, 0.85)
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: cell.d.getDate()
                                    color: cell.isSel ? "black"
                                         : !cell.inMonth ? Qt.rgba(1, 1, 1, 0.18)
                                         : cell.isToday ? Qt.lighter(Colors.accent, 1.3)
                                         : (cell.index % 7) >= 5 ? Qt.rgba(1, 1, 1, 0.6) : Qt.rgba(1, 1, 1, 0.86)
                                    font.family: Fonts.display
                                    font.features: { "tnum": 1 }
                                    font.pixelSize: Fonts.medium
                                    font.weight: cell.isSel || cell.isToday ? Font.Bold : Font.Normal
                                    Behavior on color { ColorAnimation { duration: 220 } }
                                }

                                Row {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 7
                                    spacing: 3
                                    visible: cell.reminds > 0
                                    Repeater {
                                        model: Math.min(3, cell.reminds)
                                        Rectangle {
                                            width: 4
                                            height: 4
                                            radius: 2
                                            color: cell.isSel ? Qt.rgba(0, 0, 0, 0.7) : Colors.warn
                                        }
                                    }
                                }

                                HoverHandler { id: cellHover; cursorShape: Qt.PointingHandCursor }
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 40
                                    height: 40
                                    radius: 16
                                    color: Qt.rgba(1, 1, 1, 0.06)
                                    visible: cellHover.hovered && !cell.isSel
                                }
                                TapHandler { onTapped: root.select(cell.d) }
                            }
                        }
                    }

                    SequentialAnimation {
                        id: swap
                        ParallelAnimation {
                            NumberAnimation { target: gridFace; property: "opacity"; to: 0; duration: 170; easing.type: Easing.InCubic }
                            NumberAnimation { target: gridFace; property: "shift"; to: -34 * root.dir; duration: 170; easing.type: Easing.InCubic }
                            NumberAnimation { target: gridFace; property: "haze"; to: 1; duration: 170 }
                        }
                        ScriptAction { script: root.view = root.pendingView }
                        ParallelAnimation {
                            NumberAnimation { target: gridFace; property: "opacity"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic }
                            NumberAnimation { target: gridFace; property: "shift"; from: 40 * root.dir; to: 0; duration: 520; easing.type: Easing.OutCubic }
                            NumberAnimation { target: gridFace; property: "haze"; from: 1; to: 0; duration: 420; easing.type: Easing.OutCubic }
                        }
                    }
                }
            }
        }
    }
}
