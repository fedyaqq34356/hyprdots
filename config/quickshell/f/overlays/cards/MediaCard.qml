import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: mc
    readonly property Item hero: art
    property color tint: Colors.accent
    property var demo: ({})
    property bool big: false

    MorphSpring {
        id: grow
        springBack: true
        response: 0.56
        damping: 1.0
        epsilon: 0.001
        target: mc.big ? 1 : 0
    }
    readonly property real g: grow.value
    readonly property bool bigOn: mc.big || grow.value > 0.002
    function bm(a, b) { return a + (b - a) * mc.g; }

    readonly property var d: mc.demo && mc.demo.media ? mc.demo.media : null
    readonly property var m: mc.d ? ({
        art: mc.d.art || "", playing: true, title: mc.d.title, label: mc.d.title,
        artist: mc.d.artist, source: "", hasPosition: true, progress: mc.d.progress,
        length: mc.d.length, canPrev: true, canNext: true, canToggle: true
    }) : ({
        art: Media.art, playing: Media.playing, title: Media.title, label: Media.label,
        artist: Media.artist, source: Media.source, hasPosition: Media.hasPosition,
        progress: Media.progress, length: Media.player ? Media.player.length : 0,
        canPrev: Media.canPrev, canNext: Media.canNext, canToggle: Media.canToggle
    })

    property real bass: 0
    property real mid: 0
    property real high: 0
    property real bassT: 0
    property real midT: 0
    property real highT: 0
    property real bassAvg: 0
    property real lastKick: 0
    property int kickAt: 0

    signal kicked()

    Connections {
        target: Cava
        enabled: mc.bigOn && mc.visible
        function onSmoothChanged() {
            const l = Cava.smooth;
            const on = mc.m.playing ? 1 : 0;
            mc.bassT = Math.min(1, ((l[0] || 0) + (l[1] || 0) + (l[2] || 0)) / 2.2) * on;
            mc.midT = Math.min(1, ((l[4] || 0) + (l[5] || 0) + (l[6] || 0)) / 2.0) * on;
            mc.highT = Math.min(1, ((l[8] || 0) + (l[9] || 0) + (l[10] || 0)) / 1.6) * on;
            const now = Date.now();
            if (mc.big && mc.bassT - mc.bassAvg > 0.16 && mc.bassT > 0.35
                && now - mc.lastKick > 230) {
                mc.lastKick = now;
                mc.kicked();
            }
            mc.bassAvg = mc.bassAvg * 0.9 + mc.bassT * 0.1;

            const n = l.length;
            const out = new Array(mc.rays);
            const half = mc.rays / 2;
            for (let i = 0; i < mc.rays; i++) {
                const pos = i < half ? (half - 1 - i) / half : (i - half) / half;
                const f = pos * (n - 1);
                const a = Math.floor(f);
                const b = Math.min(n - 1, a + 1);
                out[i] = n > 0 ? ((l[a] || 0) + ((l[b] || 0) - (l[a] || 0)) * (f - a)) * on : 0;
            }
            mc.rayTarget = out;
        }
    }

    readonly property int rays: 44
    property var rayTarget: []
    property var rayLevels: []

    FrameAnimation {
        running: mc.bigOn && mc.visible
        onTriggered: {
            const dt = Math.min(frameTime, 0.05);
            const up = 1 - Math.exp(-dt / 0.05);
            const down = 1 - Math.exp(-dt / 0.18);
            const on = mc.m.playing ? 1 : 0;
            const ease = (c, t) => c + (t - c) * (t > c ? up : down);
            mc.bass = ease(mc.bass, mc.bassT * on);
            mc.mid = ease(mc.mid, mc.midT * on);
            mc.high = ease(mc.high, mc.highT * on);

            const t = mc.rayTarget;
            const p = mc.rayLevels;
            const out = new Array(mc.rays);
            for (let i = 0; i < mc.rays; i++)
                out[i] = ease(p[i] || 0, (t[i] || 0) * on);
            mc.rayLevels = out;
        }
    }

    PhaseHold { active: mc.bigOn && mc.visible }

    Item {
        id: fog
        visible: mc.bigOn && mc.m.art !== ""
        x: -12
        y: -12
        width: 64
        height: 64
        opacity: (0.42 + 0.16 * mc.bass) * mc.g
        transform: [
            Scale {
                origin.x: 32
                origin.y: 32
                xScale: 1.25 + 0.08 * mc.bass + 0.06 * Phase.wave(11, 0)
                yScale: xScale
            },
            Translate {
                x: (Phase.wave(17, 0.3) - 0.5) * 12
                y: (Phase.wave(13, 0.7) - 0.5) * 8
            },
            Scale {
                xScale: (mc.width + 24) / 64
                yScale: (mc.height + 24) / 64
            }
        ]

        property string shownArt: ""
        property string prevArt: ""
        readonly property string wantArt: mc.bigOn ? mc.m.art : ""
        onWantArtChanged: {
            if (fog.shownArt === fog.wantArt)
                return;
            fog.prevArt = fog.shownArt;
            fog.shownArt = fog.wantArt;
            artSwap.restart();
        }
        Component.onCompleted: fog.shownArt = fog.wantArt

        property real swap: 1
        NumberAnimation {
            id: artSwap
            target: fog; property: "swap"
            from: 0; to: 1; duration: 1400
            easing.type: Easing.InOutCubic
        }

        rotation: Phase.wave(23, 0.1) * 40 - 20

        Image {
            id: fogPrev
            anchors.fill: parent
            visible: false
            source: fog.prevArt
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 64
            sourceSize.height: 64
        }

        MultiEffect {
            anchors.fill: parent
            source: fogPrev
            visible: fog.swap < 0.999 && fog.prevArt !== ""
            opacity: 1 - fog.swap
            blurEnabled: true
            blur: 1.0
            blurMax: 24
            saturation: 0.6
            autoPaddingEnabled: false
            layer.enabled: true
        }

        Image {
            id: fogImg
            anchors.fill: parent
            visible: false
            source: fog.shownArt
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 64
            sourceSize.height: 64
        }

        MultiEffect {
            anchors.fill: parent
            source: fogImg
            opacity: fog.swap
            blurEnabled: true
            blur: 1.0
            blurMax: 24
            saturation: 0.6
            autoPaddingEnabled: false
            layer.enabled: true
        }
    }

    Rectangle {
        visible: mc.bigOn
        opacity: mc.g
        anchors.fill: parent
        anchors.margins: -12
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.15) }
            GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.55) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.82) }
        }
    }

    Rectangle {
        id: kickFlash
        visible: mc.bigOn && opacity > 0.005
        anchors.fill: parent
        anchors.margins: -12
        opacity: 0
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Colors.alpha(Qt.lighter(mc.tint, 1.3), 0.45) }
            GradientStop { position: 0.5; color: Colors.alpha(mc.tint, 0.10) }
            GradientStop { position: 1.0; color: "transparent" }
        }
        SequentialAnimation {
            id: kickFlashRun
            NumberAnimation {
                target: kickFlash; property: "opacity"
                to: 0.38; duration: 110
                easing.type: Easing.OutSine
            }
            NumberAnimation {
                target: kickFlash; property: "opacity"
                to: 0; duration: 820
                easing.type: Easing.OutCubic
            }
        }
        Connections {
            target: mc
            function onKicked() { kickFlashRun.restart(); }
        }
    }

    Row {
        visible: mc.bigOn
        anchors.bottom: parent.bottom
        anchors.bottomMargin: -12
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 5
        opacity: 0.26 * mc.g

        Repeater {
            model: mc.bigOn ? mc.rays : 0

            Rectangle {
                required property int index
                readonly property real v: mc.rayLevels[index] || 0
                anchors.bottom: parent.bottom
                width: 6
                height: 3 + v * 34
                radius: 3
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(mc.tint, 1.5) }
                    GradientStop { position: 1.0; color: Colors.alpha(mc.tint, 0) }
                }
            }
        }
    }

    property int sparkAt: 0

    Repeater {
        model: mc.bigOn ? 12 : 0

        Rectangle {
            id: mote
            required property int index
            property real p: 1
            property real dx: 40
            property real dy: -60
            property real sz: 4
            readonly property real ox: art.x + art.width / 2
            readonly property real oy: head.y + art.y + art.height / 2

            width: mote.sz
            height: mote.sz
            radius: mote.sz / 2
            x: mote.ox + mote.dx * mote.p - mote.sz / 2
            y: mote.oy + mote.dy * mote.p - 30 * mote.p * mote.p - mote.sz / 2
            color: Qt.lighter(mc.tint, 1.6)
            opacity: mote.p >= 1 ? 0 : Math.min(1, mote.p * 7) * (1 - mote.p) * 0.9 * mc.g
            visible: opacity > 0.01
            z: 4

            NumberAnimation {
                id: moteRun
                target: mote; property: "p"
                from: 0; to: 1; duration: 1300
                easing.type: Easing.OutCubic
            }

            Connections {
                target: mc
                function onKicked() {
                    const slot = mc.sparkAt % 4;
                    if (Math.floor(mote.index / 3) !== slot)
                        return;
                    const a = -Math.PI / 2 + (Math.random() - 0.3) * 1.6;
                    const r = 60 + Math.random() * 70;
                    mote.dx = Math.cos(a) * r + 30;
                    mote.dy = Math.sin(a) * r * 0.6;
                    mote.sz = 2.5 + Math.random() * 3.5;
                    moteRun.restart();
                }
            }
        }
    }

    Connections {
        target: mc
        function onKicked() { mc.sparkAt++; }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -12
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Colors.alpha(mc.tint, 0.20) }
            GradientStop { position: 0.55; color: Colors.alpha(mc.tint, 0.04) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Item {
        id: head
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: mc.bm(56, 120)

        Repeater {
            model: mc.bigOn ? 3 : 0

            Rectangle {
                required property int index
                readonly property real lvl: index === 0 ? mc.bass : index === 1 ? mc.mid : mc.high
                readonly property real grow: 5 + index * 8 + lvl * (10 + index * 3)
                anchors.centerIn: art
                width: art.width * art.scale + grow * 2
                height: width
                radius: art.radius * art.scale + grow
                color: "transparent"
                antialiasing: true
                border.width: index === 0 ? 2 : 1.5
                border.color: Qt.lighter(mc.tint, 1.2 + 0.2 * index)
                opacity: (0.10 + 0.6 * lvl) * (1 - index * 0.22) * mc.g
            }
        }

        Repeater {
            model: mc.bigOn ? 3 : 0

            Rectangle {
                id: wave
                required property int index
                property real p: 1
                readonly property real g: 2 + 52 * (1 - Math.pow(1 - wave.p, 3))
                anchors.centerIn: art
                width: art.width * art.scale + g * 2
                height: width
                radius: art.radius * art.scale + g
                color: "transparent"
                antialiasing: true
                border.width: 2
                border.color: Qt.lighter(mc.tint, 1.35)
                opacity: wave.p >= 1 ? 0
                    : Math.min(1, wave.p * 6) * Math.pow(1 - wave.p, 1.6) * 0.7 * mc.g
                visible: opacity > 0.01

                NumberAnimation {
                    id: waveRun
                    target: wave; property: "p"
                    from: 0; to: 1; duration: 1000
                }

                Connections {
                    target: mc
                    function onKicked() {
                        if (mc.kickAt % 3 === wave.index)
                            waveRun.restart();
                    }
                }
            }
        }

        Connections {
            target: mc
            function onKicked() { mc.kickAt++; }
        }

        RectangularShadow {
            visible: mc.bigOn
            opacity: mc.g
            anchors.centerIn: art
            width: art.width * art.scale
            height: width
            radius: art.radius
            blur: 26 + 18 * mc.bass
            spread: 2 * mc.bass
            offset.y: 6
            color: Colors.alpha(mc.tint, 0.35 + 0.4 * mc.bass)
        }

        Image {
            anchors.centerIn: art
            width: art.width * 1.6
            height: art.height * 1.6
            visible: mc.m.art !== ""
            source: mc.m.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 48
            opacity: 0.55 * art.opacity

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 40
                blur: 1.0
                saturation: 0.5
            }
        }

        ClippingRectangle {
            id: art
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: mc.bm(0, 6)
            width: mc.bm(56, 108)
            height: width
            radius: mc.bm(14, 24)
            color: Colors.alpha(mc.tint, 0.25)
            property real rest: mc.m.playing ? 1 : 0.88
            Behavior on rest { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
            scale: rest * (1 + 0.035 * mc.bass * mc.g)

            Image {
                id: artImg
                anchors.fill: parent
                visible: mc.m.art !== ""
                source: mc.m.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                sourceSize.width: 320
            }

            Vinyl {
                anchors.fill: parent
                visible: mc.m.art === ""
                spinning: mc.m.playing
            }

            Rectangle {
                id: artFlash
                anchors.fill: parent
                color: Colors.fg
                opacity: 0
            }

            Connections {
                target: Media
                function onArtChanged() { artFlashRun.restart(); }
            }

            NumberAnimation {
                id: artFlashRun
                target: artFlash; property: "opacity"
                from: 0.35; to: 0; duration: 520
                easing.type: Easing.OutCubic
            }
        }

        Rectangle {
            anchors.fill: art
            scale: art.scale
            radius: art.radius
            color: "transparent"
            border.width: 1
            border.color: Colors.alpha(Colors.fg, 0.10)
            antialiasing: true
        }

        Column {
            anchors.left: art.right
            id: lines
            anchors.leftMargin: mc.bm(12, 26)
            anchors.right: eq.left
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            spacing: mc.bm(2, 4)

            Text {
                visible: mc.bigOn && mc.m.source !== ""
                height: implicitHeight * mc.g
                opacity: mc.g * mc.g
                text: mc.m.source.toUpperCase()
                color: Colors.alpha(Colors.fg, 0.45)
                font.family: Fonts.display
                font.pixelSize: 10
                font.weight: Font.DemiBold
                font.letterSpacing: 1.6
            }

            Item {
                id: titleBox
                readonly property int px: mc.big ? 22 : 15
                readonly property real k: mc.bm(15, 22) / titleBox.px
                width: parent.width
                height: mc.bm(title.implicitHeight * 15 / titleBox.px, 28)

                Marquee {
                    id: title
                    width: titleBox.width / titleBox.k
                    height: titleBox.height / titleBox.k
                    transformOrigin: Item.TopLeft
                    scale: titleBox.k
                    text: mc.m.title !== "" ? mc.m.title : mc.m.label
                    color: Colors.fg
                    family: Fonts.display
                    pixelSize: titleBox.px
                    weight: mc.big ? Font.Bold : Font.DemiBold
                    fade: mc.big ? 22 : 16
                }
            }

            Item {
                id: artistBox
                readonly property int px: mc.big ? 15 : 13
                readonly property real k: mc.bm(13, 15) / artistBox.px
                width: parent.width
                height: mc.bm(artist.implicitHeight * 13 / artistBox.px, 20)

                Marquee {
                    id: artist
                    width: artistBox.width / artistBox.k
                    height: artistBox.height / artistBox.k
                    transformOrigin: Item.TopLeft
                    scale: artistBox.k
                    text: mc.m.artist !== "" ? mc.m.artist : mc.m.source
                    color: Qt.tint(Colors.alpha(Colors.fg, 0.55),
                                   Colors.alpha(Qt.lighter(mc.tint, 1.45), mc.g))
                    family: Fonts.display
                    pixelSize: artistBox.px
                    weight: mc.big ? Font.Medium : Font.Normal
                    fade: mc.big ? 22 : 16
                }
            }
        }

        IslandBars {
            id: eq
            anchors.right: parent.right
            anchors.rightMargin: 4
            anchors.verticalCenter: parent.verticalCenter
            width: mc.bm(30, 52)
            height: mc.bm(24, 40)
            count: mc.big ? 7 : 6
            tint: mc.tint
            live: mc.visible
        }
    }

    Item {
        id: seek
        anchors.top: head.bottom
        anchors.topMargin: mc.bm(12, 14)
        anchors.left: parent.left
        anchors.right: parent.right
        height: 16
        visible: mc.m.hasPosition

        property real drag: -1
        readonly property real at: seek.drag >= 0
            ? seek.drag : Math.max(0, Math.min(1, mc.m.progress))
        readonly property real len: mc.m.length

        Text {
            id: atText
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            text: Media.clock(seek.at * seek.len)
            color: Colors.alpha(Colors.fg, track.hot ? 0.85 : 0.5)
            Behavior on color { ColorAnimation { duration: Motion.base } }
            font.family: Fonts.mono
            font.pixelSize: 10
        }

        Text {
            id: endText
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 38
            horizontalAlignment: Text.AlignRight
            text: "-" + Media.clock(Math.max(0, (1 - seek.at) * seek.len))
            color: Colors.alpha(Colors.fg, track.hot ? 0.85 : 0.5)
            Behavior on color { ColorAnimation { duration: Motion.base } }
            font.family: Fonts.mono
            font.pixelSize: 10
        }

        Item {
            id: track
            anchors.left: atText.right
            anchors.right: endText.left
            anchors.leftMargin: 6
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter

            readonly property bool hot: trackHover.hovered || seek.drag >= 0
            property real thick: track.hot ? 1 : 0
            Behavior on thick { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
            height: mc.bm(3 + 3 * track.thick, 6 + 4 * track.thick)

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Colors.alpha(Colors.fg, 0.16)
            }

            RectangularShadow {
                visible: mc.bigOn
                opacity: mc.g
                width: Math.max(parent.height, parent.width * seek.at)
                height: parent.height
                radius: height / 2
                blur: 10 + 10 * mc.bass
                color: Colors.alpha(mc.tint, 0.35 + 0.5 * mc.bass)
            }

            Rectangle {
                width: Math.max(parent.height, parent.width * seek.at)
                height: parent.height
                radius: height / 2
                antialiasing: true
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: mc.tint }
                    GradientStop { position: 1.0; color: Qt.lighter(mc.tint, 1.5) }
                }
                Behavior on width {
                    enabled: seek.drag < 0
                    NumberAnimation { duration: Motion.base }
                }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -8
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: false

                function frac(mx) {
                    return Math.max(0, Math.min(1, (mx - 8) / track.width));
                }

                onPressed: mouse => seek.drag = frac(mouse.x)
                onPositionChanged: mouse => { if (pressed) seek.drag = frac(mouse.x); }
                onReleased: mouse => {
                    if (!mc.d) Media.seekTo(frac(mouse.x));
                    seek.drag = -1;
                }
                onCanceled: seek.drag = -1
            }

        }

        HoverHandler { id: trackHover }
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: mc.bm(-6, -4)
        spacing: mc.bm(26, 46)

        IslandKey {
            anchors.verticalCenter: parent.verticalCenter
            glyph: "󰒮"
            size: mc.big ? 26 : 22
            scale: mc.bm(22, 26) / size
            enabled: mc.m.canPrev
            onActivated: if (!mc.d) Media.previous()
        }

        Item {
            width: mc.bm(48, 56)
            height: width
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                visible: mc.bigOn
                opacity: mc.g
                anchors.centerIn: parent
                width: parent.width * (0.95 + 0.3 * mc.bass)
                height: width
                radius: width / 2
                color: Colors.alpha(mc.tint, 0.06 + 0.12 * mc.bass)
                border.width: 1.5
                border.color: Colors.alpha(Qt.lighter(mc.tint, 1.3), 0.15 + 0.5 * mc.bass)
                antialiasing: true
            }

            Item {
                anchors.fill: parent
                scale: mc.bm(30, 36) / (mc.big ? 36 : 30)

                IslandKey {
                    anchors.centerIn: parent
                    glyph: "󰏤"
                    size: mc.big ? 36 : 30
                    enabled: mc.m.canToggle
                    opacity: mc.m.playing ? 1 : 0
                    scale: mc.m.playing ? 1 : 0.4
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                    Behavior on scale { Spring {} }
                    onActivated: if (!mc.d) Media.toggle()
                }

                IslandKey {
                    anchors.centerIn: parent
                    glyph: "󰐊"
                    size: mc.big ? 36 : 30
                    enabled: mc.m.canToggle
                    opacity: mc.m.playing ? 0 : 1
                    scale: mc.m.playing ? 0.4 : 1
                    visible: opacity > 0.01
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                    Behavior on scale { Spring {} }
                    onActivated: if (!mc.d) Media.toggle()
                }
            }
        }

        IslandKey {
            anchors.verticalCenter: parent.verticalCenter
            glyph: "󰒭"
            size: mc.big ? 26 : 22
            scale: mc.bm(22, 26) / size
            enabled: mc.m.canNext
            onActivated: if (!mc.d) Media.next()
        }
    }
}
