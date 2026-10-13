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

    Item {
        id: wallSrc
        anchors.fill: parent
        visible: false
        layer.enabled: true

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
    }

    Item {
        id: bgSrc
        anchors.fill: parent
        visible: false
        layer.enabled: true
        layer.smooth: true
        layer.textureSize: Qt.size(320, 180)

        Image {
            anchors.fill: parent
            source: face.wall
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: true
            smooth: true
            sourceSize.width: 480
            scale: wallImg.scale
            transform: Translate {
                x: 16 * Math.sin(face.ph * 2 + 0.6)
                y: 9 * Math.cos(face.ph * 2)
            }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: bgSrc
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 32
        blur: 1.0
        brightness: -0.22
        saturation: 0.25
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
            font.features: { "tnum": 1 }
            font.pixelSize: 22
            font.weight: Font.Medium
            font.letterSpacing: 0.5
        }

        Row {
            id: digits
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 8

            opacity: 0

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
                font.features: { "tnum": 1 }
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
                font.features: { "tnum": 1 }
                font.pixelSize: 17
                font.weight: Font.Medium
            }
        }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            readonly property var next: {
                Reminders.items;
                const now = face.ms;
                let best = null;
                for (const r of Reminders.items) {
                    if (r.done || r.at < now - 60000 || r.at - now > 36 * 3600000)
                        continue;
                    if (!best || r.at < best.at)
                        best = r;
                }
                return best;
            }
            visible: next !== null
            spacing: 8
            topPadding: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰂚"
                color: Qt.lighter(Colors.warn, 1.15)
                font.family: Fonts.glyph
                font.pixelSize: 15
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.next ? Qt.formatDateTime(new Date(parent.next.at), "HH:mm") : ""
                color: Qt.lighter(Colors.warn, 1.15)
                font.family: Fonts.display
                font.features: { "tnum": 1 }
                font.pixelSize: 16
                font.weight: Font.DemiBold
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: parent.next ? parent.next.title : ""
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: Fonts.display
                font.features: { "tnum": 1 }
                font.pixelSize: 16
            }
        }
    }

    Item {
        id: clockMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Row {
            x: stack.x + digits.x
            y: stack.y + digits.y
            spacing: digits.spacing

            RollText {
                text: Qt.formatDateTime(clock.date, "HH")
                color: "white"
                family: Fonts.display
                pixelSize: 220
                weight: Font.Bold
                rollDuration: 700
                overshoot: 0.4
            }
            Text {
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -14
                text: ":"
                color: "white"
                opacity: 0.55 + 0.45 * (0.5 + 0.5 * Math.cos(face.ms / 1000 * Math.PI))
                font.family: Fonts.display
                font.features: { "tnum": 1 }
                font.pixelSize: 190
                font.weight: Font.Bold
            }
            RollText {
                text: Qt.formatDateTime(clock.date, "mm")
                color: "white"
                family: Fonts.display
                pixelSize: 220
                weight: Font.Bold
                rollDuration: 700
                overshoot: 0.4
            }
        }
    }

    MultiEffect {
        anchors.fill: parent
        source: wallSrc
        autoPaddingEnabled: false
        maskEnabled: true
        maskSource: clockMask
        maskThresholdMin: 0.3
        maskSpreadAtMin: 0.3
        brightness: 0.24
        saturation: 0.7
        contrast: 0.22
        shadowEnabled: true
        shadowColor: Colors.alpha(Colors.accent, 0.55)
        shadowBlur: 1.0
        shadowVerticalOffset: 0
    }

    MultiEffect {
        anchors.fill: parent
        source: sheenSrc
        autoPaddingEnabled: false
        maskEnabled: true
        maskSource: clockMask
        maskThresholdMin: 0.3
        maskSpreadAtMin: 0.3
    }
    Item {
        id: sheenSrc
        anchors.fill: parent
        visible: false
        layer.enabled: true
        Rectangle {
            readonly property real k: ((face.ms % 30000) / 30000)
            width: 260
            height: face.height * 2
            rotation: 20
            y: -face.height / 2
            x: -400 + (face.width + 800) * Math.min(1, k * 3)
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.22) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
