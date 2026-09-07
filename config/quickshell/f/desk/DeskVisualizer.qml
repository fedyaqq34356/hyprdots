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
                       : face.variant === "orb" ? orb
                       : face.variant === "line" ? line
                       : face.variant === "grid" ? grid
                       : face.variant === "flame" ? flame
                       : face.variant === "tape" ? tape
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
                            NumberAnimation { duration: Motion.instant; easing.type: Easing.OutQuad }
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
    Component {
        id: orb

        Item {
            implicitWidth: 220
            implicitHeight: 220

            Repeater {
                model: 4

                Rectangle {
                    required property int index

                    anchors.centerIn: parent
                    width: parent.width * (0.36 + index * 0.18)
                    height: width
                    radius: width / 2
                    antialiasing: true
                    color: "transparent"
                    border.width: index === 0 ? 0 : 2
                    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b,
                                          0.42 - index * 0.09 + Beat.level * 0.25)

                    scale: 1 + Beat.bass * (0.06 + index * 0.04)
                    Behavior on scale { NumberAnimation { duration: Motion.instant } }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.34
                height: width
                radius: width / 2
                antialiasing: true
                color: Colors.accent
                opacity: 0.35 + Beat.level * 0.5
                scale: 1 + Beat.pulse * 0.18
                Behavior on scale { NumberAnimation { duration: Motion.instant } }
            }

            Rectangle {
                anchors.centerIn: parent
                width: parent.width * 0.16
                height: width
                radius: width / 2
                antialiasing: true
                color: Colors.fg
                opacity: 0.5 + Beat.treble * 0.4
            }
        }
    }

    Component {
        id: line

        Canvas {
            id: scope

            implicitWidth: 380
            implicitHeight: 110
            renderStrategy: Canvas.Cooperative
            antialiasing: true

            readonly property var levels: Cava.levels
            readonly property color tint: Colors.accent

            onLevelsChanged: scope.requestPaint()
            onTintChanged: scope.requestPaint()
            onWidthChanged: scope.requestPaint()

            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();

                const l = scope.levels;
                const n = l ? l.length : 0;
                if (n < 2)
                    return;

                const mid = height / 2;
                const step = width / (n - 1);

                for (const pass of [{ w: 7, a: 0.18 }, { w: 2, a: 1.0 }]) {
                    ctx.beginPath();
                    for (let i = 0; i < n; i++) {
                        const v = l[i] === undefined ? 0 : l[i];
                        const y = mid - (i % 2 === 0 ? 1 : -1) * v * mid * 0.92;
                        if (i === 0) ctx.moveTo(0, y);
                        else ctx.lineTo(i * step, y);
                    }
                    ctx.strokeStyle = Qt.rgba(scope.tint.r, scope.tint.g,
                                              scope.tint.b, pass.a);
                    ctx.lineWidth = pass.w;
                    ctx.lineJoin = "round";
                    ctx.lineCap = "round";
                    ctx.stroke();
                }
            }
        }
    }

    Component {
        id: grid

        Item {
            implicitWidth: 360
            implicitHeight: 150

            readonly property int rows: 9

            Row {
                anchors.centerIn: parent
                spacing: 4

                Repeater {
                    model: Cava.bars

                    Column {
                        id: bandColumn

                        required property int index
                        spacing: 4

                        readonly property real level: {
                            const v = Cava.levels[bandColumn.index];
                            return v === undefined ? 0 : v;
                        }

                        Repeater {
                            model: 9

                            Rectangle {
                                required property int index

                                readonly property real threshold: (9 - index - 1) / 9
                                readonly property bool lit: bandColumn.level > threshold

                                width: 12
                                height: 12
                                radius: 3
                                antialiasing: true

                                color: index < 2 ? Colors.warn : Colors.accent
                                opacity: lit ? 0.95 : 0.08

                                Behavior on opacity { NumberAnimation { duration: 100 } }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: flame

        Item {
            implicitWidth: 340
            implicitHeight: 190

            Row {
                id: torches

                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4

                readonly property real cell:
                    (parent.width - spacing * (Cava.bars - 1)) / Math.max(1, Cava.bars)

                Repeater {
                    model: Cava.bars

                    Rectangle {
                        required property int index

                        readonly property real level: {
                            const v = Cava.levels[index];
                            return v === undefined ? 0 : v;
                        }

                        width: torches.cell
                        height: Math.max(width, level * 180)
                        radius: width / 2
                        antialiasing: true

                        gradient: Gradient {
                            GradientStop {
                                position: 0.0
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                               Colors.accent.b, 0.0)
                            }
                            GradientStop {
                                position: 0.45
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                               Colors.accent.b, 0.65)
                            }
                            GradientStop {
                                position: 1.0
                                color: Qt.rgba(Colors.warn.r, Colors.warn.g,
                                               Colors.warn.b, 0.95)
                            }
                        }

                        Behavior on height {
                            NumberAnimation { duration: Motion.instant; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: tape

        Column {
            spacing: 6

            Repeater {
                model: Math.min(10, Cava.bars)

                Item {
                    id: band

                    required property int index

                    readonly property real level: {
                        const v = Cava.levels[band.index];
                        return v === undefined ? 0 : v;
                    }

                    width: 320
                    height: 10

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                       Colors.fgDim.b, 0.10)
                    }

                    Rectangle {
                        width: Math.max(parent.height, parent.width * band.level)
                        height: parent.height
                        radius: height / 2
                        antialiasing: true

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Colors.accentAlt }
                            GradientStop { position: 1.0; color: Colors.accent }
                        }

                        Behavior on width {
                            NumberAnimation { duration: Motion.instant; easing.type: Easing.OutQuad }
                        }
                    }
                }
            }
        }
    }
}
