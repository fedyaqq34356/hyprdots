import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import "root:/design"
import "root:/services"

Item {
    id: em

    property Item card: null
    property var win: null
    property bool open: false
    property bool dock: false
    property bool cache: true
    property real cornerTo: em.card && em.card.radius !== undefined ? em.card.radius : Shape.modal

    readonly property bool on: Prefs.apple

    anchors.fill: parent

    readonly property string screenName: em.win && em.win.screen ? em.win.screen.name : ""
    readonly property int barH: BarConfig.s("barHeight", em.screenName)
    readonly property bool underBar: em.win ? em.win.exclusiveZone >= 0 : true
    readonly property real pillH: IslandConfig.s("pillHeight")
    readonly property real islandCy: em.barH / 2 - (em.underBar ? em.barH : 0)
    readonly property real islandTop: em.islandCy - em.pillH / 2
    readonly property real islandW: 110

    readonly property real fx: em.card ? em.card.x + em.card.width / 2 : em.width / 2
    readonly property real fy: em.card ? em.card.y + em.card.height / 2 : em.height / 2
    readonly property real fw: em.card ? em.card.width : 0
    readonly property real fh: em.card ? em.card.height : 0

    MorphSpring {
        id: grow
        enabled: em.on
        response: 0.44
        damping: 0.86
        closeMs: 380
        softClose: true
        target: em.open ? 1 : (em.leaving ? 1 : 0)
    }

    MorphSpring {
        id: travel
        enabled: em.on
        response: 0.60
        damping: 0.86
        closeMs: 340
        softClose: true
        target: em.go ? 1 : 0
    }

    property bool go: false
    property bool leaving: false

    onOpenChanged: {
        if (!em.on) {
            em.go = em.open;
            return;
        }
        if (em.open) {
            em.revealStarted = false;
            em.leaving = false;
            leave.stop();
            depart.restart();
            Emergence.launch();
        } else {
            depart.stop();
            revealIn.stop();
            revealOut.restart();
            em.revealStarted = false;
            em.go = false;
            em.leaving = true;
            leave.restart();
        }
    }

    Timer { id: depart; interval: 70; onTriggered: em.go = true }
    Timer { id: leave; interval: em.dock ? 20 : 150; onTriggered: em.leaving = false }

    readonly property bool living: em.on && !em.open
        && (grow.value > 0.01 || travel.value > 0.01 || em.leaving)

    Binding {
        target: em.win
        property: "visible"
        value: true
        when: em.living && em.win !== null
    }

    readonly property real g: Math.max(0, grow.value)
    readonly property real t: travel.value

    readonly property real bw: Motion.mix(em.islandW, em.fw, em.g)
    readonly property real bh: Motion.mix(em.pillH, em.fh, em.g)
    readonly property real parkCy: em.islandTop + em.bh / 2 + (em.dock ? 0 : 0)
    readonly property real bcx: Motion.mix(em.width / 2, em.fx, em.t)
    readonly property real bcy: em.dock ? Motion.mix(em.parkCy, em.fy, Math.min(1, em.g))
                                        : Motion.mix(em.parkCy, em.fy, em.t)

    readonly property real stretch: em.on
        ? Math.max(-0.06, Math.min(0.06, travel.velocity * 0.016 + grow.velocity * 0.008))
        : 0

    property real reveal: 0
    readonly property real cardOpacity: em.reveal
    property bool revealStarted: false

    onGChanged: {
        if (em.on && em.open && !em.revealStarted && em.g >= 0.7) {
            em.revealStarted = true;
            revealOut.stop();
            revealIn.restart();
        }
    }

    NumberAnimation {
        id: revealIn
        target: em; property: "reveal"
        to: 1; duration: 460
        easing.type: Easing.Bezier
        easing.bezierCurve: [0.25, 0.1, 0.25, 1.0, 1, 1]
    }

    NumberAnimation {
        id: revealOut
        target: em; property: "reveal"
        to: 0; duration: 220
        easing.type: Easing.InOutSine
    }

    readonly property bool revealing: em.cardOpacity < 0.99 || em.pour < 0.999

    Binding {
        target: em.card
        property: "layer.enabled"
        value: em.on && (em.open || em.cardOpacity > 0.01) && (em.cache || em.revealing)
        when: em.card !== null
    }

    Binding {
        target: em.card
        property: "layer.smooth"
        value: true
        when: em.card !== null && em.on
    }

    Binding {
        target: em.card
        property: "layer.effect"
        value: haze
        when: em.card !== null && em.on && em.revealing
    }

    property real pour: 1
    property bool poured: false
    onCardOpacityChanged: {
        if (em.cardOpacity > 0.01 && !em.poured && em.open) {
            em.poured = true;
            pourRun.restart();
        }
        if (em.cardOpacity <= 0.001)
            em.poured = false;
    }
    NumberAnimation {
        id: pourRun
        target: em; property: "pour"
        from: 0; to: 1; duration: 820
        easing.type: Easing.OutCubic
    }

    ShaderEffect {
        id: pourMask
        visible: false
        layer.enabled: em.on
        width: em.fw
        height: em.fh
        fragmentShader: "root:/design/shaders/pourwave.frag.qsb"
        property real pour: em.pour
        property real aspect: em.fh > 0 ? em.fw / em.fh : 1
    }

    Component {
        id: haze
        MultiEffect {
            autoPaddingEnabled: false
            blurEnabled: true
            blurMax: 32
            blur: 1 - em.cardOpacity
            maskEnabled: em.pour < 0.999
            maskSource: pourMask
            maskThresholdMin: 0.4
            maskSpreadAtMin: 1.0
        }
    }
    readonly property real dx: em.on ? em.bcx - em.fx : 0
    readonly property real dy: em.on ? em.bcy - em.fy : 0

    readonly property bool blobOn: em.on && em.card !== null && (em.g > 0.001 || em.t > 0.001)

    readonly property real bodyW: em.bw * (1 - em.stretch * 0.6)
    readonly property real bodyH: em.bh * (1 + em.stretch)
    readonly property real bodyX: em.bcx - em.bodyW / 2
    readonly property real bodyY: em.bcy - em.bodyH / 2
    readonly property real bodyR:
        Math.min(em.bodyH / 2, Motion.mix(em.pillH / 2, em.cornerTo, em.g))

    readonly property bool isleKnown: IslandBus.isleW > 0
        && IslandBus.isleScreen === em.screenName
    readonly property real isleCx: em.isleKnown
        ? IslandBus.isleX + IslandBus.isleW / 2 : em.width / 2
    readonly property real isleBottom: em.isleKnown
        ? IslandBus.isleY + IslandBus.isleH - (em.underBar ? em.barH : 0)
        : em.islandTop + em.pillH
    readonly property real isleW: em.isleKnown ? IslandBus.isleW : em.islandW

    readonly property bool watching: em.on && (em.open || em.living)
    onWatchingChanged: IslandBus.watch += em.watching ? 1 : -1
    Component.onDestruction: if (em.watching) IslandBus.watch -= 1

    readonly property real ax: em.isleCx
    readonly property real ay: em.isleBottom - 6
    readonly property real bx: Math.max(em.bodyX + em.cornerTo + 24,
                                        Math.min(em.bodyX + em.bodyW - em.cornerTo - 24, em.isleCx))
    readonly property real by: em.bodyY + 10
    readonly property real gap: em.by - em.ay
    readonly property real neckMax: 190
    readonly property int beads: 8

    property real snap: 0

    NumberAnimation {
        id: breakRun
        target: em; property: "snap"
        to: 1; duration: 560
        easing.type: Easing.InOutSine
    }
    NumberAnimation {
        id: mendRun
        target: em; property: "snap"
        to: 0; duration: 300
        easing.type: Easing.OutCubic
    }

    function checkNeck() {
        if (!em.on)
            return;
        if (em.open) {
            const landed = !em.dock && em.t > 0.985 && em.g > 0.985;
            if (em.snap < 1 && !breakRun.running && (em.gap > em.neckMax || landed)) {
                mendRun.stop();
                breakRun.restart();
            }
        } else if (em.snap > 0 && !mendRun.running && em.gap < em.neckMax * 0.8) {
            breakRun.stop();
            mendRun.restart();
        }
    }
    onGapChanged: em.checkNeck()
    onTChanged: em.checkNeck()

    Connections {
        target: em
        function onOpenChanged() {
            if (em.open && em.g < 0.05) {
                breakRun.stop();
                mendRun.stop();
                em.snap = 0;
            }
            em.checkNeck();
        }
    }

    readonly property bool gooLive: em.blobOn
        && !(em.open && em.snap >= 1 && em.t > 0.995 && em.g > 0.995)

    function neckWidth(s) {
        const w0 = Math.min(em.isleW * 0.42, 46);
        const w1 = Math.min(em.bodyW * 0.18, 76);
        const base = Motion.mix(w0, w1, s * s);
        const th = Math.max(0, Math.min(1, 1 - em.gap / em.neckMax));
        const pinch = 1 - (1 - Math.pow(th, 0.7)) * 0.86 * Math.sin(Math.PI * s);
        const mid = 1 - Math.abs(2 * s - 1);
        const cut = Math.max(0, Math.min(1, 1 - em.snap * (1 + 2 * mid)));
        return base * pinch * cut;
    }

    function syncGoo() {
        if (!em.gooLive)
            return;
        twin.width = Math.max(20, em.isleW - 18);
        twin.height = 10;
        twin.x = em.isleCx - twin.width / 2;
        twin.y = em.isleBottom - 14;

        body.x = em.bodyX;
        body.y = em.bodyY;
        body.width = Math.max(1, em.bodyW);
        body.height = Math.max(1, em.bodyH);

        const n = em.beads;
        const on = em.gap > 2;
        const cy = em.ay + em.gap * 0.55;
        const seg = Math.max(0, em.gap) / n;
        for (let i = 0; i < n; i++) {
            const it = beadRow.itemAt(i);
            if (!it)
                continue;
            const s0 = (i + 0.5) / n;
            const w = on ? em.neckWidth(s0) : 0;
            if (w < 1.5) {
                it.visible = false;
                continue;
            }
            const u = s0 < 0.5 ? s0 * (1 - em.snap) : s0 + (1 - s0) * em.snap;
            const px = (1 - u * u) * em.ax + u * u * em.bx;
            const py = (1 - u) * (1 - u) * em.ay + 2 * (1 - u) * u * cy + u * u * em.by;
            it.width = w;
            it.height = Math.max(w, seg * 1.6);
            it.x = px - w / 2;
            it.y = py - it.height / 2;
            it.visible = true;
        }
        goo.applySync();
    }

    onBodyXChanged: em.syncGoo()
    onBodyYChanged: em.syncGoo()
    onBodyWChanged: em.syncGoo()
    onBodyHChanged: em.syncGoo()
    onSnapChanged: em.syncGoo()
    onIsleCxChanged: em.syncGoo()
    onIsleBottomChanged: em.syncGoo()
    onGooLiveChanged: em.syncGoo()

    RectangularShadow {
        visible: em.blobOn
        x: em.bodyX
        y: em.bodyY
        width: em.bodyW
        height: em.bodyH
        radius: em.bodyR
        blur: 22 + 20 * em.g
        spread: 0
        offset.y: 6 * em.g
        color: Colors.alpha(Colors.accent, 0.30 * Math.min(1, em.g * 1.5))
    }

    Item {
        id: gooHost
        anchors.fill: parent

        Item { id: twin; property bool isBlob: true }
        Item { id: body; property bool isBlob: true }
        Repeater {
            id: beadRow
            model: em.beads
            Item { property bool isBlob: true; visible: false }
        }
    }

    Blobs {
        id: goo
        host: gooHost
        visible: em.gooLive && count > 0
        fuse: 22
        corner: em.cornerTo
        stroke: 0
        shadow: false
        fillColor: "black"
        fillAlpha: 1
        hoverColor: "black"
        hoverAlpha: 1
        strokeAlpha: 0
    }

    Rectangle {
        visible: em.blobOn && !em.gooLive
        x: em.bodyX
        y: em.bodyY
        width: em.bodyW
        height: em.bodyH
        radius: em.bodyR
        antialiasing: true
        color: "black"
    }

    PhaseHold { active: em.on && em.open; slow: true }

    property real flash: 0
    Connections {
        target: em
        function onOpenChanged() { if (em.open && em.on) flashRun.restart(); }
    }
    SequentialAnimation {
        id: flashRun
        PauseAnimation { duration: 180 }
        NumberAnimation { target: em; property: "flash"; from: 0; to: 1; duration: 220; easing.type: Easing.OutCubic }
        NumberAnimation { target: em; property: "flash"; to: 0; duration: 1100; easing.type: Easing.InOutSine }
    }

    Item {
        id: shine
        clip: true

        parent: em.parent
        z: 90
        enabled: false
        visible: em.on && em.card !== null && em.cardOpacity > 0.01
        opacity: em.cardOpacity
        x: em.card ? em.card.x + em.dx : 0
        y: em.card ? em.card.y + em.dy : 0
        width: em.fw
        height: em.fh

        RectangularShadow {
            x: shine.width * 0.15
            y: -80
            width: shine.width * 0.7
            height: 120
            radius: 55
            blur: 70
            color: Colors.alpha(Colors.accent, 0.16 + 0.42 * em.flash)
        }

        RectangularShadow {
            readonly property real w: Phase.slowWave(11, 0)
            x: shine.width * (0.05 + 0.35 * w) - 60
            y: shine.height * 0.55
            width: 220
            height: 160
            radius: 80
            blur: 90
            color: Colors.alpha(Colors.accentAlt, 0.11)
        }
        RectangularShadow {
            readonly property real w: Phase.slowWave(14, 0.5)
            x: shine.width * (0.55 + 0.25 * w)
            y: shine.height * (0.15 + 0.3 * w)
            width: 200
            height: 180
            radius: 90
            blur: 90
            color: Colors.alpha(Colors.accent, 0.09)
        }

        Rectangle {
            id: gloss
            width: Math.max(120, shine.width * 0.3)
            height: shine.height * 2.2
            anchors.verticalCenter: parent.verticalCenter
            rotation: 18
            opacity: 0
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.09) }
                GradientStop { position: 1.0; color: "transparent" }
            }
            SequentialAnimation {
                id: glossRun
                PauseAnimation { duration: 260 }
                ParallelAnimation {
                    NumberAnimation { target: gloss; property: "x"; from: -gloss.width * 1.2; to: shine.width + gloss.width * 0.2; duration: 900; easing.type: Easing.InOutCubic }
                    SequentialAnimation {
                        NumberAnimation { target: gloss; property: "opacity"; to: 1; duration: 200 }
                        PauseAnimation { duration: 450 }
                        NumberAnimation { target: gloss; property: "opacity"; to: 0; duration: 250 }
                    }
                }
            }
            Connections {
                target: em
                function onOpenChanged() { if (em.open && em.on) glossRun.restart(); }
            }
        }

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - em.cornerTo * 1.4
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.22 + 0.25 * em.flash) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }
}
