import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "rings"

    readonly property bool bare: face.variant === "rings"

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

    Loader {
        id: loader
        sourceComponent: face.variant === "bars" ? bars : rings
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
}
