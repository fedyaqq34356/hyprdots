import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "bars"

    readonly property bool bare: face.variant === "dots"

    readonly property string mono: "JetBrainsMono Nerd Font"

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

    Loader {
        id: loader
        sourceComponent: face.variant === "dots" ? dots : bars
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
}
