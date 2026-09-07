import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "bars"

    readonly property bool bare: face.variant === "total"
                              || face.variant === "ring"
                              || face.variant === "list"
                              || face.variant === "now"
                              || face.variant === "donut"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    readonly property var leaders: Wellbeing.ranked.slice(0, 4)

    readonly property int budgetSeconds: 6 * 3600

    readonly property var days: {
        const out = Wellbeing.history.slice(-6).map(d => ({
            date: d.date, total: d.total, today: false
        }));
        out.push({ date: Wellbeing.today, total: Wellbeing.total, today: true });
        return out;
    }

    readonly property int dayPeak: {
        let m = 1;
        for (const d of face.days) m = Math.max(m, d.total);
        return m;
    }

    readonly property var shares: {
        const total = Math.max(1, Wellbeing.total);
        return Wellbeing.ranked.slice(0, 5).map(e => ({
            app: e.app,
            seconds: e.seconds,
            part: e.seconds / total
        }));
    }
    readonly property int peak:
        face.leaders.length > 0 ? face.leaders[0].seconds : 1

    Loader {
        id: loader
        sourceComponent: face.variant === "total" ? total
                       : face.variant === "ring" ? ring
                       : face.variant === "week" ? week
                       : face.variant === "donut" ? donut
                       : face.variant === "list" ? leaderboard
                       : face.variant === "now" ? now
                       : face.variant === "grid" ? tiles
                       : face.variant === "stack" ? stacked
                       : face.variant === "budget" ? budget
                       : bars
    }

    Component {
        id: ring

        Item {
            implicitWidth: 150
            implicitHeight: 150

            Ring {
                anchors.fill: parent
                value: Math.min(1, Wellbeing.total / 28800)
                label: Wellbeing.human(Wellbeing.total)
                caption: I18n.t("desk.screentime")
                thickness: 6
                animationDuration: 900
            }
        }
    }

    Component {
        id: total

        Column {
            spacing: 2

            Text {
                text: Wellbeing.human(Wellbeing.total)
                color: Colors.fg
                font.family: face.mono
                font.pixelSize: 38
                font.weight: Font.Light
            }

            Text {
                text: I18n.t("time.today")
                color: Colors.fgDim
                opacity: 0.6
                font.family: face.mono
                font.pixelSize: 11
                font.letterSpacing: 2
            }
        }
    }

    Component {
        id: bars

        Rectangle {
            implicitWidth: 260
            implicitHeight: body.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: body
                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 12

                Row {
                    width: parent.width

                    Text {
                        text: I18n.t("time.todayGlyph")
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: face.mono
                        font.pixelSize: 11
                        font.letterSpacing: 1
                    }

                    Item { width: parent.width - 170; height: 1 }

                    Text {
                        text: Wellbeing.human(Wellbeing.total)
                        color: Colors.accent
                        font.family: face.mono
                        font.pixelSize: 12
                    }
                }

                Repeater {
                    model: face.leaders

                    Column {
                        required property var modelData

                        width: body.width
                        spacing: 4

                        Row {
                            width: parent.width

                            Text {
                                width: parent.width - 74
                                text: Wellbeing.label(modelData.app)
                                color: Colors.fg
                                opacity: 0.85
                                elide: Text.ElideRight
                                font.family: Fonts.display
                                font.pixelSize: 13
                            }

                            Text {
                                text: Wellbeing.human(modelData.seconds)
                                color: Colors.fgDim
                                opacity: 0.6
                                font.family: face.mono
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 3
                            radius: 2
                            color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                           Colors.outline.b, 0.18)

                            Rectangle {
                                width: parent.width * (modelData.seconds / Math.max(1, face.peak))
                                height: parent.height
                                radius: parent.radius
                                color: Colors.accentAlt
                                Behavior on width { NumberAnimation { duration: Motion.slow } }
                            }
                        }
                    }
                }

                Text {
                    visible: face.leaders.length === 0
                    text: I18n.t("state.nothingYet")
                    color: Colors.fgDim
                    opacity: 0.5
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }
    Component {
        id: week

        Rectangle {
            implicitWidth: 260
            implicitHeight: 172
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

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

                    Text {
                        text: I18n.t("desk.screentime")
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: face.mono
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }

                    Item { width: parent.width - 160; height: 1 }

                    Text {
                        text: Wellbeing.human(Wellbeing.total)
                        color: Colors.accent
                        font.family: face.mono
                        font.pixelSize: 12
                    }
                }

                Row {
                    width: parent.width
                    height: 96
                    spacing: 8

                    Repeater {
                        model: face.days

                        Column {
                            id: bar

                            required property var modelData

                            width: (parent.width - 8 * (face.days.length - 1))
                                   / Math.max(1, face.days.length)
                            height: parent.height
                            spacing: 6

                            Item {
                                width: parent.width
                                height: parent.height - 18

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    width: parent.width
                                    height: Math.max(3, parent.height
                                        * (bar.modelData.total / face.dayPeak))
                                    radius: Shape.detail
                                    color: bar.modelData.today
                                        ? Colors.accent
                                        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                  Colors.fgDim.b, 0.30)
                                    Behavior on height { NumberAnimation { duration: Motion.slow } }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: bar.modelData.date !== ""
                                    ? Qt.formatDateTime(new Date(bar.modelData.date), "dd")
                                    : "—"
                                color: Colors.fgDim
                                opacity: bar.modelData.today ? 0.9 : 0.45
                                font.family: face.mono
                                font.pixelSize: 9
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: donut

        Item {
            implicitWidth: 190
            implicitHeight: 190

            Canvas {
                id: pie

                anchors.fill: parent
                renderStrategy: Canvas.Cooperative
                antialiasing: true

                readonly property var slices: face.shares
                readonly property color tint: Colors.accent

                onSlicesChanged: pie.requestPaint()
                onTintChanged: pie.requestPaint()
                onWidthChanged: pie.requestPaint()

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const cx = width / 2;
                    const cy = height / 2;
                    const r = Math.min(width, height) / 2 - 8;

                    ctx.lineWidth = 16;
                    ctx.beginPath();
                    ctx.arc(cx, cy, r, 0, Math.PI * 2);
                    ctx.strokeStyle = Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                              Colors.fgDim.b, 0.12);
                    ctx.stroke();

                    let at = -Math.PI / 2;
                    for (let i = 0; i < pie.slices.length; i++) {
                        const s = pie.slices[i];
                        const sweep = s.part * Math.PI * 2;
                        if (sweep <= 0.002)
                            continue;

                        ctx.beginPath();
                        ctx.arc(cx, cy, r, at + 0.03, at + sweep - 0.03);
                        ctx.strokeStyle = i === 0
                            ? Colors.accent
                            : Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                      Colors.accentAlt.b, 0.85 - i * 0.16);
                        ctx.lineCap = "butt";
                        ctx.stroke();

                        at += sweep;
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Wellbeing.human(Wellbeing.total)
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 26
                    font.weight: Font.Light
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: face.shares.length > 0
                        ? Wellbeing.label(face.shares[0].app) : ""
                    color: Colors.fgDim
                    opacity: 0.6
                    width: 120
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    font.family: Fonts.display
                    font.pixelSize: 11
                }
            }
        }
    }

    Component {
        id: leaderboard

        Column {
            spacing: 10

            Repeater {
                model: Wellbeing.ranked.slice(0, 5)

                Row {
                    id: entry

                    required property var modelData
                    required property int index

                    spacing: 12

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 18
                        text: entry.index + 1
                        color: entry.index === 0 ? Colors.accent : Colors.fgDim
                        opacity: entry.index === 0 ? 1 : 0.4
                        font.family: face.mono
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 180
                        text: Wellbeing.label(entry.modelData.app)
                        color: Colors.fg
                        opacity: entry.index === 0 ? 1 : 0.8
                        elide: Text.ElideRight
                        font.family: Fonts.display
                        font.pixelSize: entry.index === 0 ? 18 : 15
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Wellbeing.human(entry.modelData.seconds)
                        color: Colors.fgDim
                        opacity: 0.65
                        font.family: face.mono
                        font.pixelSize: 12
                    }
                }
            }

            Text {
                visible: Wellbeing.ranked.length === 0
                text: I18n.t("state.nothingYet")
                color: Colors.fgDim
                opacity: 0.5
                font.family: face.mono
                font.pixelSize: 12
            }
        }
    }

    Component {
        id: now

        Column {
            spacing: 4

            Text {
                text: I18n.t("time.today")
                color: Colors.fgDim
                opacity: 0.5
                font.family: face.mono
                font.pixelSize: 10
                font.letterSpacing: 3
            }

            Text {
                text: Wellbeing.current !== ""
                    ? Wellbeing.label(Wellbeing.current)
                    : "—"
                color: Colors.fg
                font.family: Fonts.display
                font.pixelSize: 34
                font.weight: Font.DemiBold
            }

            Row {
                spacing: 10

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Wellbeing.human(
                        Wellbeing.apps[Wellbeing.current] !== undefined
                            ? Wellbeing.apps[Wellbeing.current] : 0)
                    color: Colors.accent
                    font.family: face.mono
                    font.pixelSize: 20
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 1
                    height: 16
                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.3)
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Wellbeing.human(Wellbeing.total) + " total"
                    color: Colors.fgDim
                    opacity: 0.6
                    font.family: face.mono
                    font.pixelSize: 12
                }
            }
        }
    }

    Component {
        id: tiles

        Rectangle {
            implicitWidth: 280
            implicitHeight: quad.implicitHeight + 36
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Grid {
                id: quad

                anchors.centerIn: parent
                width: parent.width - 36
                columns: 2
                columnSpacing: 10
                rowSpacing: 10

                Repeater {
                    model: face.leaders

                    Rectangle {
                        id: appTile

                        required property var modelData
                        required property int index

                        width: (quad.width - quad.columnSpacing) / 2
                        height: 66
                        radius: Shape.field
                        color: index === 0
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                      Colors.accent.b, 0.16)
                            : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                      Colors.bgAlt.b, 0.35)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Text {
                                width: parent.width
                                text: Wellbeing.label(appTile.modelData.app)
                                color: Colors.fg
                                opacity: 0.9
                                elide: Text.ElideRight
                                font.family: Fonts.display
                                font.pixelSize: 13
                            }

                            Text {
                                text: Wellbeing.human(appTile.modelData.seconds)
                                color: appTile.index === 0 ? Colors.accent : Colors.fgDim
                                opacity: appTile.index === 0 ? 1 : 0.7
                                font.family: face.mono
                                font.pixelSize: 15
                            }

                            Rectangle {
                                width: parent.width
                                height: 3
                                radius: 1.5
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.14)

                                Rectangle {
                                    width: parent.width * (appTile.modelData.seconds
                                        / Math.max(1, face.peak))
                                    height: parent.height
                                    radius: parent.radius
                                    color: appTile.index === 0
                                        ? Colors.accent : Colors.accentAlt
                                    Behavior on width { NumberAnimation { duration: Motion.slow } }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: stacked

        Rectangle {
            implicitWidth: 300
            implicitHeight: 118
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

                Text {
                    text: Wellbeing.human(Wellbeing.total)
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 30
                    font.weight: Font.Light
                }

                Row {
                    width: parent.width
                    height: 12
                    spacing: 3

                    Repeater {
                        model: face.shares

                        Rectangle {
                            id: slice

                            required property var modelData
                            required property int index

                            width: Math.max(2, (parent.width - 12) * modelData.part)
                            height: parent.height
                            radius: Shape.detail
                            color: index === 0
                                ? Colors.accent
                                : Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                          Colors.accentAlt.b, 0.85 - index * 0.16)

                            Behavior on width { NumberAnimation { duration: Motion.slow } }
                        }
                    }
                }

                Row {
                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: face.shares.slice(0, 3)

                        Row {
                            id: key

                            required property var modelData
                            required property int index

                            spacing: 5

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 7
                                height: 7
                                radius: 2
                                color: key.index === 0
                                    ? Colors.accent
                                    : Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                              Colors.accentAlt.b, 0.85 - key.index * 0.16)
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Wellbeing.label(key.modelData.app)
                                color: Colors.fgDim
                                opacity: 0.7
                                elide: Text.ElideRight
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
        id: budget

        Rectangle {
            id: goal

            readonly property real part:
                Math.min(1.6, Wellbeing.total / face.budgetSeconds)
            readonly property bool over: Wellbeing.total > face.budgetSeconds

            implicitWidth: 280
            implicitHeight: 126
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: budgetBody

                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                Row {
                    width: parent.width

                    Text {
                        text: Wellbeing.human(Wellbeing.total)
                        color: goal.over ? Colors.warn : Colors.fg
                        font.family: face.mono
                        font.pixelSize: 32
                        font.weight: Font.Light
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Item { width: parent.width - 190; height: 1 }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 5
                        text: "/ " + Wellbeing.human(face.budgetSeconds)
                        color: Colors.fgDim
                        opacity: 0.55
                        font.family: face.mono
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 8
                    radius: 4
                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.14)

                    Rectangle {
                        width: parent.width * Math.min(1, goal.part)
                        height: parent.height
                        radius: parent.radius
                        color: goal.over ? Colors.warn : Colors.accent
                        Behavior on width { NumberAnimation { duration: Motion.slow } }
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                    }

                    Rectangle {
                        visible: goal.over
                        anchors.right: parent.right
                        width: parent.width * Math.min(0.6, goal.part - 1)
                        height: parent.height
                        radius: parent.radius
                        color: Colors.bad
                        opacity: 0.7
                    }
                }

                Text {
                    text: goal.over
                        ? Wellbeing.human(Wellbeing.total - face.budgetSeconds) + " over"
                        : Wellbeing.human(face.budgetSeconds - Wellbeing.total) + " left"
                    color: goal.over ? Colors.warn : Colors.fgDim
                    opacity: goal.over ? 0.9 : 0.6
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }
}
