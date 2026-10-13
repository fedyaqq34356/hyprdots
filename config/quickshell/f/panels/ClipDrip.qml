import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: drip

    required property var c
    property bool open: false

    readonly property bool known: IslandBus.isleW > 0
    readonly property real cx: drip.known ? IslandBus.isleX + IslandBus.isleW / 2 : drip.width / 2
    readonly property real base: drip.known ? IslandBus.isleY + IslandBus.isleH : 47
    readonly property real isleW: drip.known ? IslandBus.isleW : IslandBus.searchW

    readonly property var entry: drip.c.results.length > 0
        ? drip.c.results[Math.max(0, Math.min(drip.c.index, drip.c.results.length - 1))] : null
    readonly property bool want: drip.open && !drip.leaving

    MorphSpring {
        id: lean
        springBack: true
        response: 0.42
        damping: 0.9
        epsilon: 0.002
        target: 0
    }
    Timer { id: leanBack; interval: 110; onTriggered: lean.target = 0 }

    function flip(dir) {
        lean.target = dir;
        leanBack.restart();
        card.go(dir);
    }

    property bool leaving: false
    onOpenChanged: if (drip.open) drip.leaving = false
    function take() {
        drip.leaving = true;
    }

    MorphSpring {
        id: life
        response: 0.72
        damping: 0.96
        closeMs: 420
        softClose: true
        target: drip.want ? 1 : 0
    }

    readonly property real g: Math.max(0, life.value)
    readonly property bool living: life.value > 0.005 || drip.open
    readonly property bool holding: drip.leaving && life.value > 0.12

    readonly property real cardW: 520
    readonly property real wantH: {
        const e = card.face;
        if (!e)
            return 120;
        if (e.isImage) {
            const a = preview.status === Image.Ready && preview.implicitHeight > 0
                ? preview.implicitWidth / preview.implicitHeight : 16 / 9;
            return Math.max(170, Math.min(320, (drip.cardW - 24) / a + 24));
        }
        return Math.max(110, Math.min(300, bodyText.implicitHeight + 86));
    }
    property real shownH: drip.wantH
    Behavior on shownH { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }

    readonly property real stretch: lean.value
    readonly property real bw: Motion.mix(drip.isleW * 0.42, drip.cardW, drip.g)
                               * (1 + 0.05 * Math.abs(drip.stretch))
    readonly property real bh: Motion.mix(18, drip.shownH, drip.g)
                               * (1 - 0.03 * Math.abs(drip.stretch))
    readonly property real by: Motion.mix(drip.base - 16, drip.base + 12, drip.g)
    readonly property real bx: drip.cx - drip.bw / 2 + 18 * drip.stretch

    ArtTint {
        id: art
        x: drip.cx
        y: 0
        source: card.face && card.face.isImage ? drip.c.previewOf(card.face) : ""
        fallback: Colors.accent
    }
    readonly property color hue: !card.face ? Colors.accentAlt
        : card.face.isImage ? (art.found ? art.color : Colors.accent)
        : card.face.kind === "link" ? Colors.accent
        : card.face.kind === "path" ? Colors.warn
        : Colors.accentAlt
    property color glow: drip.hue
    Behavior on glow { ColorAnimation { duration: 900; easing.type: Easing.InOutCubic } }

    RectangularShadow {
        x: drip.bx
        y: drip.by + 10
        width: drip.bw
        height: drip.bh
        radius: 34
        blur: 70
        spread: -6
        color: Colors.alpha(drip.glow, 0.30)
        opacity: drip.g
        visible: opacity > 0.01
    }

    Item {
        id: host
        x: drip.cx - 360
        y: drip.base - 24
        width: 720
        height: 420

        Item {
            id: twin
            property bool isBlob: true
            width: Math.min(drip.isleW - 44, 260)
            height: 8
            x: drip.cx - width / 2 - host.x
            y: drip.base - 8 - host.y
            visible: drip.g > 0.005
        }

        Item {
            id: body
            property bool isBlob: true
            width: drip.bw
            height: drip.bh
            x: drip.bx - host.x
            y: drip.by - host.y
            visible: drip.g > 0.005
        }
    }

    onBxChanged: goo.applySync()
    onByChanged: goo.applySync()
    onBwChanged: goo.applySync()
    onBhChanged: goo.applySync()
    onCxChanged: goo.applySync()

    Blobs {
        id: goo
        host: host
        fuse: 22
        corner: 28
        stroke: 0
        shadow: false
        fillColor: "black"
        fillAlpha: 1
        hoverColor: "black"
        hoverAlpha: 1
        strokeAlpha: 0
        visible: count > 0 && drip.g > 0.005
    }

    ClippingRectangle {
        id: card

        x: drip.bx
        y: drip.by
        width: drip.bw
        height: drip.bh
        radius: Math.min(28, height / 2)
        color: "transparent"

        opacity: Math.max(0, Math.min(1, (drip.g - 0.55) / 0.45))
        visible: opacity > 0.01

        readonly property real t: card.visible ? (Phase.ts % 10) / 10 * Math.PI * 2 : 0
        PhaseHold { active: card.visible; slow: true }

        RectangularShadow {
            x: card.width * (0.12 + 0.10 * Math.sin(card.t)) - 40
            y: card.height * (0.30 + 0.16 * Math.cos(card.t * 2)) - 50
            width: 190
            height: 140
            radius: 70
            blur: 80
            color: Colors.alpha(drip.glow, 0.34)
        }
        RectangularShadow {
            x: card.width * (0.62 + 0.14 * Math.cos(card.t)) - 40
            y: card.height * (0.55 + 0.18 * Math.sin(card.t * 2 + 1)) - 60
            width: 210
            height: 150
            radius: 75
            blur: 90
            color: Colors.alpha(Qt.lighter(drip.glow, 1.3), 0.16)
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

        property var face: null
        property int dir: 1
        readonly property string wantKey: drip.entry ? drip.entry.id : ""

        onWantKeyChanged: {
            if (!drip.entry)
                return;
            if (card.face === null) {
                card.face = drip.entry;
                faceIn.restart();
                return;
            }
            swap.restart();
        }

        function go(d) {
            card.dir = d;
        }

        SequentialAnimation {
            id: swap
            ParallelAnimation {
                NumberAnimation { target: face; property: "opacity"; to: 0; duration: 170; easing.type: Easing.InCubic }
                NumberAnimation { target: face; property: "shift"; to: 26 * card.dir; duration: 170; easing.type: Easing.InCubic }
                NumberAnimation { target: face; property: "haze"; to: 1; duration: 170 }
            }
            ScriptAction { script: card.face = drip.entry }
            ScriptAction { script: faceIn.restart() }
        }

        ParallelAnimation {
            id: faceIn
            NumberAnimation { target: face; property: "opacity"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic }
            NumberAnimation { target: face; property: "shift"; from: -30 * card.dir; to: 0; duration: 520; easing.type: Easing.OutCubic }
            NumberAnimation { target: face; property: "haze"; from: 1; to: 0; duration: 420; easing.type: Easing.OutCubic }
        }

        Item {
            id: face
            anchors.centerIn: parent
            width: drip.cardW
            height: drip.shownH
            property real shift: 0
            property real haze: 0
            transform: Translate { x: face.shift }

            layer.enabled: face.haze > 0.01
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 32
                blur: face.haze
                autoPaddingEnabled: false
            }

            readonly property var e: card.face

            ClippingRectangle {
                visible: face.e !== null && face.e.isImage
                anchors.fill: parent
                anchors.margins: 12
                radius: 18
                color: Qt.rgba(1, 1, 1, 0.04)

                Image {
                    id: preview
                    anchors.fill: parent
                    source: face.e && face.e.isImage && !drip.c.decoding
                        ? drip.c.previewOf(face.e) : ""
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    cache: false
                    smooth: true
                    sourceSize.width: 1000
                }

                Text {
                    anchors.centerIn: parent
                    visible: preview.status !== Image.Ready
                    text: "󰋩"
                    color: Qt.rgba(1, 1, 1, 0.3)
                    font.family: Fonts.glyph
                    font.pixelSize: Fonts.giant
                }
            }

            Item {
                visible: face.e !== null && !face.e.isImage
                anchors.fill: parent
                anchors.leftMargin: 28
                anchors.rightMargin: 28
                anchors.topMargin: 24
                anchors.bottomMargin: 20

                Text {
                    id: bodyText
                    width: parent.width
                    text: face.e && !face.e.isImage ? drip.c.bodyOf(face.e) : ""
                    textFormat: Text.PlainText
                    color: "white"
                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                    maximumLineCount: face.e && face.e.kind === "text" ? 8 : 3
                    elide: Text.ElideRight
                    lineHeight: 1.12
                    font.family: face.e && (face.e.kind === "path" || drip.c.codey(face.e))
                        ? Fonts.mono : Fonts.display
                    font.pixelSize: face.e && face.e.kind === "text" && face.e.body.length < 40 ? 22 : 15
                    font.weight: face.e && face.e.kind === "text" && face.e.body.length < 40
                        ? Font.DemiBold : Font.Normal
                }

                Row {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    spacing: 8

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: face.e ? drip.c.glyphFor(face.e.kind) : ""
                        color: Qt.lighter(drip.glow, 1.3)
                        font.family: Fonts.glyph
                        font.pixelSize: Fonts.medium
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: face.e ? drip.c.metaOf(face.e) : ""
                        color: Qt.rgba(1, 1, 1, 0.45)
                        font.family: Fonts.display
                        font.features: { "tnum": 1 }
                        font.pixelSize: Fonts.text
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 380)
                    }
                }
            }
        }

        Timer { id: wheelRest; interval: 220 }
        TapHandler { onTapped: drip.c.accept() }
        HoverHandler { cursorShape: Qt.PointingHandCursor }
        WheelHandler {
            acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
            property real acc: 0
            onWheel: (ev) => {
                acc += ev.angleDelta.y || ev.angleDelta.x;
                if (Math.abs(acc) < 120 || wheelRest.running)
                    return;
                drip.c.step(acc < 0 ? 1 : -1);
                acc = 0;
                wheelRest.restart();
            }
        }
    }
}
