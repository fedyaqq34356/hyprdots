import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "rings"

    readonly property bool bare: face.variant === "rings"
                              || face.variant === "digits"
                              || face.variant === "meters"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Component.onCompleted: Sys.acquire()
    Component.onDestruction: Sys.release()

    readonly property var metrics: [
        { label: "cpu", value: Sys.cpu, caption: Sys.cpuLabel },
        { label: "ram", value: Sys.mem, caption: Sys.memLabel },
        { label: "gpu", value: Sys.gpu, caption: Sys.gpuLabel }
    ]

    readonly property var allMetrics: [
        { label: "cpu",  value: Sys.cpu,     caption: Sys.cpuLabel,     glyph: "\uf4bc" },
        { label: "ram",  value: Sys.mem,     caption: Sys.memLabel,     glyph: "\udb80\udf5b" },
        { label: "gpu",  value: Sys.gpu,     caption: Sys.gpuLabel,     glyph: "\udb82\udcae" },
        { label: "vram", value: Sys.vram,    caption: Sys.vramLabel,    glyph: "\udb80\udf5b" },
        { label: "cpu \u00b0", value: Sys.temp,    caption: Sys.tempLabel,    glyph: "\udb80\ude9f" },
        { label: "gpu \u00b0", value: Sys.gputemp, caption: Sys.gputempLabel, glyph: "\udb80\ude9f" }
    ]

    function tone(v) {
        return v > 85 ? Colors.bad : v > 60 ? Colors.warn : Colors.accent;
    }

    Loader {
        id: loader
        sourceComponent: face.variant === "bars" ? bars
                       : face.variant === "digits" ? digits
                       : face.variant === "full" ? full
                       : face.variant === "meters" ? meters
                       : face.variant === "compact" ? compact
                       : rings
    }

    Component {
        id: rings

        Row {
            spacing: 22

            Repeater {
                model: face.metrics

                Item {
                    required property var modelData

                    width: 84
                    height: 84
                    visible: modelData.value >= 0

                    Ring {
                        anchors.fill: parent
                        value: modelData.value
                        label: modelData.caption
                        caption: modelData.label
                        thickness: 5
                        animationDuration: 700
                    }
                }
            }
        }
    }

    Component {
        id: digits

        Row {
            spacing: 26

            Repeater {
                model: face.metrics

                Column {
                    required property var modelData

                    spacing: -6
                    visible: modelData.value >= 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(modelData.value)
                        color: modelData.value > 85 ? Colors.bad
                             : modelData.value > 60 ? Colors.warn
                             : Colors.fg
                        opacity: 0.92
                        font.family: face.mono
                        font.pixelSize: 56
                        font.weight: Font.Thin
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: Colors.fgDim
                        opacity: 0.55
                        font.family: face.mono
                        font.pixelSize: 11
                        font.letterSpacing: 3
                    }
                }
            }
        }
    }

    Component {
        id: bars

        Rectangle {
            implicitWidth: 240
            implicitHeight: rows.implicitHeight + 30
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
                width: parent.width - 32
                spacing: 12

                Repeater {
                    model: face.metrics

                    Column {
                        required property var modelData

                        width: rows.width
                        spacing: 5
                        visible: modelData.value >= 0

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

                            Item { width: parent.width - 100; height: 1 }

                            Text {
                                text: modelData.caption
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
                                width: parent.width * Math.max(0, Math.min(1, modelData.value / 100))
                                height: parent.height
                                radius: parent.radius
                                color: modelData.value > 85 ? Colors.bad
                                     : modelData.value > 60 ? Colors.warn
                                     : Colors.accent

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
        id: full

        Rectangle {
            implicitWidth: 268
            implicitHeight: fullRows.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: fullRows
                anchors.centerIn: parent
                width: parent.width - 34
                spacing: 11

                Repeater {
                    model: face.allMetrics

                    Column {
                        required property var modelData

                        width: fullRows.width
                        spacing: 5
                        visible: modelData.value >= 0

                        Row {
                            width: parent.width

                            Text {
                                text: modelData.glyph
                                color: face.tone(modelData.value)
                                opacity: 0.9
                                font.family: face.mono
                                font.pixelSize: 11
                                Behavior on color { ColorAnimation { duration: Motion.base } }
                            }

                            Item { width: 8; height: 1 }

                            Text {
                                text: modelData.label
                                color: Colors.fgDim
                                opacity: 0.7
                                font.family: face.mono
                                font.pixelSize: 11
                                font.letterSpacing: 2
                            }

                            Item { width: parent.width - 130; height: 1 }

                            Text {
                                text: modelData.caption
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
                                width: parent.width * Math.max(0, Math.min(1, modelData.value / 100))
                                height: parent.height
                                radius: parent.radius
                                color: face.tone(modelData.value)

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
        id: meters

        Row {
            spacing: 16

            Repeater {
                model: face.allMetrics

                Column {
                    required property var modelData

                    spacing: 7
                    visible: modelData.value >= 0

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 12
                        height: 96

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                           Colors.outline.b, 0.18)
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            radius: 6
                            height: Math.max(width,
                                parent.height * Math.max(0, Math.min(1, modelData.value / 100)))
                            color: face.tone(modelData.value)

                            Behavior on height {
                                NumberAnimation {
                                    duration: Motion.slow
                                    easing.type: Easing.Bezier
                                    easing.bezierCurve: Motion.decel
                                }
                            }
                            Behavior on color { ColorAnimation { duration: Motion.base } }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(modelData.value)
                        color: Colors.fg
                        opacity: 0.9
                        font.family: face.mono
                        font.pixelSize: 13
                        font.weight: Font.Light
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
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

    Component {
        id: compact

        Rectangle {
            implicitWidth: 290
            implicitHeight: grid.implicitHeight + 30
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Grid {
                id: grid
                anchors.centerIn: parent
                columns: 2
                columnSpacing: 22
                rowSpacing: 12

                Repeater {
                    model: face.allMetrics

                    Row {
                        required property var modelData

                        spacing: 8
                        visible: modelData.value >= 0

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8
                            height: 8
                            radius: 4
                            antialiasing: true
                            color: face.tone(modelData.value)
                            Behavior on color { ColorAnimation { duration: Motion.base } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            text: modelData.label
                            color: Colors.fgDim
                            opacity: 0.65
                            font.family: face.mono
                            font.pixelSize: 10
                            font.letterSpacing: 1
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 62
                            horizontalAlignment: Text.AlignRight
                            text: modelData.caption
                            color: Colors.fg
                            font.family: face.mono
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
