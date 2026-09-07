import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "month"

    readonly property bool bare: face.variant === "day"
                              || face.variant === "week"
                              || face.variant === "dots"

    readonly property string mono: Fonts.mono

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Hours
    }

    readonly property var now: clock.date
    readonly property int today: face.now.getDate()
    readonly property int month: face.now.getMonth()
    readonly property int year: face.now.getFullYear()

    readonly property var monthNames: I18n.list("cal.months")
    readonly property var weekdays: I18n.list("cal.weekdays")
    readonly property var weekdaysFull: I18n.list("cal.weekdaysFull")

    readonly property var cells: {
        const first = new Date(face.year, face.month, 1);
        const lead = (first.getDay() + 6) % 7;
        const start = new Date(face.year, face.month, 1 - lead);

        const out = [];
        for (let i = 0; i < 42; i++) {
            const d = new Date(start.getFullYear(), start.getMonth(),
                               start.getDate() + i);
            out.push({
                day: d.getDate(),
                inMonth: d.getMonth() === face.month,
                isToday: d.getDate() === face.today
                    && d.getMonth() === face.month
                    && d.getFullYear() === face.year,
                weekend: i % 7 >= 5
            });
        }
        return out;
    }

    readonly property int daysInMonth:
        new Date(face.year, face.month + 1, 0).getDate()

    readonly property real monthPart: face.today / face.daysInMonth

    readonly property var thisWeek: {
        const offset = (face.now.getDay() + 6) % 7;
        const out = [];
        for (let i = 0; i < 7; i++) {
            const d = new Date(face.year, face.month, face.today - offset + i);
            out.push({
                day: d.getDate(),
                weekday: face.weekdays[i] || "",
                weekdayFull: face.weekdaysFull[i] || "",
                isToday: i === offset,
                weekend: i >= 5,
                month: d.getMonth()
            });
        }
        return out;
    }

    readonly property var nextDays: {
        const out = [];
        for (let i = 0; i < 7; i++) {
            const d = new Date(face.year, face.month, face.today + i);
            out.push({
                day: d.getDate(),
                weekdayFull: face.weekdaysFull[(d.getDay() + 6) % 7] || "",
                monthName: face.monthNames[d.getMonth()] || "",
                isToday: i === 0,
                weekend: (d.getDay() + 6) % 7 >= 5
            });
        }
        return out;
    }

    Loader {
        id: loader
        sourceComponent: face.variant === "day" ? day
                       : face.variant === "week" ? week
                       : face.variant === "year" ? year
                       : face.variant === "tear" ? tear
                       : face.variant === "ring" ? ring
                       : face.variant === "list" ? upcoming
                       : face.variant === "compact" ? compact
                       : face.variant === "dots" ? dots
                       : face.variant === "column" ? column
                       : month
    }

    Component {
        id: month

        Rectangle {
            implicitWidth: 268
            implicitHeight: body.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: body

                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 10

                Row {
                    width: parent.width

                    Text {
                        text: face.monthNames[face.month] || ""
                        color: Colors.fg
                        font.family: Fonts.display
                        font.pixelSize: 15
                    }

                    Item { width: parent.width - 150; height: 1 }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: face.year
                        color: Colors.fgDim
                        opacity: 0.5
                        font.family: face.mono
                        font.pixelSize: 11
                    }
                }

                Grid {
                    width: parent.width
                    columns: 7
                    spacing: 0

                    Repeater {
                        model: face.weekdays

                        Text {
                            required property string modelData
                            required property int index

                            width: body.width / 7
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: index >= 5 ? Colors.accentAlt : Colors.fgDim
                            opacity: 0.5
                            font.family: face.mono
                            font.pixelSize: 9
                        }
                    }
                }

                Grid {
                    width: parent.width
                    columns: 7
                    spacing: 0

                    Repeater {
                        model: face.cells

                        Item {
                            required property var modelData

                            width: body.width / 7
                            height: 26

                            Rectangle {
                                anchors.centerIn: parent
                                width: 22
                                height: 22
                                radius: Shape.detail
                                visible: modelData.isToday
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                               Colors.accent.b, 0.85)
                            }

                            Text {
                                anchors.centerIn: parent
                                text: modelData.day
                                color: modelData.isToday ? Colors.accentText
                                     : modelData.weekend ? Colors.accentAlt
                                     : Colors.fg
                                opacity: modelData.inMonth ? (modelData.isToday ? 1 : 0.8) : 0.22
                                font.family: face.mono
                                font.pixelSize: 11
                                font.weight: modelData.isToday ? Font.DemiBold : Font.Normal
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: day

        Column {
            spacing: -6

            Text {
                text: face.weekdaysFull[(face.now.getDay() + 6) % 7] || ""
                color: Colors.accent
                opacity: 0.9
                font.family: Fonts.display
                font.pixelSize: 20
                font.letterSpacing: 4
            }

            Text {
                text: face.today
                color: Colors.fg
                opacity: 0.94
                font.family: face.mono
                font.pixelSize: 108
                font.weight: Font.Thin
                font.letterSpacing: -4
            }

            Text {
                text: (face.monthNames[face.month] || "") + " " + face.year
                color: Colors.fgDim
                opacity: 0.7
                font.family: face.mono
                font.pixelSize: 13
                font.letterSpacing: 3
            }
        }
    }
    Component {
        id: week

        Row {
            spacing: 10

            Repeater {
                model: face.thisWeek

                Column {
                    id: dayChip

                    required property var modelData

                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: dayChip.modelData.weekday
                        color: dayChip.modelData.weekend ? Colors.accentAlt : Colors.fgDim
                        opacity: dayChip.modelData.isToday ? 0.9 : 0.5
                        font.family: face.mono
                        font.pixelSize: 10
                        font.letterSpacing: 1
                    }

                    Rectangle {
                        width: 44
                        height: 44
                        radius: Shape.chip
                        antialiasing: true
                        color: dayChip.modelData.isToday
                            ? Colors.accent
                            : Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)
                        border.width: 1
                        border.color: dayChip.modelData.isToday
                            ? "transparent"
                            : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                      Colors.outline.b, 0.22)

                        Text {
                            anchors.centerIn: parent
                            text: dayChip.modelData.day
                            color: dayChip.modelData.isToday ? Colors.accentText : Colors.fg
                            opacity: dayChip.modelData.isToday ? 1 : 0.8
                            font.family: face.mono
                            font.pixelSize: 17
                            font.weight: dayChip.modelData.isToday
                                ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }
    }

    Component {
        id: year

        Rectangle {
            implicitWidth: 268
            implicitHeight: yearBody.implicitHeight + 36
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: yearBody

                anchors.centerIn: parent
                width: parent.width - 36
                spacing: 14

                Row {
                    width: parent.width

                    Text {
                        text: face.year
                        color: Colors.fg
                        font.family: face.mono
                        font.pixelSize: 22
                        font.weight: Font.Light
                    }

                    Item { width: parent.width - 130; height: 1 }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 3
                        text: Math.round(((face.month + face.monthPart) / 12) * 100) + "%"
                        color: Colors.accent
                        opacity: 0.8
                        font.family: face.mono
                        font.pixelSize: 12
                    }
                }

                Grid {
                    width: parent.width
                    columns: 4
                    columnSpacing: 8
                    rowSpacing: 8

                    Repeater {
                        model: 12

                        Rectangle {
                            id: monthCell

                            required property int index

                            readonly property bool past: index < face.month
                            readonly property bool current: index === face.month

                            width: (yearBody.width - 24) / 4
                            height: 38
                            radius: Shape.chip
                            color: current
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.22)
                                : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                          Colors.bgAlt.b, past ? 0.5 : 0.22)
                            border.width: 1
                            border.color: current
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.55)
                                : "transparent"

                            Text {
                                anchors.centerIn: parent
                                text: (face.monthNames[monthCell.index] || "")
                                        .substring(0, 3).toLowerCase()
                                color: monthCell.current ? Colors.accent : Colors.fg
                                opacity: monthCell.current ? 1 : (monthCell.past ? 0.7 : 0.35)
                                font.family: face.mono
                                font.pixelSize: 11
                            }

                            Rectangle {
                                visible: monthCell.current
                                anchors.left: parent.left
                                anchors.bottom: parent.bottom
                                anchors.margins: 1
                                width: (parent.width - 2) * face.monthPart
                                height: 2
                                radius: 1
                                color: Colors.accent
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: tear

        Rectangle {
            implicitWidth: 200
            implicitHeight: 230
            radius: 8
            color: Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.93)

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 34
                radius: 8
                color: Colors.accent

                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 10
                    color: Colors.accent
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 60

                    Repeater {
                        model: 2

                        Rectangle {
                            width: 12
                            height: 12
                            radius: 6
                            antialiasing: true
                            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
                        }
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                anchors.verticalCenterOffset: 14
                spacing: -12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.today
                    color: Colors.bg
                    font.family: face.mono
                    font.pixelSize: 116
                    font.weight: Font.Light
                    font.letterSpacing: -4
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 16
                    text: (face.weekdaysFull[(face.now.getDay() + 6) % 7] || "")
                    color: Colors.bg
                    opacity: 0.65
                    font.family: Fonts.display
                    font.pixelSize: 16
                    font.letterSpacing: 3
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 6
                    text: (face.monthNames[face.month] || "") + " " + face.year
                    color: Colors.bg
                    opacity: 0.45
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }

    Component {
        id: ring

        Item {
            implicitWidth: 190
            implicitHeight: 190

            ProgressRing {
                anchors.fill: parent
                value: face.monthPart
                color: Colors.accent
                trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.14)
                thickness: 6
                inset: 4
                animationDuration: 900
            }

            Column {
                anchors.centerIn: parent
                spacing: -4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.today
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 58
                    font.weight: Font.Thin
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: (face.monthNames[face.month] || "").toLowerCase()
                    color: Colors.fgDim
                    opacity: 0.65
                    font.family: Fonts.display
                    font.pixelSize: 13
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 4
                    text: (face.daysInMonth - face.today) + " left"
                    color: Colors.accent
                    opacity: 0.7
                    font.family: face.mono
                    font.pixelSize: 10
                }
            }
        }
    }

    Component {
        id: upcoming

        Rectangle {
            implicitWidth: 250
            implicitHeight: agenda.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: agenda

                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 2

                Repeater {
                    model: face.nextDays

                    Item {
                        id: agendaRow

                        required property var modelData

                        width: agenda.width
                        height: 30

                        Rectangle {
                            anchors.fill: parent
                            radius: Shape.chip
                            visible: agendaRow.modelData.isToday
                            color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                           Colors.accent.b, 0.16)
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: agendaRow.modelData.day
                            color: agendaRow.modelData.isToday ? Colors.accent : Colors.fg
                            opacity: agendaRow.modelData.isToday ? 1 : 0.8
                            font.family: face.mono
                            font.pixelSize: 14
                            font.weight: agendaRow.modelData.isToday
                                ? Font.DemiBold : Font.Normal
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 44
                            anchors.verticalCenter: parent.verticalCenter
                            text: agendaRow.modelData.weekdayFull
                            color: agendaRow.modelData.weekend
                                ? Colors.accentAlt : Colors.fgDim
                            opacity: agendaRow.modelData.isToday ? 0.9 : 0.6
                            font.family: Fonts.display
                            font.pixelSize: 12
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            visible: agendaRow.modelData.isToday
                            text: I18n.t("time.today")
                            color: Colors.accent
                            opacity: 0.7
                            font.family: face.mono
                            font.pixelSize: 9
                            font.letterSpacing: 1
                        }
                    }
                }
            }
        }
    }

    Component {
        id: compact

        Rectangle {
            implicitWidth: dateRow.implicitWidth + 34
            implicitHeight: 52
            radius: Shape.field
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.5)

            Sheen {
                anchors.fill: parent
                radius: Shape.field
                edgeOpacity: 0.14
            }

            Row {
                id: dateRow

                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: face.today
                    color: Colors.accent
                    font.family: face.mono
                    font.pixelSize: 30
                    font.weight: Font.Light
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: face.weekdaysFull[(face.now.getDay() + 6) % 7] || ""
                        color: Colors.fg
                        font.family: Fonts.display
                        font.pixelSize: 14
                    }

                    Text {
                        text: (face.monthNames[face.month] || "").toLowerCase()
                              + " " + face.year
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: face.mono
                        font.pixelSize: 10
                    }
                }
            }
        }
    }

    Component {
        id: dots

        Grid {
            columns: 7
            columnSpacing: 9
            rowSpacing: 9

            Repeater {
                model: face.daysInMonth

                Rectangle {
                    required property int index

                    readonly property bool past: index + 1 < face.today
                    readonly property bool current: index + 1 === face.today

                    width: current ? 14 : 10
                    height: width
                    radius: width / 2
                    antialiasing: true

                    color: current ? Colors.accent
                         : past ? Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.55)
                         : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.20)

                    Behavior on color { ColorAnimation { duration: Colors.morph } }
                }
            }
        }
    }

    Component {
        id: column

        Rectangle {
            implicitWidth: 150
            implicitHeight: weekColumn.implicitHeight + 28
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: weekColumn

                anchors.centerIn: parent
                width: parent.width - 28
                spacing: 4

                Repeater {
                    model: face.thisWeek

                    Rectangle {
                        id: weekRow

                        required property var modelData

                        width: weekColumn.width
                        height: 30
                        radius: Shape.chip
                        color: modelData.isToday
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                      Colors.accent.b, 0.22)
                            : "transparent"

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: weekRow.modelData.weekday
                            color: weekRow.modelData.weekend
                                ? Colors.accentAlt : Colors.fgDim
                            opacity: weekRow.modelData.isToday ? 0.95 : 0.55
                            font.family: face.mono
                            font.pixelSize: 11
                            font.letterSpacing: 1
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: weekRow.modelData.day
                            color: weekRow.modelData.isToday ? Colors.accent : Colors.fg
                            opacity: weekRow.modelData.isToday ? 1 : 0.75
                            font.family: face.mono
                            font.pixelSize: 15
                            font.weight: weekRow.modelData.isToday
                                ? Font.DemiBold : Font.Normal
                        }
                    }
                }
            }
        }
    }
}
