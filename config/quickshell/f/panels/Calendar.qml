import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property int offset: 0
    property int hovered: -1

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (!root.shown) {
            root.offset = 0;
            root.hovered = -1;
        }
    }

    function step(by) {
        root.offset += by;
        root.hovered = -1;
        Sfx.pick();
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property date shownMonth: {
        const d = new Date(clock.date);
        d.setDate(1);
        d.setMonth(d.getMonth() + root.offset);
        return d;
    }

    readonly property bool thisMonth:
        shownMonth.getMonth() === clock.date.getMonth()
        && shownMonth.getFullYear() === clock.date.getFullYear()

    readonly property int daysInMonth:
        new Date(shownMonth.getFullYear(), shownMonth.getMonth() + 1, 0).getDate()

    readonly property var months: I18n.list("cal.months")
    readonly property var monthsGen: I18n.list("cal.monthsGen")
    readonly property var weekdaysFull: I18n.list("cal.weekdaysFull")

    readonly property string longDate: {
        const d = clock.date;
        return weekdaysFull[d.getDay()] + ", " + d.getDate() + " "
             + monthsGen[d.getMonth()] + " " + d.getFullYear();
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
                Quickshell.env("HOME") + "/.config/hypr/scripts/git-activity.py",
                "--quiet"
            ];
            activityScan.running = true;
        }
    }

    function dateFor(day) {
        return new Date(root.shownMonth.getFullYear(),
                        root.shownMonth.getMonth(), day);
    }

    function commitsOn(date) {
        const key = Qt.formatDate(date, "yyyy-MM-dd");
        const n = root.activity[key];
        return n === undefined ? 0 : n;
    }

    function commitsForDay(day) {
        return root.commitsOn(root.dateFor(day));
    }

    readonly property int focusDay: {
        if (root.hovered > 0)
            return root.hovered;
        if (root.thisMonth)
            return clock.date.getDate();
        return 1;
    }

    readonly property date focusDate: root.dateFor(root.focusDay)

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-calendar"
        id: win

        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        readonly property string mono: "JetBrainsMono Nerd Font"

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.35)
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
                onWheel: (wheel) => root.step(wheel.angleDelta.y > 0 ? -1 : 1)
            }
        }

        Glass {
            id: card

            anchors.centerIn: parent
            width: 460
            height: 500
            radius: Shape.modal
            elevation: 3
            focus: true

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                NumberAnimation {
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.snap
                }
            }

            Item {
                id: dial

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: 22
                width: 400
                height: 400

                readonly property real cx: width / 2
                readonly property real cy: height / 2
                readonly property real dayRing: 148
                readonly property real monthRing: 186

                function angleFor(day) {
                    return (day - 1) / root.daysInMonth * 2 * Math.PI - Math.PI / 2;
                }

                Repeater {
                    model: 12

                    Item {
                        id: monthMark

                        required property int index

                        readonly property bool current:
                            index === root.shownMonth.getMonth()
                        readonly property real angle:
                            index / 12 * 2 * Math.PI - Math.PI / 2

                        x: dial.cx + Math.cos(angle) * dial.monthRing - width / 2
                        y: dial.cy + Math.sin(angle) * dial.monthRing - height / 2
                        width: 46
                        height: 18

                        Text {
                            anchors.centerIn: parent
                            text: {
                                const name = root.months[monthMark.index];
                                return name ? name.slice(0, 3).toLowerCase() : "";
                            }
                            color: monthMark.current ? Colors.accent : Colors.fgDim
                            opacity: monthMark.current ? 1
                                   : (monthHover.hovered ? 0.85 : 0.32)
                            font.family: win.mono
                            font.pixelSize: 9
                            font.letterSpacing: 1

                            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                            Behavior on color { ColorAnimation { duration: Motion.fast } }
                        }

                        HoverHandler { id: monthHover }

                        TapHandler {
                            onTapped: {
                                const now = new Date(clock.date);
                                root.offset =
                                    (root.shownMonth.getFullYear() - now.getFullYear()) * 12
                                    + monthMark.index - now.getMonth();
                                root.hovered = -1;
                                Sfx.pick();
                            }
                        }
                    }
                }

                Canvas {
                    id: spent

                    anchors.fill: parent
                    antialiasing: true

                    readonly property real done:
                        root.thisMonth ? clock.date.getDate() / root.daysInMonth : 0

                    onDoneChanged: requestPaint()
                    Component.onCompleted: requestPaint()

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        if (spent.done <= 0)
                            return;
                        ctx.lineWidth = 2;
                        ctx.lineCap = "round";
                        ctx.strokeStyle = Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                  Colors.accent.b, 0.30);
                        ctx.beginPath();
                        ctx.arc(dial.cx, dial.cy, dial.dayRing + 18,
                                -Math.PI / 2,
                                -Math.PI / 2 + Math.PI * 2 * spent.done);
                        ctx.stroke();
                    }
                }

                Repeater {
                    model: root.daysInMonth

                    Item {
                        id: tick

                        required property int index

                        readonly property int day: index + 1
                        readonly property real angle: dial.angleFor(day)
                        readonly property int commits: root.commitsForDay(day)
                        readonly property real heat:
                            commits > 0 ? Math.min(1, commits / root.activityMax) : 0
                        readonly property bool today:
                            root.thisMonth && day === clock.date.getDate()
                        readonly property bool weekend: {
                            const wd = root.dateFor(day).getDay();
                            return wd === 0 || wd === 6;
                        }
                        readonly property bool active: root.hovered === day

                        x: dial.cx + Math.cos(angle) * dial.dayRing - width / 2
                        y: dial.cy + Math.sin(angle) * dial.dayRing - height / 2
                        width: 22
                        height: 26
                        rotation: angle * 180 / Math.PI + 90

                        opacity: 0
                        SequentialAnimation on opacity {
                            running: root.shown
                            PauseAnimation { duration: Math.min(tick.index, 31) * 13 }
                            NumberAnimation { to: 1; duration: Motion.base }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            width: 3
                            height: 9 + tick.heat * 15
                            radius: 1.5
                            antialiasing: true

                            color: tick.today ? Colors.accent
                                 : tick.heat > 0 ? Colors.accentAlt
                                 : Colors.fgDim
                            opacity: tick.active || tick.today ? 1
                                   : tick.heat > 0 ? 0.5 + tick.heat * 0.5
                                   : (tick.weekend ? 0.32 : 0.58)
                            scale: tick.active ? 1.4 : 1

                            Behavior on height {
                                NumberAnimation {
                                    duration: Motion.slow
                                    easing.type: Easing.Bezier
                                    easing.bezierCurve: Motion.decel
                                }
                            }
                            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                            Behavior on scale { Spring {} }
                            Behavior on color { ColorAnimation { duration: Motion.base } }
                        }

                        Rectangle {
                            anchors.centerIn: parent
                            visible: tick.today
                            width: 20
                            height: 20
                            radius: width / 2
                            color: "transparent"
                            border.width: 1
                            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                  Colors.accent.b, 0.45)

                            SequentialAnimation on scale {
                                running: root.shown && tick.today
                                loops: Animation.Infinite
                                NumberAnimation { to: 1.3; duration: 1900; easing.type: Easing.InOutQuad }
                                NumberAnimation { to: 1.0; duration: 1900; easing.type: Easing.InOutQuad }
                            }
                        }

                        HoverHandler {
                            onHoveredChanged: {
                                if (hovered) {
                                    root.hovered = tick.day;
                                    Sfx.tick();
                                } else if (root.hovered === tick.day) {
                                    root.hovered = -1;
                                }
                            }
                        }
                    }
                }

                Repeater {
                    model: [5, 10, 15, 20, 25, 30]

                    Text {
                        required property int modelData

                        visible: modelData <= root.daysInMonth

                        readonly property real angle: dial.angleFor(modelData)

                        x: dial.cx + Math.cos(angle) * (dial.dayRing - 26) - width / 2
                        y: dial.cy + Math.sin(angle) * (dial.dayRing - 26) - height / 2

                        text: modelData
                        color: Colors.fgDim
                        opacity: 0.28
                        font.family: win.mono
                        font.pixelSize: 9
                    }
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            const name = root.weekdaysFull[root.focusDate.getDay()];
                            return name ? name.toLowerCase() : "";
                        }
                        color: Colors.fgDim
                        opacity: 0.55
                        font.family: win.mono
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }

                    RollText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: String(root.focusDay)
                        color: Colors.fg
                        family: Fonts.display
                        pixelSize: 54
                        weight: Font.Light
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            const name = root.months[root.shownMonth.getMonth()];
                            return (name ? name.toLowerCase() : "")
                                 + "  " + root.shownMonth.getFullYear();
                        }
                        color: Colors.accent
                        opacity: 0.85
                        font.family: win.mono
                        font.pixelSize: 11
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter

                        readonly property int commits: root.commitsForDay(root.focusDay)

                        visible: commits > 0
                        text: I18n.count("plural.commit", commits)
                        color: Colors.accentAlt
                        opacity: 0.8
                        font.family: win.mono
                        font.pixelSize: 10
                    }
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 24
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.longDate.toLowerCase()
                    color: Colors.fgDim
                    opacity: 0.7
                    font.family: Fonts.display
                    font.pixelSize: 13
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    IconButton {
                        glyph: "󰅁"
                        tip: I18n.t("cal.prev")
                        tint: Colors.fgDim
                        onActivated: root.step(-1)
                    }

                    IconButton {
                        glyph: "󰃭"
                        tip: I18n.t("cal.today")
                        tint: Colors.accent
                        onActivated: {
                            root.offset = 0;
                            root.hovered = -1;
                            Sfx.tap();
                        }
                    }

                    IconButton {
                        glyph: "󰅂"
                        tip: I18n.t("cal.next")
                        tint: Colors.fgDim
                        onActivated: root.step(1)
                    }
                }
            }

            WheelHandler {
                onWheel: (wheel) => root.step(wheel.angleDelta.y > 0 ? -1 : 1)
            }

            Keys.onEscapePressed: root.close()
            Keys.onLeftPressed: root.step(-1)
            Keys.onRightPressed: root.step(1)
            Keys.onUpPressed: root.step(-1)
            Keys.onDownPressed: root.step(1)
        }
    }
}
