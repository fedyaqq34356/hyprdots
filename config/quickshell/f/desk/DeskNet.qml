import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "speed"

    readonly property bool bare: face.variant === "speed"
                              || face.variant === "minimal"
                              || face.variant === "dial"
                              || face.variant === "bars"

    readonly property string mono: Fonts.mono

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    Component.onCompleted: Network.hold()
    Component.onDestruction: Network.release()

    function rate(bytes) {
        return Network.human(bytes);
    }

    Loader {
        id: loader
        sourceComponent: face.variant === "link" ? link
                       : face.variant === "graph" ? graph
                       : face.variant === "meters" ? meters
                       : face.variant === "dial" ? dial
                       : face.variant === "badge" ? badge
                       : face.variant === "column" ? column
                       : face.variant === "bars" ? bars
                       : face.variant === "minimal" ? minimal
                       : face.variant === "detail" ? detail
                       : speed
    }

    Component {
        id: speed

        Column {
            spacing: 6

            Repeater {
                model: [
                    { glyph: "󰇚", value: Network.rxRate, tint: Colors.accent },
                    { glyph: "󰕒", value: Network.txRate, tint: Colors.accentAlt }
                ]

                Row {
                    required property var modelData
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: modelData.glyph
                        color: modelData.tint
                        opacity: 0.85
                        font.family: face.mono
                        font.pixelSize: 18
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: face.rate(modelData.value)
                        color: Colors.fg
                        opacity: 0.92
                        font.family: face.mono
                        font.pixelSize: 26
                        font.weight: Font.Light
                    }
                }
            }
        }
    }

    Component {
        id: link

        Rectangle {
            implicitWidth: 250
            implicitHeight: 96
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Row {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Item {
                    width: 46
                    height: 46
                    anchors.verticalCenter: parent.verticalCenter

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        antialiasing: true
                        color: Network.connected
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                      Colors.accent.b, 0.16)
                            : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                      Colors.fgDim.b, 0.08)
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: Network.glyph
                        color: Network.connected ? Colors.accent : Colors.fgDim
                        font.family: face.mono
                        font.pixelSize: 20
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 60
                    spacing: 5

                    Text {
                        width: parent.width
                        text: Network.connected && Network.ssid !== ""
                            ? Network.ssid : I18n.t("net.notConnected")
                        color: Colors.fg
                        elide: Text.ElideRight
                        font.family: face.mono
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: {
                            const parts = [];
                            if (Network.strength > 0)
                                parts.push(Network.strength + "%");
                            if (Network.linkRate !== "")
                                parts.push(Network.linkRate);
                            return parts.join("  ·  ");
                        }
                        visible: text !== ""
                        color: Colors.fgDim
                        opacity: 0.7
                        elide: Text.ElideRight
                        font.family: face.mono
                        font.pixelSize: 11
                    }

                    Row {
                        spacing: 12

                        Text {
                            text: "󰇚 " + face.rate(Network.rxRate)
                            color: Colors.accent
                            opacity: 0.85
                            font.family: face.mono
                            font.pixelSize: 11
                        }

                        Text {
                            text: "󰕒 " + face.rate(Network.txRate)
                            color: Colors.accentAlt
                            opacity: 0.85
                            font.family: face.mono
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
    Component {
        id: graph

        Rectangle {
            id: chart

            implicitWidth: 300
            implicitHeight: 160
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            property var rxSeries: []
            property var txSeries: []
            readonly property int points: 60

            readonly property real ceiling: {
                let m = 65536;
                for (const v of chart.rxSeries) m = Math.max(m, v);
                for (const v of chart.txSeries) m = Math.max(m, v);
                return m;
            }

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Timer {
                interval: 1000
                running: true
                repeat: true
                triggeredOnStart: true

                onTriggered: {
                    const push = (series, v) => {
                        const out = series.slice(-(chart.points - 1));
                        out.push(Math.max(0, v));
                        return out;
                    };
                    chart.rxSeries = push(chart.rxSeries, Network.rxRate);
                    chart.txSeries = push(chart.txSeries, Network.txRate);
                    plot.requestPaint();
                }
            }

            Canvas {
                id: plot

                anchors.fill: parent
                anchors.margins: 16
                anchors.topMargin: 44
                renderStrategy: Canvas.Cooperative

                readonly property color rxTint: Colors.accent
                readonly property color txTint: Colors.accentAlt

                onRxTintChanged: plot.requestPaint()
                onWidthChanged: plot.requestPaint()

                function curve(ctx, series, tint, fill) {
                    if (series.length < 2)
                        return;

                    const step = width / (chart.points - 1);
                    ctx.beginPath();
                    for (let i = 0; i < series.length; i++) {
                        const x = i * step;
                        const y = height - (series[i] / chart.ceiling) * height;
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
                    ctx.fillStyle = Qt.rgba(tint.r, tint.g, tint.b, 0.16);
                    ctx.fill();
                }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    ctx.strokeStyle = Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                              Colors.fgDim.b, 0.10);
                    ctx.lineWidth = 1;
                    for (let q = 1; q < 3; q++) {
                        const y = Math.round(height * q / 3) + 0.5;
                        ctx.beginPath();
                        ctx.moveTo(0, y);
                        ctx.lineTo(width, y);
                        ctx.stroke();
                    }

                    plot.curve(ctx, chart.txSeries, plot.txTint, false);
                    plot.curve(ctx, chart.rxSeries, plot.rxTint, true);
                }
            }

            Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 16
                spacing: 3

                Text {
                    text: Network.connected && Network.ssid !== ""
                        ? Network.ssid : I18n.t("net.notConnected")
                    color: Colors.fg
                    width: 260
                    elide: Text.ElideRight
                    font.family: face.mono
                    font.pixelSize: 12
                }

                Row {
                    spacing: 14

                    Text {
                        text: "󰇚 " + face.rate(Network.rxRate)
                        color: Colors.accent
                        opacity: 0.9
                        font.family: face.mono
                        font.pixelSize: 11
                    }

                    Text {
                        text: "󰕒 " + face.rate(Network.txRate)
                        color: Colors.accentAlt
                        opacity: 0.9
                        font.family: face.mono
                        font.pixelSize: 11
                    }
                }
            }
        }
    }

    Component {
        id: meters

        Rectangle {
            id: gaugeCard

            implicitWidth: 280
            implicitHeight: 120
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            property real ceiling: 65536

            Timer {
                interval: 1000
                running: true
                repeat: true
                onTriggered: {
                    const peak = Math.max(Network.rxRate, Network.txRate, 65536);
                    gaugeCard.ceiling = peak > gaugeCard.ceiling
                        ? peak
                        : gaugeCard.ceiling * 0.92 + peak * 0.08;
                }
            }

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Repeater {
                    model: [
                        { glyph: "󰇚", value: Network.rxRate, tint: Colors.accent },
                        { glyph: "󰕒", value: Network.txRate, tint: Colors.accentAlt }
                    ]

                    Column {
                        id: meter

                        required property var modelData

                        width: parent.width
                        spacing: 6

                        Row {
                            width: parent.width

                            Text {
                                text: meter.modelData.glyph
                                color: meter.modelData.tint
                                opacity: 0.9
                                font.family: face.mono
                                font.pixelSize: 13
                            }

                            Item { width: parent.width - 130; height: 1 }

                            Text {
                                text: face.rate(meter.modelData.value)
                                color: Colors.fg
                                font.family: face.mono
                                font.pixelSize: 13
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 5
                            radius: 2.5
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.14)

                            Rectangle {
                                width: parent.width * Math.min(1,
                                    meter.modelData.value / gaugeCard.ceiling)
                                height: parent.height
                                radius: parent.radius
                                color: meter.modelData.tint
                                Behavior on width { NumberAnimation { duration: 900 } }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: dial

        Item {
            implicitWidth: 180
            implicitHeight: 180

            ProgressRing {
                anchors.fill: parent
                value: Math.max(0, Math.min(1, Network.strength / 100))
                color: Network.connected ? Colors.accent : Colors.fgDim
                trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.14)
                thickness: 6
                inset: 4
            }

            Column {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Network.glyph
                    color: Network.connected ? Colors.accent : Colors.fgDim
                    font.family: face.mono
                    font.pixelSize: 26
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 130
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: Network.connected && Network.ssid !== ""
                        ? Network.ssid : I18n.t("net.notConnected")
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 13
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Network.strength > 0 ? Network.strength + "%" : ""
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }

    Component {
        id: badge

        Rectangle {
            implicitWidth: Math.min(240, badgeRow.implicitWidth + 28)
            implicitHeight: 40
            radius: height / 2
            antialiasing: true
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
            border.width: 1
            border.color: Network.connected
                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45)
                : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.25)

            Row {
                id: badgeRow

                anchors.centerIn: parent
                spacing: 9

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Network.glyph
                    color: Network.connected ? Colors.accent : Colors.fgDim
                    font.family: face.mono
                    font.pixelSize: 16
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(160, implicitWidth)
                    elide: Text.ElideRight
                    text: Network.connected && Network.ssid !== ""
                        ? Network.ssid : I18n.t("net.notConnected")
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 13
                }
            }
        }
    }

    Component {
        id: column

        Rectangle {
            implicitWidth: 170
            implicitHeight: 176
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Network.glyph
                        color: Network.connected ? Colors.accent : Colors.fgDim
                        font.family: face.mono
                        font.pixelSize: 16
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 30
                        elide: Text.ElideRight
                        text: Network.connected && Network.ssid !== ""
                            ? Network.ssid : I18n.t("net.notConnected")
                        color: Colors.fg
                        font.family: face.mono
                        font.pixelSize: 12
                    }
                }

                Repeater {
                    model: [
                        { glyph: "󰇚", value: Network.rxRate, tint: Colors.accent },
                        { glyph: "󰕒", value: Network.txRate, tint: Colors.accentAlt }
                    ]

                    Column {
                        id: leg

                        required property var modelData

                        spacing: -2

                        Text {
                            text: face.rate(leg.modelData.value)
                            color: Colors.fg
                            font.family: face.mono
                            font.pixelSize: 22
                            font.weight: Font.Light
                        }

                        Text {
                            text: leg.modelData.glyph
                            color: leg.modelData.tint
                            opacity: 0.8
                            font.family: face.mono
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }

    Component {
        id: bars

        Column {
            spacing: 10

            Row {
                spacing: 5
                height: 44

                Repeater {
                    model: 5

                    Rectangle {
                        required property int index

                        readonly property bool lit:
                            Network.connected && Network.strength >= (index + 1) * 20 - 10

                        anchors.bottom: parent.bottom
                        width: 12
                        height: 12 + index * 8
                        radius: 3
                        antialiasing: true
                        color: lit ? Colors.accent
                             : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.16)

                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }
                }
            }

            Text {
                text: Network.connected && Network.ssid !== ""
                    ? Network.ssid : I18n.t("net.notConnected")
                color: Colors.fg
                opacity: 0.9
                font.family: face.mono
                font.pixelSize: 14
            }

            Row {
                spacing: 14

                Text {
                    text: "󰇚 " + face.rate(Network.rxRate)
                    color: Colors.accent
                    opacity: 0.85
                    font.family: face.mono
                    font.pixelSize: 11
                }

                Text {
                    text: "󰕒 " + face.rate(Network.txRate)
                    color: Colors.accentAlt
                    opacity: 0.85
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }

    Component {
        id: minimal

        Row {
            spacing: 16

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰇚 " + face.rate(Network.rxRate)
                color: Colors.fg
                font.family: face.mono
                font.pixelSize: 18
                font.weight: Font.Light
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "󰕒 " + face.rate(Network.txRate)
                color: Colors.fgDim
                opacity: 0.75
                font.family: face.mono
                font.pixelSize: 18
                font.weight: Font.Light
            }
        }
    }

    Component {
        id: detail

        Rectangle {
            implicitWidth: 300
            implicitHeight: 176
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
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 12

                    Item {
                        width: 44
                        height: 44
                        anchors.verticalCenter: parent.verticalCenter

                        ProgressRing {
                            anchors.fill: parent
                            value: Math.max(0, Math.min(1, Network.strength / 100))
                            color: Network.connected ? Colors.accent : Colors.fgDim
                            trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                Colors.fgDim.b, 0.14)
                            thickness: 3
                            inset: 2
                        }

                        Text {
                            anchors.centerIn: parent
                            text: Network.glyph
                            color: Network.connected ? Colors.accent : Colors.fgDim
                            font.family: face.mono
                            font.pixelSize: 16
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 60
                        spacing: 3

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: Network.connected && Network.ssid !== ""
                                ? Network.ssid : I18n.t("net.notConnected")
                            color: Colors.fg
                            font.family: face.mono
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            elide: Text.ElideRight
                            text: {
                                const parts = [];
                                if (Network.strength > 0)
                                    parts.push(Network.strength + "%");
                                if (Network.linkRate !== "")
                                    parts.push(Network.linkRate);
                                if (Network.iface !== "")
                                    parts.push(Network.iface);
                                return parts.join("  ·  ");
                            }
                            color: Colors.fgDim
                            opacity: 0.65
                            font.family: face.mono
                            font.pixelSize: 10
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                   Colors.outline.b, 0.16)
                }

                Row {
                    width: parent.width

                    Repeater {
                        model: [
                            { glyph: "󰇚", value: Network.rxRate, tint: Colors.accent,
                              label: "down" },
                            { glyph: "󰕒", value: Network.txRate, tint: Colors.accentAlt,
                              label: "up" }
                        ]

                        Column {
                            id: figure

                            required property var modelData

                            width: 130
                            spacing: 2

                            Text {
                                text: face.rate(figure.modelData.value)
                                color: Colors.fg
                                font.family: face.mono
                                font.pixelSize: 20
                                font.weight: Font.Light
                            }

                            Row {
                                spacing: 6

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: figure.modelData.glyph
                                    color: figure.modelData.tint
                                    opacity: 0.85
                                    font.family: face.mono
                                    font.pixelSize: 11
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: figure.modelData.label
                                    color: Colors.fgDim
                                    opacity: 0.5
                                    font.family: face.mono
                                    font.pixelSize: 10
                                    font.letterSpacing: 1
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
