import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property bool live: true

    property real ms: Date.now()
    FrameAnimation {
        running: face.live && face.visible
        onTriggered: face.ms = Date.now()
    }
    readonly property real ph: (face.ms % 48000) / 48000 * Math.PI * 2

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
        enabled: face.live
    }

    FileView {
        id: current
        path: Quickshell.env("HOME") + "/.config/hypr/current-wallpaper"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string wall: {
        const t = current.text().trim();
        return t !== "" ? "file://" + t : "";
    }

    Rectangle {
        anchors.fill: parent
        color: "black"
    }

    Image {
        id: wallImg
        anchors.fill: parent
        source: face.wall
        fillMode: Image.PreserveAspectCrop
        asynchronous: false
        cache: true
        sourceSize.width: 1920
        scale: 1.07 + 0.035 * Math.sin(face.ph)
        transform: Translate {
            x: 16 * Math.sin(face.ph * 2 + 0.6)
            y: 9 * Math.cos(face.ph * 2)
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.34) }
            GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.16) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.58) }
        }
    }

    RectangularShadow {
        x: face.width * (0.18 + 0.10 * Math.sin(face.ph * 3)) - 300
        y: face.height * (0.20 + 0.08 * Math.cos(face.ph * 2)) - 200
        width: 600
        height: 400
        radius: 200
        blur: 220
        color: Colors.alpha(Colors.accent, 0.22)
    }
    RectangularShadow {
        x: face.width * (0.78 + 0.08 * Math.cos(face.ph * 3 + 1)) - 320
        y: face.height * (0.62 + 0.10 * Math.sin(face.ph * 2 + 2)) - 220
        width: 640
        height: 440
        radius: 220
        blur: 240
        color: Colors.alpha(Colors.accentAlt, 0.16)
    }

    Column {
        id: stack
        anchors.horizontalCenter: parent.horizontalCenter
        y: face.height * 0.13
        spacing: -6

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "dddd, d MMMM")
            color: Qt.rgba(1, 1, 1, 0.82)
            font.family: Fonts.display
            font.pixelSize: 22
            font.weight: Font.Medium
            font.letterSpacing: 0.5
        }

        Row {
            id: digits
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: Qt.rgba(0, 0, 0, 0.35)
                shadowBlur: 0.8
                shadowVerticalOffset: 6
            }

            RollText {
                text: Qt.formatDateTime(clock.date, "HH")
                color: "white"
                family: Fonts.display
                pixelSize: 220
                weight: Font.DemiBold
                rollDuration: 700
                overshoot: 0.4
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -14
                text: ":"
                color: "white"
                opacity: 0.55 + 0.35 * (0.5 + 0.5 * Math.cos(face.ms / 1000 * Math.PI))
                font.family: Fonts.display
                font.pixelSize: 190
                font.weight: Font.DemiBold
            }

            RollText {
                text: Qt.formatDateTime(clock.date, "mm")
                color: "white"
                family: Fonts.display
                pixelSize: 220
                weight: Font.DemiBold
                rollDuration: 700
                overshoot: 0.4
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Weather.ready
            spacing: 8
            topPadding: 6

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.glyph
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: Fonts.glyph
                font.pixelSize: 17
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Weather.temp) + "°"
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: Fonts.display
                font.pixelSize: 17
                font.weight: Font.Medium
            }
        }
    }
}
