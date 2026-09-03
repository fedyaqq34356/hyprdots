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
}
