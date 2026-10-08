import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: drip

    required property var l
    property bool open: false

    readonly property bool known: IslandBus.isleW > 0
    readonly property real cx: drip.known ? IslandBus.isleX + IslandBus.isleW / 2 : drip.width / 2
    readonly property real base: drip.known ? IslandBus.isleY + IslandBus.isleH : 47
    readonly property real isleW: drip.known ? IslandBus.isleW : IslandBus.searchW

    readonly property int off: 0

    readonly property bool typed: drip.l.calcMode || drip.l.runMode
                                  || IslandBus.query.trim() !== ""
    readonly property var best: !drip.l.calcMode && !drip.l.runMode && drip.typed
                               ? (drip.l.results[0] || null) : null
    readonly property string kind: drip.l.runMode ? "run" : drip.l.calcMode ? "calc"
                                 : drip.best ? "app" : ""

    readonly property bool want: drip.open && drip.kind !== "" && !drip.leaving

    ArtTint {
        id: art
        x: drip.cx
        y: 0
        source: drip.best && drip.best.icon
            ? drip.iconOf(drip.best) : ""
        fallback: Colors.accent
    }
    readonly property color hue: drip.kind === "app" && art.found ? art.color : Colors.accent
    readonly property bool hueOn: drip.kind === "app" && art.found

    property color glow: drip.hue
    Behavior on glow { ColorAnimation { duration: 1000; easing.type: Easing.InOutCubic } }

    property bool leaving: false
    function fly(slotIndex, info) {
        drip.leaving = true;
        launchLater.info = info;
        launchLater.restart();
    }
    Timer {
        id: launchLater
        property var info: null
        interval: 300
        onTriggered: {
            if (launchLater.info)
                IslandBus.launching(launchLater.info);
            launchLater.info = null;
        }
    }
    onOpenChanged: if (drip.open) drip.leaving = false

    MorphSpring {
        id: life
        response: 0.72
        damping: 0.96
        closeMs: 420
        softClose: true
        target: drip.want ? 1 : 0
    }

    readonly property real g: Math.max(0, life.value)
    readonly property real cardW: 440
    readonly property real cardH: drip.kind === "app" ? 96 : 84
    property real shownH: drip.cardH
    Behavior on shownH { NumberAnimation { duration: 560; easing.type: Easing.InOutCubic } }

    readonly property real bw: Motion.mix(drip.isleW * 0.42, drip.cardW, drip.g)
    readonly property real bh: Motion.mix(18, drip.shownH, drip.g)
    readonly property real by: Motion.mix(drip.base - 16, drip.base + 10, drip.g)

    readonly property bool living: life.value > 0.005 || drip.open
    readonly property bool holding: drip.leaving && life.value > 0.12

    RectangularShadow {
        x: drip.cx - drip.bw / 2
        y: drip.by + 10
        width: drip.bw
        height: drip.bh
        radius: 34
        blur: 70
        spread: -6
        color: Colors.alpha(drip.glow, 0.32)
        opacity: drip.g
        visible: opacity > 0.01
    }

    Item {
        id: host
        x: drip.cx - 320
        y: drip.base - 24
        width: 640
        height: 300

        Item {
            id: twin
            property bool isBlob: true
            width: Math.min(drip.isleW - 44, 260)
            height: 8
            x: drip.cx - width / 2 - host.x
            y: drip.base - 8 - host.y
            visible: drip.g > 0.005
            onXChanged: goo.requestSync()
            onYChanged: goo.requestSync()
            onWidthChanged: goo.requestSync()
            onVisibleChanged: goo.requestSync()
        }

        Item {
            id: body
            property bool isBlob: true
            width: drip.bw
            height: drip.bh
            x: drip.cx - width / 2 - host.x
            y: drip.by - host.y
            visible: drip.g > 0.005
            onXChanged: goo.requestSync()
            onYChanged: goo.requestSync()
            onWidthChanged: goo.requestSync()
            onHeightChanged: goo.requestSync()
            onVisibleChanged: goo.requestSync()
        }
    }

    Blobs {
        id: goo
        host: host
        fuse: 22
        corner: 28
        stroke: 0
        shadow: false
        fillColor: "black"
        fillAlpha: 1
        strokeAlpha: 0
        visible: count > 0 && drip.g > 0.005
    }

    ClippingRectangle {
        id: card

        x: drip.cx - drip.bw / 2
        y: drip.by
        width: drip.bw
        height: drip.bh
        radius: Math.min(28, height / 2)
        color: "transparent"

        opacity: Math.max(0, Math.min(1, (drip.g - 0.55) / 0.45))
        visible: opacity > 0.01

        property real t: 0

        property real kick: 0
        SequentialAnimation {
            id: kickRun
            NumberAnimation { target: card; property: "kick"; to: 1; duration: 160; easing.type: Easing.OutCubic }
            NumberAnimation { target: card; property: "kick"; to: 0; duration: 1200; easing.type: Easing.InOutSine }
        }
        Connections {
            target: IslandBus
            function onKeyed(dir) { if (card.visible) kickRun.restart(); }
        }
        NumberAnimation on t {
            running: card.visible
            loops: Animation.Infinite
            from: 0; to: Math.PI * 2
            duration: 9000
        }

        RectangularShadow {
            x: card.width * (0.10 + 0.10 * Math.sin(card.t)) - 40
            y: card.height * (0.25 + 0.18 * Math.cos(card.t * 2)) - 50
            width: 170
            height: 130
            radius: 65
            blur: 70
            color: Colors.alpha(drip.glow, 0.42 + 0.22 * card.kick)
        }
        RectangularShadow {
            x: card.width * (0.62 + 0.14 * Math.cos(card.t)) - 40
            y: card.height * (0.55 + 0.20 * Math.sin(card.t * 2 + 1)) - 60
            width: 190
            height: 140
            radius: 70
            blur: 80
            color: Colors.alpha(Qt.lighter(drip.glow, 1.3), 0.20)
        }

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 80
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.16) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Rectangle {
            id: gloss
            width: 140
            height: card.height * 2.4
            anchors.verticalCenter: parent.verticalCenter
            rotation: 18
            opacity: 0
            visible: opacity > 0.01
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.07) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            SequentialAnimation {
                id: glossRun
                ParallelAnimation {
                    NumberAnimation { target: gloss; property: "x"; from: -200; to: card.width + 60; duration: 1100; easing.type: Easing.InOutCubic }
                    SequentialAnimation {
                        NumberAnimation { target: gloss; property: "opacity"; to: 1; duration: 300 }
                        PauseAnimation { duration: 400 }
                        NumberAnimation { target: gloss; property: "opacity"; to: 0; duration: 400 }
                    }
                }
            }
        }

        property var face: null
        property string faceKind: ""
        readonly property string wantKey: drip.kind === "app" && drip.best
            ? "app:" + (drip.best.id || drip.best.name) : drip.kind

        onWantKeyChanged: {
            if (drip.kind === "")
                return;
            if (card.faceKind === "") {
                card.face = drip.best;
                card.faceKind = drip.kind;
                faceIn.restart();
                glossRun.restart();
                return;
            }
            swap.restart();
        }

        SequentialAnimation {
            id: swap
            ParallelAnimation {
                NumberAnimation { target: face; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InOutCubic }
                NumberAnimation { target: face; property: "lift"; to: -6; duration: 200; easing.type: Easing.InOutCubic }
            }
            ScriptAction {
                script: {
                    card.face = drip.best;
                    card.faceKind = drip.kind;
                    if (drip.kind === "app")
                        glossRun.restart();
                }
            }
            ScriptAction { script: faceIn.restart() }
        }

        ParallelAnimation {
            id: faceIn
            NumberAnimation { target: face; property: "opacity"; from: 0; to: 1; duration: 520; easing.type: Easing.OutCubic }
            NumberAnimation { target: face; property: "lift"; from: 8; to: 0; duration: 620; easing.type: Easing.OutCubic }
            NumberAnimation { target: face; property: "iconIn"; from: 0.92; to: 1; duration: 700; easing.type: Easing.OutCubic }
        }

        Item {
            id: face
            anchors.fill: parent
            property real lift: 0
            property real iconIn: 1
            transform: Translate { y: face.lift }

            Item {
                anchors.fill: parent
                visible: card.faceKind === "app" && card.face !== null
                opacity: 0.5 + 0.2 * card.kick

                IconImage {
                    width: 300
                    height: 300
                    implicitSize: 300
                    x: 60 + Math.sin(card.t) * 24 - width / 2
                    y: card.height / 2 + Math.cos(card.t * 2) * 10 - height / 2
                    rotation: card.t * 180 / Math.PI
                    source: card.face ? drip.iconOf(card.face) : ""
                    asynchronous: true
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 64
                        saturation: 0.25
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.15) }
                        GradientStop { position: 0.55; color: Qt.rgba(0, 0, 0, 0.6) }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
                    }
                }
            }

            Item {
                anchors.fill: parent
                visible: card.faceKind === "app" && card.face !== null

                readonly property var e: card.face

                Item {
                    id: iconBox
                    x: 18
                    anchors.verticalCenter: parent.verticalCenter
                    width: 60
                    height: 60

                    RectangularShadow {
                        anchors.centerIn: parent
                        width: 46
                        height: 46
                        radius: 23
                        blur: 24
                        color: Colors.alpha(drip.glow, 0.55 + 0.15 * Math.sin(card.t * 3) + 0.3 * card.kick)
                    }

                    IconImage {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: Math.sin(card.t * 2) * 2.5
                        implicitSize: 48
                        scale: face.iconIn * (1 + 0.018 * Math.sin(card.t * 3) + 0.04 * card.kick)
                        source: parent.parent.e
                            ? drip.iconOf(parent.parent.e) : ""
                        asynchronous: true
                    }
                }

                Column {
                    anchors.left: iconBox.right
                    anchors.leftMargin: 14
                    anchors.right: hintPill.left
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        width: parent.width
                        textFormat: Text.StyledText
                        text: drip.marked(parent.parent.e ? parent.parent.e.name : "")
                        color: "white"
                        font.family: Fonts.display
                        font.pixelSize: 18
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Text {
                        width: parent.width
                        visible: text !== ""
                        text: parent.parent.e ? (parent.parent.e.genericName || parent.parent.e.comment || "") : ""
                        color: Qt.rgba(1, 1, 1, 0.5)
                        font.family: Fonts.display
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }

                }

                Rectangle {
                        id: hintPill
                        anchors.right: parent.right
                        anchors.rightMargin: 20
                        anchors.verticalCenter: parent.verticalCenter
                        height: 23
                        width: hintRow.implicitWidth + 20
                        radius: 11.5
                        color: Colors.alpha(drip.glow, 0.18)
                        border.width: 1
                        border.color: Colors.alpha(drip.glow, 0.32)

                        Row {
                            id: hintRow
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Running.any ? "󰖯" : "󰌑"
                                color: Qt.lighter(drip.glow, 1.3)
                                font.family: Fonts.glyph
                                font.pixelSize: 12
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Running.any
                                    ? (Running.workspaces.length === 1
                                       ? "Running on desk " + Running.workspaces[0]
                                       : "Running on " + Running.workspaces.length + " desks")
                                    : "Open"
                                color: Qt.lighter(drip.glow, 1.3)
                                font.family: Fonts.display
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }
                        }
                    }
            }

            Column {
                visible: card.faceKind === "calc"
                anchors.right: parent.right
                anchors.rightMargin: 26
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    anchors.right: parent.right
                    text: drip.l.calcExpr !== "" ? drip.l.calcExpr : " "
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: Fonts.display
                    font.pixelSize: 14
                }

                RollText {
                    anchors.right: parent.right
                    text: drip.l.calcResult !== "" ? drip.l.calcResult : "—"
                    color: "white"
                    family: Fonts.display
                    pixelSize: 36
                    weight: Font.DemiBold
                    rollDuration: 360
                    overshoot: 0.6
                }
            }

            Text {
                visible: card.faceKind === "calc"
                x: 26
                anchors.verticalCenter: parent.verticalCenter
                text: "󰃬"
                color: Qt.lighter(drip.glow, 1.2)
                font.family: Fonts.glyph
                font.pixelSize: 24
            }

            Column {
                visible: card.faceKind === "run"
                x: 26
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - 52
                spacing: 8

                Text {
                    width: parent.width
                    text: "$ " + drip.l.runCmd
                    color: "white"
                    font.family: Fonts.glyph
                    font.pixelSize: 15
                    elide: Text.ElideRight
                }
                Text {
                    text: "↵  Run in shell"
                    color: Qt.rgba(1, 1, 1, 0.45)
                    font.family: Fonts.display
                    font.pixelSize: 12
                }
            }
        }

        TapHandler { onTapped: drip.l.accept() }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
    }

    function iconOf(e) {
        const i = e && e.icon ? e.icon : "";
        if (i.startsWith("/"))
            return "file://" + i;
        return Quickshell.iconPath(i, "application-x-executable");
    }

    function marked(name) {
        const q = IslandBus.query.trim().toLowerCase();
        const esc = s => s.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        const i = q === "" ? -1 : name.toLowerCase().indexOf(q);
        if (i < 0)
            return esc(name);
        const dim = "<font color=\"#8cffffff\">";
        return dim + esc(name.slice(0, i)) + "</font>"
            + esc(name.slice(i, i + q.length))
            + dim + esc(name.slice(i + q.length)) + "</font>";
    }
}
