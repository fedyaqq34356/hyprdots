import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "ring"

    readonly property bool bare: face.variant === "ring"
                              || face.variant === "digits"
                              || face.variant === "minimal"
                              || face.variant === "arc"

    readonly property string mono: Fonts.mono

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    opacity: Timers.items.length > 0 ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    readonly property var soon: Timers.soonest

    readonly property int soonLeft: face.soon ? Timers.left(face.soon) : 0
    readonly property real soonPart: Timers.progress(face.soon)
    readonly property bool ringing: face.soon ? face.soon.ringing : false

    readonly property string soonLabel: face.soon && face.soon.label !== ""
        ? face.soon.label
        : (Timers.running > 1 ? I18n.count("timer.running", Timers.running) : "")

    readonly property color live: face.ringing
        ? Colors.bad
        : (face.soonLeft <= Math.max(3, Prefs.timerTickSec) && face.soonLeft > 0
            ? Colors.warn : Colors.accent)

    Loader {
        id: loader
        sourceComponent: face.variant === "list" ? list
                       : face.variant === "digits" ? digits
                       : face.variant === "bar" ? bar
                       : face.variant === "arc" ? arc
                       : face.variant === "sand" ? sand
                       : face.variant === "pills" ? pills
                       : face.variant === "stack" ? stack
                       : face.variant === "minimal" ? minimal
                       : face.variant === "grid" ? tiles
                       : ring
    }

    Component {
        id: ring

        TimerDial {
            id: dial

            implicitWidth: 190
            implicitHeight: 190
            width: 190
            height: 190

            readonly property int secs: face.soon ? Timers.left(face.soon) : 0

            progress: Timers.progress(face.soon)
            running: face.soon ? face.soon.running : false
            ringing: face.soon ? face.soon.ringing : false
            remaining: secs
            urgentAt: Math.max(3, Prefs.timerTickSec)
            thickness: 5

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Timers.clock(dial.secs)
                    color: dial.live
                    font.family: face.mono
                    font.pixelSize: 30
                    font.weight: Font.Medium
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 140
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: face.soon && face.soon.label !== ""
                        ? face.soon.label
                        : (Timers.running > 1
                            ? I18n.count("timer.running", Timers.running) : "")
                    color: Colors.fgDim
                    opacity: 0.7
                    font.family: Fonts.display
                    font.pixelSize: 12
                }
            }
        }
    }

    Component {
        id: list

        Rectangle {
            implicitWidth: 260
            implicitHeight: rows.implicitHeight + 28
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
                width: parent.width - 28
                spacing: 8

                Repeater {
                    model: Timers.items

                    Item {
                        required property var modelData

                        width: rows.width
                        height: 30

                        Rectangle {
                            anchors.fill: parent
                            radius: Shape.chip
                            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                           Colors.bgAlt.b, 0.35)
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: parent.width * Timers.progress(modelData)
                            radius: Shape.chip
                            color: modelData.ringing
                                ? Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.35)
                                : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b,
                                          modelData.running ? 0.22 : 0.08)
                            Behavior on width {
                                NumberAnimation { duration: 950; easing.type: Easing.Linear }
                            }
                        }

                        Text {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 90
                            elide: Text.ElideRight
                            text: modelData.label !== ""
                                ? modelData.label
                                : Timers.human(modelData.total)
                            color: Colors.fg
                            opacity: 0.85
                            font.family: Fonts.display
                            font.pixelSize: 12
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            text: Timers.clock(Timers.left(modelData))
                            color: modelData.ringing ? Colors.bad : Colors.fg
                            font.family: face.mono
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
    Component {
        id: digits

        Column {
            spacing: -4

            Text {
                text: Timers.clock(face.soonLeft)
                color: face.live
                font.family: face.mono
                font.pixelSize: 88
                font.weight: Font.Thin
                font.letterSpacing: -2
                Behavior on color { ColorAnimation { duration: Motion.base } }

                scale: face.ringing ? 1.03 : 1
                Behavior on scale {
                    NumberAnimation { duration: 420; easing.type: Easing.InOutSine }
                }

                SequentialAnimation on opacity {
                    running: face.ringing
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.55; duration: 520 }
                    NumberAnimation { to: 1.0;  duration: 520 }
                }
            }

            Text {
                text: face.soonLabel
                color: Colors.fgDim
                opacity: 0.65
                font.family: Fonts.display
                font.pixelSize: 15
            }
        }
    }

    Component {
        id: bar

        Rectangle {
            implicitWidth: 300
            implicitHeight: 108
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Row {
                    width: parent.width

                    Text {
                        text: Timers.clock(face.soonLeft)
                        color: face.live
                        font.family: face.mono
                        font.pixelSize: 34
                        font.weight: Font.Light
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Item { width: parent.width - 210; height: 1 }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        width: 130
                        horizontalAlignment: Text.AlignRight
                        elide: Text.ElideRight
                        text: face.soonLabel
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: Fonts.display
                        font.pixelSize: 12
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 6
                    radius: 3
                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.15)

                    Rectangle {
                        width: parent.width * (1 - face.soonPart)
                        height: parent.height
                        radius: parent.radius
                        color: face.live
                        Behavior on width {
                            NumberAnimation { duration: 950; easing.type: Easing.Linear }
                        }
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }
                }
            }
        }
    }

    Component {
        id: arc

        Item {
            implicitWidth: 240
            implicitHeight: 148

            Canvas {
                id: sweep

                anchors.fill: parent
                renderStrategy: Canvas.Cooperative
                antialiasing: true

                readonly property real part: face.soonPart
                readonly property color tint: face.live

                onPartChanged: sweep.requestPaint()
                onTintChanged: sweep.requestPaint()
                onWidthChanged: sweep.requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const cx = width / 2;
                    const cy = height - 16;
                    const r = Math.min(width / 2, height) - 16;

                    ctx.lineWidth = 12;
                    ctx.lineCap = "round";

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, Math.PI, Math.PI * 2);
                    ctx.strokeStyle = Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                              Colors.fgDim.b, 0.14);
                    ctx.stroke();

                    const left = 1 - Math.max(0, Math.min(1, sweep.part));
                    if (left <= 0.001)
                        return;

                    ctx.beginPath();
                    ctx.arc(cx, cy, r, Math.PI, Math.PI + Math.PI * left);
                    ctx.strokeStyle = sweep.tint;
                    ctx.stroke();
                }
            }

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 10
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Timers.clock(face.soonLeft)
                    color: face.live
                    font.family: face.mono
                    font.pixelSize: 34
                    font.weight: Font.Light
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 180
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: face.soonLabel
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: Fonts.display
                    font.pixelSize: 12
                }
            }
        }
    }

    Component {
        id: sand

        Rectangle {
            implicitWidth: 108
            implicitHeight: 240
            radius: Shape.field + 6
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.5)
            clip: true

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: parent.height * (1 - face.soonPart)
                color: Qt.rgba(face.live.r, face.live.g, face.live.b, 0.35)

                Behavior on height {
                    NumberAnimation { duration: 950; easing.type: Easing.Linear }
                }
                Behavior on color { ColorAnimation { duration: Motion.base } }

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 2
                    color: face.live
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Timers.clock(face.soonLeft)
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 22
                    font.weight: Font.Medium
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 88
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: face.soonLabel
                    color: Colors.fgDim
                    opacity: 0.65
                    font.family: Fonts.display
                    font.pixelSize: 11
                }
            }

            Sheen {
                anchors.fill: parent
                radius: Shape.field + 6
                edgeOpacity: 0.16
            }
        }
    }

    Component {
        id: pills

        Row {
            spacing: 8

            Repeater {
                model: Timers.items

                Rectangle {
                    id: pill

                    required property var modelData

                    width: 96
                    height: 42
                    radius: height / 2
                    antialiasing: true
                    clip: true
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
                    border.width: 1
                    border.color: modelData.ringing
                        ? Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.7)
                        : Qt.rgba(Colors.accent.r, Colors.accent.g,
                                  Colors.accent.b, modelData.running ? 0.5 : 0.2)

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: parent.width * (1 - Timers.progress(pill.modelData))
                        color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                       Colors.accent.b, 0.22)
                        Behavior on width {
                            NumberAnimation { duration: 950; easing.type: Easing.Linear }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Timers.clock(Timers.left(pill.modelData))
                        color: pill.modelData.ringing ? Colors.bad : Colors.fg
                        font.family: face.mono
                        font.pixelSize: 14
                    }
                }
            }
        }
    }

    Component {
        id: stack

        Row {
            spacing: 10

            Repeater {
                model: Timers.items

                Column {
                    id: bank

                    required property var modelData

                    spacing: 8

                    Rectangle {
                        width: 34
                        height: 150
                        radius: Shape.chip
                        clip: true
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.5)

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: parent.height * (1 - Timers.progress(bank.modelData))
                            radius: Shape.chip
                            color: bank.modelData.ringing ? Colors.bad : Colors.accent
                            opacity: bank.modelData.running ? 0.85 : 0.4
                            Behavior on height {
                                NumberAnimation { duration: 950; easing.type: Easing.Linear }
                            }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Timers.clock(Timers.left(bank.modelData))
                        color: Colors.fg
                        opacity: 0.85
                        font.family: face.mono
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    Component {
        id: minimal

        Row {
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: face.ringing ? "󰀟" : "󰔛"
                color: face.live
                font.family: face.mono
                font.pixelSize: 16
                Behavior on color { ColorAnimation { duration: Motion.base } }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Timers.clock(face.soonLeft)
                color: Colors.fg
                font.family: face.mono
                font.pixelSize: 24
                font.weight: Font.Light
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: text !== ""
                text: face.soonLabel
                color: Colors.fgDim
                opacity: 0.55
                font.family: Fonts.display
                font.pixelSize: 13
            }
        }
    }

    Component {
        id: tiles

        Grid {
            columns: 2
            columnSpacing: 10
            rowSpacing: 10

            Repeater {
                model: Timers.items

                Rectangle {
                    id: cell

                    required property var modelData

                    width: 116
                    height: 116
                    radius: Shape.field
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

                    Sheen {
                        anchors.fill: parent
                        radius: Shape.field
                        edgeOpacity: 0.12
                    }

                    ProgressRing {
                        anchors.fill: parent
                        anchors.margins: 12
                        value: 1 - Timers.progress(cell.modelData)
                        color: cell.modelData.ringing ? Colors.bad : Colors.accent
                        trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                            Colors.fgDim.b, 0.14)
                        thickness: 4
                        animationDuration: 950
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 1

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Timers.clock(Timers.left(cell.modelData))
                            color: cell.modelData.ringing ? Colors.bad : Colors.fg
                            font.family: face.mono
                            font.pixelSize: 15
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 88
                            horizontalAlignment: Text.AlignHCenter
                            elide: Text.ElideRight
                            text: cell.modelData.label
                            color: Colors.fgDim
                            opacity: 0.6
                            font.family: Fonts.display
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
