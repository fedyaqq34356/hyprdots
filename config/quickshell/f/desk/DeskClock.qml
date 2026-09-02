import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"

Item {
    id: face

    property string variant: "minimal"

    readonly property bool bare: true

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: body.implicitWidth
    implicitHeight: body.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string time: Qt.formatDateTime(clock.date, "HH:mm")
    readonly property string hh: Qt.formatDateTime(clock.date, "HH")
    readonly property string mm: Qt.formatDateTime(clock.date, "mm")
    readonly property string date:
        Qt.formatDateTime(clock.date, "dddd, d MMMM").toLowerCase()

    Item {
        id: body
        implicitWidth: loader.implicitWidth
        implicitHeight: loader.implicitHeight

        Loader {
            id: loader
            sourceComponent: face.variant === "digital" ? digital
                           : face.variant === "hand" ? hand
                           : minimal
        }
    }

    Component {
        id: minimal

        Column {
            spacing: -22

            Repeater {
                model: [face.hh, face.mm]

                Item {
                    required property string modelData
                    required property int index

                    implicitWidth: glyph.implicitWidth
                    implicitHeight: glyph.implicitHeight * 0.82

                    Text {
                        text: modelData
                        font: glyph.font
                        color: Qt.rgba(0, 0, 0, 0.35)
                        x: 2
                        y: 4
                    }

                    Text {
                        id: glyph
                        text: modelData
                        color: index === 0 ? Colors.fg : Colors.accent
                        opacity: index === 0 ? 0.92 : 0.85
                        font.family: face.mono
                        font.pixelSize: 132
                        font.weight: Font.Thin
                        font.letterSpacing: -6

                        Behavior on color { ColorAnimation { duration: Colors.morph } }
                    }
                }
            }
        }
    }

    Component {
        id: digital

        Column {
            spacing: 8

            Text {
                text: face.time
                color: Colors.fg
                font.family: face.mono
                font.pixelSize: 64
                font.weight: Font.Light
                font.letterSpacing: 2
                Behavior on color { ColorAnimation { duration: Colors.morph } }
            }

            Rectangle {
                width: parent.width
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.75) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Text {
                text: face.date
                color: Colors.fgDim
                opacity: 0.75
                font.family: face.mono
                font.pixelSize: 13
                font.letterSpacing: 3
            }
        }
    }

    Component {
        id: hand

        HandClock {
            text: face.time
            color: Colors.fg
            thickness: 3
            glyphWidth: 62
            glyphHeight: 104
            spacing: 14
        }
    }
}
