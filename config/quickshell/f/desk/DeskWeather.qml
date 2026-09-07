import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "full"

    readonly property bool bare: face.variant === "compact"
                              || face.variant === "hero"
                              || face.variant === "strip"
                              || face.variant === "ring"

    readonly property string mono: Fonts.mono

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    readonly property real coldest: -20
    readonly property real hottest: 40

    function part(t) {
        return Math.max(0, Math.min(1, (t - face.coldest)
                                       / (face.hottest - face.coldest)));
    }

    function heat(t) {
        const p = face.part(t);
        if (p < 0.45)
            return Qt.tint(Colors.accentAlt,
                           Qt.rgba(Colors.accent.r, Colors.accent.g,
                                   Colors.accent.b, p * 1.6));
        return Qt.tint(Colors.accent,
                       Qt.rgba(Colors.warn.r, Colors.warn.g, Colors.warn.b,
                               (p - 0.45) * 1.4));
    }

    readonly property var today: Weather.forecast.length > 0
        ? Weather.forecast[0] : null

    Loader {
        id: loader
        sourceComponent: face.variant === "compact" ? compact
                       : face.variant === "hero" ? hero
                       : face.variant === "detail" ? detail
                       : face.variant === "strip" ? strip
                       : face.variant === "ring" ? ring
                       : face.variant === "sky" ? sky
                       : face.variant === "forecast" ? forecast
                       : face.variant === "badge" ? badge
                       : face.variant === "range" ? range
                       : full
    }

    Component {
        id: hero

        Column {
            spacing: -10

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Weather.glyph
                color: Weather.tint
                font.family: face.mono
                font.pixelSize: 92
                Behavior on color { ColorAnimation { duration: Colors.morph } }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Weather.ready ? Math.round(Weather.temp) + "°" : "··"
                color: Colors.fg
                opacity: 0.94
                font.family: face.mono
                font.pixelSize: 76
                font.weight: Font.Thin
                font.letterSpacing: -2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Weather.text
                color: Colors.fgDim
                opacity: 0.7
                font.family: face.mono
                font.pixelSize: 12
                font.letterSpacing: 2
            }
        }
    }

    Component {
        id: compact

        Row {
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.glyph
                color: Weather.tint
                font.family: face.mono
                font.pixelSize: 40
                Behavior on color { ColorAnimation { duration: Colors.morph } }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.ready ? Math.round(Weather.temp) + "°" : "··"
                color: Colors.fg
                font.family: face.mono
                font.pixelSize: 44
                font.weight: Font.Light
            }
        }
    }

    Component {
        id: full

        Rectangle {
            implicitWidth: 250
            implicitHeight: column.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: column
                anchors.centerIn: parent
                width: parent.width - 36
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 14

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Weather.glyph
                        color: Weather.tint
                        font.family: face.mono
                        font.pixelSize: 44
                        Behavior on color { ColorAnimation { duration: Colors.morph } }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: Weather.ready ? Math.round(Weather.temp) + "°" : "··°"
                            color: Colors.fg
                            font.family: face.mono
                            font.pixelSize: 34
                            font.weight: Font.Light
                        }

                        Text {
                            text: Weather.city !== "" ? Weather.city.toLowerCase() : "…"
                            color: Colors.fgDim
                            opacity: 0.7
                            font.family: face.mono
                            font.pixelSize: 11
                            font.letterSpacing: 2
                        }
                    }
                }

                Text {
                    width: parent.width
                    text: Weather.error !== "" ? Weather.error : Weather.text.toLowerCase()
                    color: Weather.error !== "" ? Colors.bad : Colors.fgDim
                    opacity: 0.8
                    elide: Text.ElideRight
                    font.family: face.mono
                    font.pixelSize: 12
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.16)
                }

                Row {
                    width: parent.width
                    spacing: 0
                    visible: Weather.forecast.length > 0

                    Repeater {
                        model: Weather.forecast

                        Column {
                            required property var modelData
                            required property int index

                            width: column.width / Math.max(1, Weather.forecast.length)
                            spacing: 4

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(new Date(modelData.date), "ddd").toLowerCase()
                                color: Colors.fgDim
                                opacity: index === 0 ? 0.9 : 0.55
                                font.family: face.mono
                                font.pixelSize: 10
                                font.letterSpacing: 1
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.max + "°"
                                color: index === 0 ? Colors.accent : Colors.fg
                                opacity: index === 0 ? 1 : 0.75
                                font.family: face.mono
                                font.pixelSize: 14
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.min + "°"
                                color: Colors.fgDim
                                opacity: 0.45
                                font.family: face.mono
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: detail

        Rectangle {
            implicitWidth: 300
            implicitHeight: grid.implicitHeight + head.implicitHeight + 62
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Row {
                id: head

                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 20
                spacing: 16

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.glyph
                    color: Weather.tint
                    font.family: face.mono
                    font.pixelSize: 52
                    Behavior on color { ColorAnimation { duration: Colors.morph } }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 1

                    Text {
                        text: Weather.ready ? Math.round(Weather.temp) + "°" : "··°"
                        color: Colors.fg
                        font.family: face.mono
                        font.pixelSize: 40
                        font.weight: Font.Light
                    }

                    Text {
                        text: Weather.text.toLowerCase()
                        color: Colors.fgDim
                        opacity: 0.75
                        font.family: face.mono
                        font.pixelSize: 11
                    }
                }
            }

            Grid {
                id: grid

                anchors.top: head.bottom
                anchors.topMargin: 18
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 20
                anchors.rightMargin: 20

                columns: 2
                columnSpacing: 12
                rowSpacing: 12

                Repeater {
                    model: [
                        { glyph: "󰔏", label: "feels", value: Math.round(Weather.feels) + "°" },
                        { glyph: "󰖌", label: "humid", value: Weather.humidity + "%" },
                        { glyph: "󰖝", label: "wind",  value: Math.round(Weather.wind) + " km/h" },
                        { glyph: "󰔐", label: "range",
                          value: face.today ? face.today.min + "° / " + face.today.max + "°" : "—" }
                    ]

                    Rectangle {
                        id: metric

                        required property var modelData

                        width: (grid.width - grid.columnSpacing) / 2
                        height: 52
                        radius: Shape.chip
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                       Colors.bgAlt.b, 0.35)

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: metric.modelData.glyph
                                color: Colors.accent
                                opacity: 0.8
                                font.family: face.mono
                                font.pixelSize: 16
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 1

                                Text {
                                    text: metric.modelData.value
                                    color: Colors.fg
                                    font.family: face.mono
                                    font.pixelSize: 13
                                }

                                Text {
                                    text: metric.modelData.label
                                    color: Colors.fgDim
                                    opacity: 0.5
                                    font.family: face.mono
                                    font.pixelSize: 9
                                    font.letterSpacing: 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: strip

        Row {
            spacing: 18

            Row {
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.glyph
                    color: Weather.tint
                    font.family: face.mono
                    font.pixelSize: 38
                    Behavior on color { ColorAnimation { duration: Colors.morph } }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.ready ? Math.round(Weather.temp) + "°" : "··°"
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 42
                    font.weight: Font.Light
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 1
                height: 34
                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.25)
            }

            Repeater {
                model: Weather.forecast

                Column {
                    required property var modelData
                    required property int index

                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(new Date(modelData.date), "ddd").toLowerCase()
                        color: Colors.fgDim
                        opacity: 0.55
                        font.family: face.mono
                        font.pixelSize: 10
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Weather.glyphFor(modelData.code, true)
                        color: Colors.fgDim
                        opacity: 0.8
                        font.family: face.mono
                        font.pixelSize: 18
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.max + "°"
                        color: index === 0 ? Colors.accent : Colors.fg
                        opacity: index === 0 ? 1 : 0.7
                        font.family: face.mono
                        font.pixelSize: 13
                    }
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
                value: Weather.ready ? face.part(Weather.temp) : 0
                color: face.heat(Weather.temp)
                trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                    Colors.fgDim.b, 0.14)
                thickness: 7
                inset: 4
            }

            Column {
                anchors.centerIn: parent
                spacing: -2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.glyph
                    color: Weather.tint
                    font.family: face.mono
                    font.pixelSize: 34
                    Behavior on color { ColorAnimation { duration: Colors.morph } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.ready ? Math.round(Weather.temp) + "°" : "··°"
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 40
                    font.weight: Font.Light
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Weather.city !== "" ? Weather.city.toLowerCase() : "…"
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: face.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }
            }
        }
    }

    Component {
        id: sky

        Rectangle {
            implicitWidth: 280
            implicitHeight: 200
            radius: Shape.card
            clip: true

            gradient: Gradient {
                GradientStop {
                    position: 0.0
                    color: Qt.rgba(Weather.tint.r, Weather.tint.g, Weather.tint.b, 0.38)
                }
                GradientStop {
                    position: 1.0
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.88)
                }
            }

            Text {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -14
                anchors.topMargin: -18
                text: Weather.glyph
                color: Colors.fg
                opacity: 0.16
                font.family: face.mono
                font.pixelSize: 150
            }

            Column {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 20
                spacing: 2

                Text {
                    text: Weather.ready ? Math.round(Weather.temp) + "°" : "··°"
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 58
                    font.weight: Font.Thin
                    font.letterSpacing: -2
                }

                Text {
                    text: Weather.text.toLowerCase()
                    color: Colors.fg
                    opacity: 0.8
                    font.family: face.mono
                    font.pixelSize: 12
                }

                Text {
                    text: Weather.city !== "" ? Weather.city.toLowerCase() : "…"
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: face.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
            }

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.14
            }
        }
    }

    Component {
        id: forecast

        Rectangle {
            implicitWidth: 290
            implicitHeight: days.implicitHeight + 40
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: days

                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 16

                Repeater {
                    model: Weather.forecast

                    Item {
                        id: dayRow

                        required property var modelData
                        required property int index

                        width: days.width
                        height: 34

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            text: Qt.formatDateTime(new Date(dayRow.modelData.date), "ddd")
                                    .toLowerCase()
                            color: Colors.fgDim
                            opacity: dayRow.index === 0 ? 0.9 : 0.55
                            font.family: face.mono
                            font.pixelSize: 11
                            font.letterSpacing: 1
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 46
                            anchors.top: parent.top
                            text: Weather.glyphFor(dayRow.modelData.code, true)
                            color: Colors.fgDim
                            opacity: 0.7
                            font.family: face.mono
                            font.pixelSize: 14
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            text: dayRow.modelData.min + "°  " + dayRow.modelData.max + "°"
                            color: dayRow.index === 0 ? Colors.accent : Colors.fg
                            opacity: dayRow.index === 0 ? 1 : 0.75
                            font.family: face.mono
                            font.pixelSize: 12
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.14)

                            Rectangle {
                                x: parent.width * face.part(dayRow.modelData.min)
                                width: Math.max(4, parent.width
                                    * (face.part(dayRow.modelData.max)
                                       - face.part(dayRow.modelData.min)))
                                height: parent.height
                                radius: parent.radius
                                color: face.heat(dayRow.modelData.max)
                                Behavior on width { NumberAnimation { duration: Motion.slow } }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: badge

        Rectangle {
            implicitWidth: pillRow.implicitWidth + 26
            implicitHeight: 40
            radius: height / 2
            antialiasing: true
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
            border.width: 1
            border.color: Qt.rgba(Weather.tint.r, Weather.tint.g,
                                  Weather.tint.b, 0.45)

            Row {
                id: pillRow

                anchors.centerIn: parent
                spacing: 9

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.glyph
                    color: Weather.tint
                    font.family: face.mono
                    font.pixelSize: 18
                    Behavior on color { ColorAnimation { duration: Colors.morph } }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Weather.ready ? Math.round(Weather.temp) + "°" : "··°"
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    Component {
        id: range

        Rectangle {
            implicitWidth: 300
            implicitHeight: 150
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 16

                Row {
                    width: parent.width

                    Text {
                        text: Weather.ready ? Math.round(Weather.temp) + "°" : "··°"
                        color: Colors.fg
                        font.family: face.mono
                        font.pixelSize: 44
                        font.weight: Font.Light
                    }

                    Item { width: parent.width - 150; height: 1 }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 8
                        text: Weather.glyph
                        color: Weather.tint
                        font.family: face.mono
                        font.pixelSize: 30
                        Behavior on color { ColorAnimation { duration: Colors.morph } }
                    }
                }

                Item {
                    width: parent.width
                    height: 26

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width
                        height: 6
                        radius: 3
                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                       Colors.fgDim.b, 0.14)
                    }

                    Rectangle {
                        visible: face.today !== null
                        anchors.verticalCenter: parent.verticalCenter
                        x: face.today ? parent.width * face.part(face.today.min) : 0
                        width: face.today
                            ? Math.max(6, parent.width * (face.part(face.today.max)
                                                          - face.part(face.today.min)))
                            : 0
                        height: 6
                        radius: 3
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Colors.accentAlt }
                            GradientStop { position: 1.0; color: Colors.accent }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        x: parent.width * face.part(Weather.temp) - 7
                        width: 14
                        height: 14
                        radius: 7
                        antialiasing: true
                        color: Colors.fg
                        border.width: 3
                        border.color: face.heat(Weather.temp)
                        Behavior on x { NumberAnimation { duration: Motion.slow } }
                    }
                }

                Row {
                    width: parent.width

                    Text {
                        text: face.today ? face.today.min + "° low" : ""
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: face.mono
                        font.pixelSize: 10
                    }

                    Item { width: parent.width - 160; height: 1 }

                    Text {
                        text: face.today ? face.today.max + "° high" : ""
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: face.mono
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
