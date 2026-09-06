import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "bars"

    readonly property bool bare: true

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    opacity: Media.playing ? 1 : 0.22
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    Loader {
        id: loader
        sourceComponent: face.variant === "wave" ? wave
                       : face.variant === "radial" ? radial
                       : face.variant === "mirror" ? mirror
                       : face.variant === "dots" ? dots
                       : bars
    }

    Component {
        id: bars

        Spectrum {
            implicitWidth: 340
            implicitHeight: 120
            mode: "bars"
            tint: Colors.accent
        }
    }

    Component {
        id: wave

        Spectrum {
            implicitWidth: 360
            implicitHeight: 130
            mode: "wave"
            mirror: true
            tint: Colors.accent
            resolution: 64
        }
    }

    Component {
        id: radial

        Item {
            implicitWidth: 230
            implicitHeight: 230

            Spectrum {
                anchors.fill: parent
                mode: "radial"
                tint: Colors.accent
                hole: 0.5
                resolution: 60
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * (0.30 + Beat.pulse * 0.06)
                height: width
                radius: width / 2
                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b,
                               0.10 + Beat.pulse * 0.35)
                antialiasing: true
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.36
                height: width
                radius: width / 2
                color: "transparent"
                antialiasing: true
                border.width: 1
                border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                      Colors.accent.b, 0.2 + Beat.level * 0.5)
                scale: 1 + Beat.bass * 0.10
            }
        }
    }

    Component {
        id: mirror

        Item {
            implicitWidth: 340
            implicitHeight: 140

            Row {
                anchors.centerIn: parent
                spacing: 3

                readonly property real cell:
                    (parent.width - spacing * (Cava.bars * 2 - 1)) / (Cava.bars * 2)

                Repeater {
                    model: Cava.bars * 2

                    Rectangle {
                        required property int index

                        readonly property real level: {
                            const l = Cava.levels;
                            const n = l ? l.length : 0;
                            if (n === 0) return 0;
                            const i = index < n ? (n - 1 - index) : (index - n);
                            const v = l[Math.max(0, Math.min(n - 1, i))];
                            return v === undefined ? 0 : v;
                        }

                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.cell
                        radius: width / 2
                        antialiasing: true
                        height: Math.max(width, level * 132)

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                               Colors.accent.b, 0.35)
                            }
                            GradientStop {
                                position: 0.5
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                               Colors.accent.b, 0.95)
                            }
                            GradientStop {
                                position: 1.0
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                               Colors.accent.b, 0.35)
                            }
                        }

                        Behavior on height {
                            NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dots

        Item {
            implicitWidth: 300
            implicitHeight: 120

            readonly property int rows: 7

            Row {
                id: field
                anchors.centerIn: parent
                spacing: 8

                Repeater {
                    model: Cava.bars

                    Column {
                        required property int index
                        spacing: 8

                        readonly property real level: {
                            const v = Cava.levels[index];
                            return v === undefined ? 0 : v;
                        }

                        Repeater {
                            model: 7

                            Rectangle {
                                required property int index

                                readonly property real threshold:
                                    (7 - index - 1) / 7

                                width: 9
                                height: 9
                                radius: 4.5
                                antialiasing: true
                                color: Colors.accent
                                opacity: parent.level > threshold ? 0.95 : 0.10

                                Behavior on opacity {
                                    NumberAnimation { duration: 110 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
