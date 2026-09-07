import Quickshell
import Quickshell.Services.UPower
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "ring"

    readonly property bool bare: face.variant === "ring"
                              || face.variant === "digits"
                              || face.variant === "dots"
                              || face.variant === "arc"

    readonly property string mono: Fonts.mono

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    readonly property var dev: UPower.displayDevice
    readonly property bool present: dev !== null && dev.isLaptopBattery
    readonly property int pct: face.dev ? Math.round(face.dev.percentage * 100) : 0
    readonly property bool charging:
        face.dev !== null && face.dev.state === UPowerDeviceState.Charging

    readonly property color tone: face.charging ? Colors.good
        : face.pct <= 12 ? Colors.bad
        : face.pct <= 25 ? Colors.warn
        : Colors.accent

    readonly property string remaining: {
        if (!face.dev || face.charging)
            return "";
        const t = face.dev.timeToEmpty;
        if (!t || t <= 0)
            return "";
        const h = Math.floor(t / 3600);
        const m = Math.floor((t % 3600) / 60);
        return (h > 0 ? h + I18n.t("unit.hourSpace") : "") + m + I18n.t("unit.min");
    }

    opacity: face.present ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    Loader {
        id: loader
        sourceComponent: face.variant === "bar" ? bar
                       : face.variant === "digits" ? digits
                       : face.variant === "cell" ? cell
                       : face.variant === "arc" ? arc
                       : face.variant === "pill" ? pill
                       : face.variant === "column" ? column
                       : face.variant === "dots" ? dots
                       : face.variant === "detail" ? detail
                       : face.variant === "wave" ? wave
                       : ring
    }

    Component {
        id: ring

        Item {
            implicitWidth: 150
            implicitHeight: 150

            Canvas {
                id: gauge

                anchors.fill: parent
                renderStrategy: Canvas.Cooperative
                antialiasing: true

                readonly property real p: face.pct / 100
                readonly property color c: face.tone

                onPChanged: gauge.requestPaint()
                onCChanged: gauge.requestPaint()
                onWidthChanged: gauge.requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const cx = width / 2;
                    const cy = height / 2;
                    const r = Math.min(cx, cy) - 8;
                    const from = Math.PI * 0.75;
                    const span = Math.PI * 1.5;

                    ctx.lineWidth = 7;
                    ctx.lineCap = "round";

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, from, from + span);
                    ctx.strokeStyle = Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                              Colors.fgDim.b, 0.14);
                    ctx.stroke();

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, from, from + span * gauge.p);
                    ctx.strokeStyle = gauge.c;
                    ctx.stroke();
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.charging ? "󰂄" : ""
                    color: Colors.good
                    visible: face.charging
                    font.family: face.mono
                    font.pixelSize: 14
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.pct
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 34
                    font.weight: Font.Light
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.remaining
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: face.mono
                    font.pixelSize: 10
                }
            }
        }
    }

    Component {
        id: bar

        Rectangle {
            implicitWidth: 230
            implicitHeight: 74
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 10

                Row {
                    width: parent.width

                    Text {
                        text: (face.charging ? "󰂄  " : "󰁹  ") + face.pct + "%"
                        color: face.tone
                        font.family: face.mono
                        font.pixelSize: 16
                    }

                    Item { width: parent.width - 170; height: 1 }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: face.remaining
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: face.mono
                        font.pixelSize: 11
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                   Colors.outline.b, 0.2)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1, face.pct / 100))
                        height: parent.height
                        radius: parent.radius
                        color: face.tone
                        Behavior on width { NumberAnimation { duration: Motion.slow } }
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }
                }
            }
        }
    }
    Component {
        id: digits

        Row {
            spacing: 10

            Text {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 16
                visible: face.charging
                text: "󰂄"
                color: Colors.good
                font.family: face.mono
                font.pixelSize: 30
            }

            Column {
                spacing: -8

                Row {
                    spacing: 4

                    Text {
                        text: face.pct
                        color: face.tone
                        font.family: face.mono
                        font.pixelSize: 86
                        font.weight: Font.Thin
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 14
                        text: "%"
                        color: Colors.fgDim
                        opacity: 0.5
                        font.family: face.mono
                        font.pixelSize: 24
                    }
                }

                Text {
                    text: face.remaining !== "" ? face.remaining : ""
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: face.mono
                    font.pixelSize: 13
                    font.letterSpacing: 2
                }
            }
        }
    }

    Component {
        id: cell

        Row {
            spacing: 5

            Rectangle {
                id: shell

                width: 190
                height: 84
                radius: 14
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.5)
                border.width: 2
                border.color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                      Colors.fgDim.b, 0.35)

                Rectangle {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    anchors.margins: 7
                    width: Math.max(6, (parent.width - 14) * face.pct / 100)
                    radius: 8
                    color: face.tone
                    opacity: 0.85

                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.slow
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.decel
                        }
                    }
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: face.charging
                        text: "󰚥"
                        color: Colors.fg
                        font.family: face.mono
                        font.pixelSize: 20
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: face.pct + "%"
                        color: Colors.fg
                        font.family: face.mono
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                    }
                }
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 8
                height: 28
                radius: 3
                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.35)
            }
        }
    }

    Component {
        id: arc

        Item {
            implicitWidth: 210
            implicitHeight: 130

            Canvas {
                id: half

                anchors.fill: parent
                renderStrategy: Canvas.Cooperative
                antialiasing: true

                readonly property int pct: face.pct
                readonly property color tint: face.tone

                onPctChanged: half.requestPaint()
                onTintChanged: half.requestPaint()
                onWidthChanged: half.requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const cx = width / 2;
                    const cy = height - 14;
                    const r = Math.min(width / 2, height) - 14;

                    ctx.lineWidth = 11;
                    ctx.lineCap = "round";

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, Math.PI, Math.PI * 2);
                    ctx.strokeStyle = Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                              Colors.fgDim.b, 0.14);
                    ctx.stroke();

                    if (half.pct <= 0)
                        return;

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, Math.PI,
                            Math.PI + Math.PI * (half.pct / 100));
                    ctx.strokeStyle = half.tint;
                    ctx.stroke();
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 6
                spacing: -2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.pct + "%"
                    color: face.tone
                    font.family: face.mono
                    font.pixelSize: 32
                    font.weight: Font.Light
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.charging ? I18n.t("act.charging") : face.remaining
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }

    Component {
        id: pill

        Rectangle {
            implicitWidth: chipRow.implicitWidth + 28
            implicitHeight: 40
            radius: height / 2
            antialiasing: true
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
            border.width: 1
            border.color: Qt.rgba(face.tone.r, face.tone.g, face.tone.b, 0.45)

            Row {
                id: chipRow

                anchors.centerIn: parent
                spacing: 8

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: face.charging ? "󰂄" : "󰁹"
                    color: face.tone
                    font.family: face.mono
                    font.pixelSize: 17
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: face.pct + "%"
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    Component {
        id: column

        Rectangle {
            implicitWidth: 74
            implicitHeight: 210
            radius: 16
            clip: true
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.5)
            border.width: 2
            border.color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.3)

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 6
                height: Math.max(8, (parent.height - 12) * face.pct / 100)
                radius: 12
                color: face.tone
                opacity: 0.8

                Behavior on height {
                    NumberAnimation {
                        duration: Motion.slow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.decel
                    }
                }
                Behavior on color { ColorAnimation { duration: Motion.base } }
            }

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: face.charging
                    text: "󰚥"
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 16
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.pct
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 26
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    Component {
        id: dots

        Row {
            spacing: 7

            Repeater {
                model: 10

                Rectangle {
                    required property int index

                    readonly property bool lit: (index + 1) * 10 <= face.pct

                    width: 16
                    height: 16
                    radius: 8
                    antialiasing: true
                    color: lit ? face.tone
                         : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.16)

                    Behavior on color { ColorAnimation { duration: Motion.base } }

                    scale: lit ? 1 : 0.7
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

    Component {
        id: detail

        Rectangle {
            implicitWidth: 280
            implicitHeight: 128
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 13

                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        anchors.bottom: parent.bottom
                        text: face.pct + "%"
                        color: face.tone
                        font.family: face.mono
                        font.pixelSize: 36
                        font.weight: Font.Light
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        text: face.charging ? "󰂄" : "󰁹"
                        color: face.tone
                        opacity: 0.8
                        font.family: face.mono
                        font.pixelSize: 18
                    }

                    Item { width: parent.width - 220; height: 1 }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 7
                        text: face.charging
                            ? I18n.t("act.charging")
                            : (face.remaining !== "" ? face.remaining : "")
                        color: Colors.fgDim
                        opacity: 0.65
                        font.family: face.mono
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 8
                    radius: 4
                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.15)

                    Rectangle {
                        width: parent.width * face.pct / 100
                        height: parent.height
                        radius: parent.radius
                        color: face.tone
                        Behavior on width { NumberAnimation { duration: Motion.slow } }
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Rectangle {
                        x: parent.width * 0.12 - 1
                        width: 2
                        height: parent.height
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.8)
                    }
                }

                Text {
                    text: face.dev && face.dev.timeToEmpty > 0 && !face.charging
                        ? I18n.t("desk.battery") + "  ·  " + face.remaining
                        : I18n.t("desk.battery")
                    color: Colors.fgDim
                    opacity: 0.45
                    font.family: face.mono
                    font.pixelSize: 10
                    font.letterSpacing: 2
                }
            }
        }
    }

    Component {
        id: wave

        Rectangle {
            implicitWidth: 168
            implicitHeight: 168
            radius: width / 2
            antialiasing: true
            clip: true
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
            border.width: 2
            border.color: Qt.rgba(face.tone.r, face.tone.g, face.tone.b, 0.5)

            WaveMeter {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height
                value: face.pct / 100
                fillColor: Qt.rgba(face.tone.r, face.tone.g, face.tone.b, 0.55)
                trackColor: "transparent"
                animating: face.charging
                wavelength: 60
            }

            Column {
                anchors.centerIn: parent
                spacing: -2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.pct
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 42
                    font.weight: Font.Light
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.charging ? "󰚥" : (face.remaining !== "" ? face.remaining : "%")
                    color: Colors.fgDim
                    opacity: 0.7
                    font.family: face.mono
                    font.pixelSize: 12
                }
            }
        }
    }
}
