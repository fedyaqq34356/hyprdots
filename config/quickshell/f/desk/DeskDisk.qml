import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "bars"

    readonly property bool bare: face.variant === "dots"
                              || face.variant === "list"
                              || face.variant === "gauge"

    readonly property string mono: Fonts.mono

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Component.onCompleted: Disk.acquire()
    Component.onDestruction: Disk.release()

    opacity: Disk.mounts.length > 0 ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    function tone(percent) {
        return percent > 92 ? Colors.bad
             : percent > 78 ? Colors.warn
             : Colors.accent;
    }

    readonly property var main: Disk.mounts.length > 0 ? Disk.mounts[0] : null

    Loader {
        id: loader
        sourceComponent: face.variant === "dots" ? dots
                       : face.variant === "rings" ? rings
                       : face.variant === "grid" ? tiles
                       : face.variant === "column" ? column
                       : face.variant === "list" ? plain
                       : face.variant === "donut" ? donut
                       : face.variant === "gauge" ? gauge
                       : face.variant === "stack" ? stack
                       : face.variant === "compact" ? compact
                       : bars
    }

    Component {
        id: bars

        Rectangle {
            implicitWidth: 260
            implicitHeight: rows.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: rows
                anchors.centerIn: parent
                width: parent.width - 34
                spacing: 13

                Repeater {
                    model: Disk.mounts

                    Column {
                        required property var modelData

                        width: rows.width
                        spacing: 5

                        Row {
                            width: parent.width

                            Text {
                                text: modelData.label
                                color: Colors.fgDim
                                opacity: 0.7
                                font.family: face.mono
                                font.pixelSize: 11
                                font.letterSpacing: 2
                            }

                            Item { width: parent.width - 120; height: 1 }

                            Text {
                                text: Disk.human(modelData.free)
                                color: Colors.fg
                                font.family: face.mono
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                           Colors.outline.b, 0.2)

                            Rectangle {
                                width: parent.width * modelData.percent / 100
                                height: parent.height
                                radius: parent.radius
                                color: face.tone(modelData.percent)

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Motion.slow
                                        easing.type: Easing.Bezier
                                        easing.bezierCurve: Motion.decel
                                    }
                                }
                                Behavior on color { ColorAnimation { duration: Motion.base } }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dots

        Row {
            spacing: 30

            Repeater {
                model: Disk.mounts

                Column {
                    required property var modelData

                    spacing: 4

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 9
                            height: 9
                            radius: 4.5
                            antialiasing: true
                            color: face.tone(modelData.percent)
                            Behavior on color { ColorAnimation { duration: Motion.base } }
                        }

                        Text {
                            text: Disk.human(modelData.free)
                            color: Colors.fg
                            opacity: 0.92
                            font.family: face.mono
                            font.pixelSize: 34
                            font.weight: Font.Thin
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: Colors.fgDim
                        opacity: 0.55
                        font.family: face.mono
                        font.pixelSize: 10
                        font.letterSpacing: 3
                    }
                }
            }
        }
    }
    Component {
        id: rings

        Row {
            spacing: 18

            Repeater {
                model: Disk.mounts

                Item {
                    id: mountRing

                    required property var modelData

                    width: 96
                    height: 96

                    ProgressRing {
                        anchors.fill: parent
                        value: mountRing.modelData.percent / 100
                        color: face.tone(mountRing.modelData.percent)
                        trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                            Colors.fgDim.b, 0.14)
                        thickness: 5
                        inset: 3
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: -2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Math.round(mountRing.modelData.percent) + "%"
                            color: Colors.fg
                            font.family: face.mono
                            font.pixelSize: 18
                            font.weight: Font.Light
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 76
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: mountRing.modelData.label
                            color: Colors.fgDim
                            opacity: 0.6
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
        id: tiles

        Rectangle {
            implicitWidth: 300
            implicitHeight: quad.implicitHeight + 36
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Grid {
                id: quad

                anchors.centerIn: parent
                width: parent.width - 36
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: Disk.mounts

                    Rectangle {
                        id: mountTile

                        required property var modelData

                        width: (quad.width - quad.columnSpacing) / 2
                        height: 74
                        radius: Shape.field
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                       Colors.bgAlt.b, 0.35)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 5

                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                text: mountTile.modelData.label
                                color: Colors.fgDim
                                opacity: 0.65
                                font.family: face.mono
                                font.pixelSize: 10
                                font.letterSpacing: 1
                            }

                            Text {
                                text: Disk.human(mountTile.modelData.free)
                                color: Colors.fg
                                font.family: face.mono
                                font.pixelSize: 17
                                font.weight: Font.Light
                            }

                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.14)

                                Rectangle {
                                    width: parent.width * mountTile.modelData.percent / 100
                                    height: parent.height
                                    radius: parent.radius
                                    color: face.tone(mountTile.modelData.percent)
                                    Behavior on width { NumberAnimation { duration: Motion.slow } }
                                    Behavior on color { ColorAnimation { duration: Motion.base } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: column

        Row {
            spacing: 14

            Repeater {
                model: Disk.mounts

                Column {
                    id: bank

                    required property var modelData

                    spacing: 8

                    Rectangle {
                        width: 46
                        height: 150
                        radius: Shape.chip
                        clip: true
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.5)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: parent.height * bank.modelData.percent / 100
                            radius: Shape.chip
                            color: face.tone(bank.modelData.percent)
                            opacity: 0.8

                            Behavior on height { NumberAnimation { duration: Motion.slow } }
                            Behavior on color { ColorAnimation { duration: Motion.base } }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.top
                            anchors.topMargin: 8
                            text: Math.round(bank.modelData.percent)
                            color: Colors.fg
                            opacity: 0.85
                            font.family: face.mono
                            font.pixelSize: 13
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 46
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: bank.modelData.label
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
        id: plain

        Column {
            spacing: 8

            Repeater {
                model: Disk.mounts

                Row {
                    id: plainRow

                    required property var modelData

                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 90
                        elide: Text.ElideRight
                        text: plainRow.modelData.label
                        color: Colors.fg
                        opacity: 0.85
                        font.family: Fonts.display
                        font.pixelSize: 15
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Disk.human(plainRow.modelData.free)
                        color: face.tone(plainRow.modelData.percent)
                        font.family: face.mono
                        font.pixelSize: 15
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "/ " + Disk.human(plainRow.modelData.total)
                        color: Colors.fgDim
                        opacity: 0.5
                        font.family: face.mono
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    Component {
        id: donut

        Item {
            implicitWidth: 190
            implicitHeight: 190

            ProgressRing {
                anchors.fill: parent
                value: face.main ? face.main.percent / 100 : 0
                color: face.main ? face.tone(face.main.percent) : Colors.accent
                trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.14)
                thickness: 12
                inset: 4
            }

            Column {
                anchors.centerIn: parent
                spacing: -2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.main ? Disk.human(face.main.free) : "—"
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 28
                    font.weight: Font.Light
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: I18n.t("desk.disk")
                    color: Colors.fgDim
                    opacity: 0.55
                    font.family: face.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
            }
        }
    }

    Component {
        id: gauge

        Column {
            spacing: -4

            Text {
                text: face.main ? Disk.human(face.main.free) : "—"
                color: Colors.fg
                font.family: face.mono
                font.pixelSize: 64
                font.weight: Font.Thin
            }

            Row {
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: face.main ? face.main.label : ""
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: face.mono
                    font.pixelSize: 12
                    font.letterSpacing: 2
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 120
                    height: 4
                    radius: 2
                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.16)

                    Rectangle {
                        width: parent.width * (face.main ? face.main.percent / 100 : 0)
                        height: parent.height
                        radius: parent.radius
                        color: face.main ? face.tone(face.main.percent) : Colors.accent
                        Behavior on width { NumberAnimation { duration: Motion.slow } }
                    }
                }
            }
        }
    }

    Component {
        id: stack

        Rectangle {
            id: whole

            readonly property real totalKb: {
                let n = 0;
                for (const m of Disk.mounts) n += m.total;
                return Math.max(1, n);
            }

            implicitWidth: 300
            implicitHeight: 112
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: stackBody

                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Row {
                    width: parent.width

                    Text {
                        text: I18n.t("desk.disk")
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: face.mono
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }

                    Item { width: parent.width - 150; height: 1 }

                    Text {
                        text: Disk.human(whole.totalKb)
                        color: Colors.fg
                        opacity: 0.8
                        font.family: face.mono
                        font.pixelSize: 11
                    }
                }

                Row {
                    width: parent.width
                    height: 14
                    spacing: 3

                    Repeater {
                        model: Disk.mounts

                        Rectangle {
                            id: slice

                            required property var modelData
                            required property int index

                            width: Math.max(4, (stackBody.width - 9)
                                * modelData.used / whole.totalKb)
                            height: parent.height
                            radius: Shape.detail
                            color: index === 0
                                ? Colors.accent
                                : Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                          Colors.accentAlt.b, 0.85 - index * 0.15)

                            Behavior on width { NumberAnimation { duration: Motion.slow } }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: Disk.mounts

                        Row {
                            id: key

                            required property var modelData
                            required property int index

                            spacing: 5

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7
                                height: 7
                                radius: 2
                                color: key.index === 0
                                    ? Colors.accent
                                    : Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                              Colors.accentAlt.b, 0.85 - key.index * 0.15)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: key.modelData.label
                                color: Colors.fgDim
                                opacity: 0.65
                                font.family: face.mono
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: compact

        Rectangle {
            implicitWidth: 168
            implicitHeight: 54
            radius: Shape.field
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.5)

            Sheen {
                anchors.fill: parent
                radius: Shape.field
                edgeOpacity: 0.14
            }

            Row {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰋊"
                    color: face.main ? face.tone(face.main.percent) : Colors.accent
                    font.family: face.mono
                    font.pixelSize: 18
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 40
                    spacing: 4

                    Text {
                        text: face.main ? Disk.human(face.main.free) + " free" : "—"
                        color: Colors.fg
                        font.family: face.mono
                        font.pixelSize: 13
                    }

                    Rectangle {
                        width: parent.width
                        height: 3
                        radius: 1.5
                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.16)

                        Rectangle {
                            width: parent.width * (face.main ? face.main.percent / 100 : 0)
                            height: parent.height
                            radius: parent.radius
                            color: face.main ? face.tone(face.main.percent) : Colors.accent
                            Behavior on width { NumberAnimation { duration: Motion.slow } }
                        }
                    }
                }
            }
        }
    }
}
