import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "month"

    readonly property bool bare: face.variant === "day"

    readonly property string mono: "JetBrainsMono Nerd Font"

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

    Loader {
        id: loader
        sourceComponent: face.variant === "day" ? day : month
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
}
