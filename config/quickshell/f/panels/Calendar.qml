import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import Quickshell.Wayland
import "root:/design"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    property int offset: 0

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (!root.shown) root.offset = 0;
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

    readonly property var months: I18n.list("cal.months")
    readonly property var weekdays: I18n.list("cal.weekdays")
    readonly property var monthsGen: I18n.list("cal.monthsGen")
    readonly property var weekdaysFull: I18n.list("cal.weekdaysFull")

    readonly property string longDate: {
        const d = clock.date;
        return weekdaysFull[d.getDay()] + ", " + d.getDate() + " "
             + monthsGen[d.getMonth()] + " " + d.getFullYear();
    }

    readonly property var days: {
        const first = new Date(shownMonth);
        const shift = (first.getDay() + 6) % 7;
        const start = new Date(first);
        start.setDate(1 - shift);

        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start);
            d.setDate(start.getDate() + i);
            out.push(d);
        }
        return out;
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

    function commitsOn(date) {
        const key = Qt.formatDate(date, "yyyy-MM-dd");
        const n = root.activity[key];
        return n === undefined ? 0 : n;
    }

    function sameDay(a, b) {
        return a.getFullYear() === b.getFullYear()
            && a.getMonth() === b.getMonth()
            && a.getDate() === b.getDate();
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
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.30 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: 46
            width: 300
            height: body.implicitHeight + 32
            radius: 20
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
            border.width: 1
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30)

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 190 } }
            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }

            focus: true
            Keys.onEscapePressed: root.close()
            Keys.onLeftPressed: root.offset--
            Keys.onRightPressed: root.offset++

            WheelHandler {
                onWheel: wheel => root.offset += wheel.angleDelta.y > 0 ? -1 : 1
            }

            Column {
                id: body
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Row {
                    width: parent.width

                    component Arrow: Text {
                        property bool hovered: false
                        color: hovered ? Colors.accent : Colors.fgDim
                        opacity: hovered ? 1 : 0.55
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 140 } }
                        HoverHandler { onHoveredChanged: parent.hovered = hovered }
                    }

                    Arrow {
                        text: "󰅁"
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.offset--
                        }
                    }

                    Item { width: 10; height: 1 }

                    Text {
                        width: parent.width - 60
                        horizontalAlignment: Text.AlignHCenter
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.months[root.shownMonth.getMonth()]
                              + " " + root.shownMonth.getFullYear()
                        color: Colors.fg
                        font.family: Fonts.display
                        font.pixelSize: 13
                        font.weight: Font.DemiBold

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: root.offset !== 0
                                ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.offset = 0
                        }
                    }

                    Item { width: 10; height: 1 }

                    Arrow {
                        text: "󰅂"
                        anchors.verticalCenter: parent.verticalCenter
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.offset++
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 7
                    spacing: 0

                    Repeater {
                        model: root.weekdays

                        Item {
                            required property string modelData
                            width: (parent.width - 0) / 7
                            height: 20

                            Text {
                                anchors.centerIn: parent
                                text: parent.modelData
                                color: Colors.fgDim
                                opacity: 0.45
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 7
                    spacing: 0

                    Repeater {
                        model: root.days

                        Item {
                            id: cell
                            required property var modelData

                            readonly property bool today: root.sameDay(modelData, clock.date)
                            readonly property bool inMonth:
                                modelData.getMonth() === root.shownMonth.getMonth()
                            readonly property bool weekend: {
                                const wd = modelData.getDay();
                                return wd === 0 || wd === 6;
                            }

                            width: parent.width / 7
                            height: 30

                            readonly property int commits:
                                root.commitsOn(modelData)

                            readonly property real heat: {
                                if (cell.commits <= 0) return 0;
                                const ratio = cell.commits / root.activityMax;
                                return 0.18 + 0.62 * Math.sqrt(ratio);
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                radius: 9
                                visible: cell.heat > 0 && !cell.today
                                opacity: cell.inMonth ? 1 : 0.3
                                color: Qt.rgba(Colors.accentAlt.r,
                                               Colors.accentAlt.g,
                                               Colors.accentAlt.b, cell.heat)
                                Behavior on color { ColorAnimation { duration: 200 } }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 26
                                height: 26
                                radius: 13
                                color: cell.today
                                    ? Colors.accent
                                    : hover.hovered && cell.inMonth
                                        ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                                  Colors.bgAlt.b, 0.55)
                                        : "transparent"
                                Behavior on color { ColorAnimation { duration: 140 } }

                                HoverHandler { id: hover }

                                Text {
                                    anchors.centerIn: parent
                                    text: cell.modelData.getDate()
                                    color: cell.today ? Colors.accentText
                                         : !cell.inMonth ? Colors.fgDim
                                         : cell.weekend ? Colors.accentAlt
                                         : Colors.fg
                                    opacity: cell.inMonth ? 1 : 0.25
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.weight: cell.today ? Font.Bold : Font.Normal
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.18)
                }

                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.longDate
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }
        }
    }
}
