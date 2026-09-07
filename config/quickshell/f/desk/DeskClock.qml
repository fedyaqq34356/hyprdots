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

    SystemClock {
        id: fine
        enabled: face.variant === "ring" || face.variant === "orbit"
                 || face.variant === "bar" || face.variant === "binary"
        precision: SystemClock.Seconds
    }

    readonly property string time: Qt.formatDateTime(clock.date, "HH:mm")
    readonly property string hh: Qt.formatDateTime(clock.date, "HH")
    readonly property string mm: Qt.formatDateTime(clock.date, "mm")
    readonly property string date:
        Qt.formatDateTime(clock.date, "dddd, d MMMM").toLowerCase()

    readonly property real dayPart: {
        const d = clock.date;
        return (d.getHours() * 3600 + d.getMinutes() * 60 + d.getSeconds()) / 86400;
    }

    readonly property var hourNames: [
        "twelve", "one", "two", "three", "four", "five", "six",
        "seven", "eight", "nine", "ten", "eleven"
    ]

    readonly property var minuteNames: [
        "o'clock", "five past", "ten past", "quarter past", "twenty past",
        "twenty five past", "half past", "twenty five to", "twenty to",
        "quarter to", "ten to", "five to"
    ]

    readonly property string spokenHead: {
        const m = clock.date.getMinutes();
        const slot = Math.round(m / 5) % 12;
        return face.minuteNames[slot];
    }

    readonly property string spokenHour: {
        const d = clock.date;
        const slot = Math.round(d.getMinutes() / 5) % 12;
        const h = slot > 6 || (slot === 0 && d.getMinutes() > 30)
            ? d.getHours() + 1 : d.getHours();
        return face.hourNames[h % 12];
    }

    Item {
        id: body
        implicitWidth: loader.implicitWidth
        implicitHeight: loader.implicitHeight

        Loader {
            id: loader
            sourceComponent: face.variant === "digital" ? digital
                           : face.variant === "hand" ? hand
                           : face.variant === "ring" ? rings
                           : face.variant === "flip" ? flip
                           : face.variant === "roll" ? roll
                           : face.variant === "words" ? words
                           : face.variant === "binary" ? binary
                           : face.variant === "orbit" ? orbit
                           : face.variant === "bar" ? bar
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
        id: rings

        Item {
            implicitWidth: 200
            implicitHeight: 200

            Canvas {
                id: dial

                anchors.fill: parent
                renderStrategy: Canvas.Cooperative
                antialiasing: true

                readonly property var at: fine.date
                readonly property color hue: Colors.accent

                onAtChanged: dial.requestPaint()
                onHueChanged: dial.requestPaint()
                onWidthChanged: dial.requestPaint()

                function ring(ctx, r, part, color, width) {
                    const cx = dial.width / 2;
                    const cy = dial.height / 2;
                    const start = -Math.PI / 2;

                    ctx.lineWidth = width;
                    ctx.lineCap = "round";

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                    ctx.strokeStyle = Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                              Colors.fgDim.b, 0.12);
                    ctx.stroke();

                    if (part <= 0)
                        return;

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, start, start + Math.PI * 2 * part);
                    ctx.strokeStyle = color;
                    ctx.stroke();
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const d = dial.at;
                    const r = Math.min(width, height) / 2;
                    const s = d.getSeconds() / 60;
                    const m = (d.getMinutes() + s) / 60;
                    const h = ((d.getHours() % 12) + m) / 12;

                    dial.ring(ctx, r - 10, h, dial.hue, 8);
                    dial.ring(ctx, r - 26, m, Colors.accentAlt, 6);
                    dial.ring(ctx, r - 40, s,
                              Qt.rgba(Colors.fg.r, Colors.fg.g, Colors.fg.b, 0.55), 3);
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.time
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 30
                    font.weight: Font.Light
                    font.letterSpacing: 1
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "ddd d").toLowerCase()
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: face.mono
                    font.pixelSize: 11
                }
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

    Component {
        id: flip

        Row {
            spacing: 12

            Repeater {
                model: [face.hh, face.mm]

                Rectangle {
                    id: pane

                    required property string modelData
                    required property int index

                    width: 132
                    height: 148
                    radius: Shape.field + 4
                    antialiasing: true
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.72)
                    border.width: 1
                    border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                          Colors.outline.b, 0.25)

                    Sheen {
                        anchors.fill: parent
                        radius: parent.radius
                        border: false
                    }

                    Text {
                        id: digits

                        anchors.centerIn: parent
                        text: pane.modelData
                        color: pane.index === 0 ? Colors.fg : Colors.accent
                        font.family: face.mono
                        font.pixelSize: 96
                        font.weight: Font.Light
                        font.letterSpacing: -2

                        Behavior on color { ColorAnimation { duration: Colors.morph } }

                        transform: Scale {
                            id: drop
                            origin.x: digits.width / 2
                            origin.y: digits.height / 2
                            yScale: 1
                        }

                        onTextChanged: fall.restart()

                        SequentialAnimation {
                            id: fall
                            NumberAnimation {
                                target: drop; property: "yScale"
                                from: 0.35; to: 1.04
                                duration: Motion.base
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.decel
                            }
                            NumberAnimation {
                                target: drop; property: "yScale"; to: 1
                                duration: Motion.fast
                            }
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.right: parent.right
                        height: 1
                        color: Qt.rgba(0, 0, 0, 0.45)
                    }
                }
            }
        }
    }

    Component {
        id: roll

        Column {
            spacing: 10

            RollText {
                text: face.time
                color: Colors.fg
                family: face.mono
                pixelSize: 78
                weight: Font.Light
                rollDuration: 420
            }

            Row {
                spacing: 10

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 26
                    height: 2
                    radius: 1
                    color: Colors.accent
                }

                Text {
                    text: face.date
                    color: Colors.fgDim
                    opacity: 0.7
                    font.family: face.mono
                    font.pixelSize: 12
                    font.letterSpacing: 2
                }
            }
        }
    }

    Component {
        id: words

        Column {
            spacing: -4

            Text {
                text: face.spokenHead
                color: Colors.fgDim
                opacity: 0.75
                font.family: Fonts.display
                font.pixelSize: 34
                font.weight: Font.Light
            }

            Text {
                text: face.spokenHour
                color: Colors.accent
                font.family: Fonts.display
                font.pixelSize: 72
                font.weight: Font.DemiBold
                Behavior on color { ColorAnimation { duration: Colors.morph } }
            }

            Text {
                topPadding: 12
                text: face.date
                color: Colors.fgDim
                opacity: 0.5
                font.family: face.mono
                font.pixelSize: 11
                font.letterSpacing: 2
            }
        }
    }

    Component {
        id: binary

        Column {
            spacing: 14

            Row {
                spacing: 14

                Repeater {
                    model: {
                        const d = fine.date;
                        const two = n => [Math.floor(n / 10), n % 10];
                        return two(d.getHours())
                            .concat(two(d.getMinutes()))
                            .concat(two(d.getSeconds()));
                    }

                    Column {
                        id: bits

                        required property var modelData
                        required property int index

                        readonly property int digit: modelData
                        readonly property bool second: index > 3

                        spacing: 9

                        Repeater {
                            model: [8, 4, 2, 1]

                            Rectangle {
                                required property int modelData

                                readonly property bool lit:
                                    (bits.digit & modelData) !== 0

                                width: 16
                                height: 16
                                radius: 8
                                antialiasing: true

                                color: lit
                                    ? (bits.second ? Colors.accentAlt : Colors.accent)
                                    : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                              Colors.fgDim.b, 0.14)
                                opacity: lit ? (bits.second ? 0.75 : 1) : 1

                                Behavior on color { ColorAnimation { duration: Motion.base } }

                                scale: lit ? 1 : 0.62
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: Motion.base
                                        easing.type: Easing.Bezier
                                        easing.bezierCurve: Motion.snap
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                text: Qt.formatDateTime(fine.date, "HH:mm:ss")
                color: Colors.fgDim
                opacity: 0.45
                font.family: face.mono
                font.pixelSize: 12
                font.letterSpacing: 4
            }
        }
    }

    Component {
        id: orbit

        Item {
            implicitWidth: 210
            implicitHeight: 210

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                antialiasing: true
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.35)
                border.width: 1
                border.color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                      Colors.fgDim.b, 0.16)
            }

            Repeater {
                model: 12

                Item {
                    required property int index
                    anchors.fill: parent
                    rotation: index * 30

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        width: 2
                        height: index % 3 === 0 ? 10 : 5
                        radius: 1
                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                       Colors.fgDim.b, index % 3 === 0 ? 0.5 : 0.25)
                    }
                }
            }

            Item {
                anchors.fill: parent
                rotation: fine.date.getSeconds() * 6

                Behavior on rotation {
                    enabled: rotation > 0
                    NumberAnimation {
                        duration: Motion.base
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.snap
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    width: 14
                    height: 14
                    radius: 7
                    antialiasing: true
                    color: Colors.accent
                    Behavior on color { ColorAnimation { duration: Colors.morph } }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.time
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 42
                    font.weight: Font.Light
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(clock.date, "ddd d MMM").toLowerCase()
                    color: Colors.fgDim
                    opacity: 0.55
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }

    Component {
        id: bar

        Column {
            spacing: 12

            Row {
                spacing: 12

                Text {
                    anchors.bottom: parent.bottom
                    text: face.time
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 54
                    font.weight: Font.Light
                }

                Text {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 8
                    text: Math.round(face.dayPart * 100) + "%"
                    color: Colors.accent
                    opacity: 0.8
                    font.family: face.mono
                    font.pixelSize: 15
                }
            }

            Item {
                width: 340
                height: 12

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    height: 4
                    radius: 2
                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.18)
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * face.dayPart
                    height: 4
                    radius: 2
                    color: Colors.accent
                    Behavior on width { NumberAnimation { duration: Motion.slow } }
                }

                Repeater {
                    model: [0.25, 0.5, 0.75]

                    Rectangle {
                        required property real modelData
                        x: parent.width * modelData - 1
                        anchors.verticalCenter: parent.verticalCenter
                        width: 2
                        height: 12
                        radius: 1
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.85)
                    }
                }

                Rectangle {
                    x: parent.width * face.dayPart - 5
                    anchors.verticalCenter: parent.verticalCenter
                    width: 10
                    height: 10
                    radius: 5
                    antialiasing: true
                    color: Colors.accent
                    Behavior on x { NumberAnimation { duration: Motion.slow } }
                }
            }

            Text {
                text: face.date
                color: Colors.fgDim
                opacity: 0.5
                font.family: face.mono
                font.pixelSize: 11
                font.letterSpacing: 2
            }
        }
    }
}
