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

    readonly property string mono: "JetBrainsMono Nerd Font"

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
        sourceComponent: face.variant === "bar" ? bar : ring
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
}
