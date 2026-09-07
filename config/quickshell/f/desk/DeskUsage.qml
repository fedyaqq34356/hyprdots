import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "rings"

    readonly property bool bare: face.variant === "rings"
                              || face.variant === "digits"
                              || face.variant === "meters"
                              || face.variant === "gauge"

    readonly property string mono: Fonts.mono

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Component.onCompleted: Sys.acquire()
    Component.onDestruction: Sys.release()

    readonly property var metrics: [
        { label: "cpu", value: Sys.cpu, caption: Sys.cpuLabel },
        { label: "ram", value: Sys.mem, caption: Sys.memLabel },
        { label: "gpu", value: Sys.gpu, caption: Sys.gpuLabel }
    ]

    readonly property var allMetrics: [
        { label: "cpu",  value: Sys.cpu,     caption: Sys.cpuLabel,     glyph: "\uf4bc" },
        { label: "ram",  value: Sys.mem,     caption: Sys.memLabel,     glyph: "\udb80\udf5b" },
        { label: "gpu",  value: Sys.gpu,     caption: Sys.gpuLabel,     glyph: "\udb82\udcae" },
        { label: "vram", value: Sys.vram,    caption: Sys.vramLabel,    glyph: "\udb80\udf5b" },
        { label: "cpu \u00b0", value: Sys.temp,    caption: Sys.tempLabel,    glyph: "\udb80\ude9f" },
        { label: "gpu \u00b0", value: Sys.gputemp, caption: Sys.gputempLabel, glyph: "\udb80\ude9f" }
    ]

    function tone(v) {
        return v > 85 ? Colors.bad : v > 60 ? Colors.warn : Colors.accent;
    }

    Loader {
        id: loader
        sourceComponent: face.variant === "bars" ? bars
                       : face.variant === "grid" ? grid
                       : face.variant === "column" ? column
                       : face.variant === "gauge" ? gauge
                       : face.variant === "trace" ? trace
                       : face.variant === "digits" ? digits
                       : face.variant === "full" ? full
                       : face.variant === "meters" ? meters
                       : face.variant === "compact" ? compact
                       : rings
    }

    Component {
        id: rings

        Row {
            spacing: 22

            Repeater {
                model: face.metrics

                Item {
                    required property var modelData

                    width: 84
                    height: 84
                    visible: modelData.value >= 0

                    Ring {
                        anchors.fill: parent
                        value: modelData.value
                        label: modelData.caption
                        caption: modelData.label
                        thickness: 5
                        animationDuration: 700
                    }
                }
            }
        }
    }

    Component {
        id: digits

        Row {
            spacing: 26

            Repeater {
                model: face.metrics

                Column {
                    required property var modelData

                    spacing: -6
                    visible: modelData.value >= 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(modelData.value)
                        color: modelData.value > 85 ? Colors.bad
                             : modelData.value > 60 ? Colors.warn
                             : Colors.fg
                        opacity: 0.92
                        font.family: face.mono
                        font.pixelSize: 56
                        font.weight: Font.Thin
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: Colors.fgDim
                        opacity: 0.55
                        font.family: face.mono
                        font.pixelSize: 11
                        font.letterSpacing: 3
                    }
                }
            }
        }
    }

    Component {
        id: bars

        Rectangle {
            implicitWidth: 240
            implicitHeight: rows.implicitHeight + 30
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
                width: parent.width - 32
                spacing: 12

                Repeater {
                    model: face.metrics

                    Column {
                        required property var modelData

                        width: rows.width
                        spacing: 5
                        visible: modelData.value >= 0

                        Row {
                            width: parent.width

                            Text {
                                text: modelData.label
                                color: Colors.fgDim
                                opacity: 0.7
                                font.family: face.mono
                                font.pixelSize: 11
                                font.letterSpacing: 2
                            }

                            Item { width: parent.width - 100; height: 1 }

                            Text {
                                text: modelData.caption
                                color: Colors.fg
                                font.family: face.mono
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                           Colors.outline.b, 0.2)

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, modelData.value / 100))
                                height: parent.height
                                radius: parent.radius
                                color: modelData.value > 85 ? Colors.bad
                                     : modelData.value > 60 ? Colors.warn
                                     : Colors.accent

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Motion.slow
                                        easing.type: Easing.Bezier
                                        easing.bezierCurve: Motion.decel
                                    }
                                }
                                Behavior on color { ColorAnimation { duration: Motion.base } }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: full

        Rectangle {
            implicitWidth: 268
            implicitHeight: fullRows.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: fullRows
                anchors.centerIn: parent
                width: parent.width - 34
                spacing: 11

                Repeater {
                    model: face.allMetrics

                    Column {
                        required property var modelData

                        width: fullRows.width
                        spacing: 5
                        visible: modelData.value >= 0

                        Row {
                            width: parent.width

                            Text {
                                text: modelData.glyph
                                color: face.tone(modelData.value)
                                opacity: 0.9
                                font.family: face.mono
                                font.pixelSize: 11
                                Behavior on color { ColorAnimation { duration: Motion.base } }
                            }

                            Item { width: 8; height: 1 }

                            Text {
                                text: modelData.label
                                color: Colors.fgDim
                                opacity: 0.7
                                font.family: face.mono
                                font.pixelSize: 11
                                font.letterSpacing: 2
                            }

                            Item { width: parent.width - 130; height: 1 }

                            Text {
                                text: modelData.caption
                                color: Colors.fg
                                font.family: face.mono
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 4
                            radius: 2
                            color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                           Colors.outline.b, 0.2)

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, modelData.value / 100))
                                height: parent.height
                                radius: parent.radius
                                color: face.tone(modelData.value)

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Motion.slow
                                        easing.type: Easing.Bezier
                                        easing.bezierCurve: Motion.decel
                                    }
                                }
                                Behavior on color { ColorAnimation { duration: Motion.base } }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: meters

        Row {
            spacing: 16

            Repeater {
                model: face.allMetrics

                Column {
                    required property var modelData

                    spacing: 7
                    visible: modelData.value >= 0

                    Item {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 12
                        height: 96

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                           Colors.outline.b, 0.18)
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            radius: 6
                            height: Math.max(width,
                                parent.height * Math.max(0, Math.min(1, modelData.value / 100)))
                            color: face.tone(modelData.value)

                            Behavior on height {
                                NumberAnimation {
                                    duration: Motion.slow
                                    easing.type: Easing.Bezier
                                    easing.bezierCurve: Motion.decel
                                }
                            }
                            Behavior on color { ColorAnimation { duration: Motion.base } }
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Math.round(modelData.value)
                        color: Colors.fg
                        opacity: 0.9
                        font.family: face.mono
                        font.pixelSize: 13
                        font.weight: Font.Light
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: modelData.label
                        color: Colors.fgDim
                        opacity: 0.5
                        font.family: face.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1
                    }
                }
            }
        }
    }

    Component {
        id: compact

        Rectangle {
            implicitWidth: 290
            implicitHeight: grid.implicitHeight + 30
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Grid {
                id: grid
                anchors.centerIn: parent
                columns: 2
                columnSpacing: 22
                rowSpacing: 12

                Repeater {
                    model: face.allMetrics

                    Row {
                        required property var modelData

                        spacing: 8
                        visible: modelData.value >= 0

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 8
                            height: 8
                            radius: 4
                            antialiasing: true
                            color: face.tone(modelData.value)
                            Behavior on color { ColorAnimation { duration: Motion.base } }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 42
                            text: modelData.label
                            color: Colors.fgDim
                            opacity: 0.65
                            font.family: face.mono
                            font.pixelSize: 10
                            font.letterSpacing: 1
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 62
                            horizontalAlignment: Text.AlignRight
                            text: modelData.caption
                            color: Colors.fg
                            font.family: face.mono
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
    Component {
        id: grid

        Rectangle {
            implicitWidth: 330
            implicitHeight: tiles.implicitHeight + 36
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Grid {
                id: tiles

                anchors.centerIn: parent
                width: parent.width - 36
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: face.allMetrics

                    Rectangle {
                        id: tile

                        required property var modelData

                        width: (tiles.width - tiles.columnSpacing) / 2
                        height: 62
                        radius: Shape.field
                        opacity: modelData.value >= 0 ? 1 : 0.35
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                       Colors.bgAlt.b, 0.35)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 11
                            spacing: 6

                            Row {
                                width: parent.width
                                spacing: 7

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tile.modelData.glyph
                                    color: face.tone(tile.modelData.value)
                                    opacity: 0.85
                                    font.family: face.mono
                                    font.pixelSize: 13
                                    Behavior on color { ColorAnimation { duration: Motion.base } }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tile.modelData.label
                                    color: Colors.fgDim
                                    opacity: 0.55
                                    font.family: face.mono
                                    font.pixelSize: 9
                                    font.letterSpacing: 1
                                }

                                Item { width: 1; height: 1 }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: tile.modelData.value >= 0
                                        ? Math.round(tile.modelData.value) + "%" : "—"
                                    color: Colors.fg
                                    font.family: face.mono
                                    font.pixelSize: 13
                                }
                            }

                            Rectangle {
                                width: parent.width
                                height: 4
                                radius: 2
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.14)

                                Rectangle {
                                    width: parent.width
                                        * Math.max(0, Math.min(1, tile.modelData.value / 100))
                                    height: parent.height
                                    radius: parent.radius
                                    color: face.tone(tile.modelData.value)
                                    Behavior on width { NumberAnimation { duration: Motion.slow } }
                                    Behavior on color { ColorAnimation { duration: Motion.base } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: column

        Rectangle {
            implicitWidth: 260
            implicitHeight: lines.implicitHeight + 36
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: lines

                anchors.centerIn: parent
                width: parent.width - 36
                spacing: 13

                Repeater {
                    model: face.allMetrics

                    Item {
                        id: line

                        required property var modelData

                        width: lines.width
                        height: 26
                        opacity: modelData.value >= 0 ? 1 : 0.3

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            text: line.modelData.label
                            color: Colors.fgDim
                            opacity: 0.6
                            font.family: face.mono
                            font.pixelSize: 10
                            font.letterSpacing: 1
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            text: line.modelData.caption !== ""
                                ? line.modelData.caption
                                : (line.modelData.value >= 0
                                    ? Math.round(line.modelData.value) + "%" : "—")
                            color: Colors.fg
                            opacity: 0.85
                            font.family: face.mono
                            font.pixelSize: 11
                        }

                        Rectangle {
                            anchors.bottom: parent.bottom
                            width: parent.width
                            height: 3
                            radius: 1.5
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.14)

                            Rectangle {
                                width: parent.width
                                    * Math.max(0, Math.min(1, line.modelData.value / 100))
                                height: parent.height
                                radius: parent.radius
                                color: face.tone(line.modelData.value)
                                Behavior on width { NumberAnimation { duration: Motion.slow } }
                                Behavior on color { ColorAnimation { duration: Motion.base } }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: gauge

        Item {
            implicitWidth: 230
            implicitHeight: 230

            ProgressRing {
                anchors.fill: parent
                value: Math.max(0, Sys.cpu) / 100
                color: face.tone(Sys.cpu)
                trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                    Colors.fgDim.b, 0.14)
                thickness: 9
                inset: 5
                animationDuration: 700
            }

            Column {
                anchors.centerIn: parent
                spacing: -4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Sys.cpu >= 0 ? Math.round(Sys.cpu) : "—"
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 62
                    font.weight: Font.Thin
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "cpu"
                    color: Colors.fgDim
                    opacity: 0.55
                    font.family: face.mono
                    font.pixelSize: 11
                    font.letterSpacing: 3
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    topPadding: 10
                    spacing: 14

                    Repeater {
                        model: [
                            { label: "ram", value: Sys.mem },
                            { label: "gpu", value: Sys.gpu }
                        ]

                        Row {
                            required property var modelData
                            spacing: 5
                            visible: modelData.value >= 0

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6
                                height: 6
                                radius: 3
                                antialiasing: true
                                color: face.tone(parent.modelData.value)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: parent.modelData.label + " "
                                      + Math.round(parent.modelData.value) + "%"
                                color: Colors.fgDim
                                opacity: 0.7
                                font.family: face.mono
                                font.pixelSize: 10
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: trace

        Rectangle {
            id: chart

            implicitWidth: 320
            implicitHeight: 170
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            property var cpuSeries: []
            property var memSeries: []
            readonly property int points: 48

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Timer {
                interval: 2000
                running: true
                repeat: true
                triggeredOnStart: true

                onTriggered: {
                    const push = (series, v) => {
                        const out = series.slice(-(chart.points - 1));
                        out.push(Math.max(0, v));
                        return out;
                    };
                    chart.cpuSeries = push(chart.cpuSeries, Sys.cpu);
                    chart.memSeries = push(chart.memSeries, Sys.mem);
                    plot.requestPaint();
                }
            }

            Canvas {
                id: plot

                anchors.fill: parent
                anchors.margins: 16
                anchors.topMargin: 40
                renderStrategy: Canvas.Cooperative

                readonly property color cpuTint: Colors.accent
                readonly property color memTint: Colors.accentAlt

                onCpuTintChanged: plot.requestPaint()
                onWidthChanged: plot.requestPaint()

                function line(ctx, series, tint, fill) {
                    if (series.length < 2)
                        return;

                    const step = width / (chart.points - 1);
                    ctx.beginPath();
                    for (let i = 0; i < series.length; i++) {
                        const x = i * step;
                        const y = height - (Math.min(100, series[i]) / 100) * height;
                        if (i === 0) ctx.moveTo(x, y);
                        else ctx.lineTo(x, y);
                    }

                    ctx.strokeStyle = tint;
                    ctx.lineWidth = 2;
                    ctx.lineJoin = "round";
                    ctx.stroke();

                    if (!fill)
                        return;

                    ctx.lineTo((series.length - 1) * step, height);
                    ctx.lineTo(0, height);
                    ctx.closePath();
                    ctx.fillStyle = Qt.rgba(tint.r, tint.g, tint.b, 0.14);
                    ctx.fill();
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    ctx.strokeStyle = Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                              Colors.fgDim.b, 0.10);
                    ctx.lineWidth = 1;
                    for (let q = 1; q < 4; q++) {
                        const y = Math.round(height * q / 4) + 0.5;
                        ctx.beginPath();
                        ctx.moveTo(0, y);
                        ctx.lineTo(width, y);
                        ctx.stroke();
                    }

                    plot.line(ctx, chart.memSeries, plot.memTint, false);
                    plot.line(ctx, chart.cpuSeries, plot.cpuTint, true);
                }
            }

            Row {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 16
                spacing: 16

                Repeater {
                    model: [
                        { label: "cpu", value: Sys.cpu, tint: Colors.accent },
                        { label: "ram", value: Sys.mem, tint: Colors.accentAlt }
                    ]

                    Row {
                        id: legend

                        required property var modelData
                        spacing: 6

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10
                            height: 3
                            radius: 1.5
                            color: legend.modelData.tint
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: legend.modelData.label + "  "
                                  + (legend.modelData.value >= 0
                                     ? Math.round(legend.modelData.value) + "%" : "—")
                            color: Colors.fgDim
                            opacity: 0.75
                            font.family: face.mono
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
