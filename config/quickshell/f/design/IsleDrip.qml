import QtQuick
import QtQuick.Effects
import Quickshell.Widgets
import "root:/design"
import "root:/services"

Item {
    id: drip

    property bool open: false
    property real cardW: 520
    property real cardH: 300
    property color glow: Colors.accent
    Behavior on glow { ColorAnimation { duration: 1100; easing.type: Easing.InOutCubic } }
    property real radius: 28
    property real gap: 12

    default property alias content: face.data
    readonly property Item card: card
    readonly property Item face: face
    readonly property real g: Math.max(0, life.value)
    readonly property bool living: life.value > 0.005 || drip.open
    readonly property real shown: card.opacity

    readonly property bool known: IslandBus.isleW > 0
    readonly property real cx: drip.known ? IslandBus.isleX + IslandBus.isleW / 2 : drip.width / 2
    readonly property real base: drip.known ? IslandBus.isleY + IslandBus.isleH : 47
    readonly property real isleW: drip.known ? IslandBus.isleW : 110

    readonly property bool watching: drip.living
    onWatchingChanged: IslandBus.watch += drip.watching ? 1 : -1
    Component.onDestruction: if (drip.watching) IslandBus.watch -= 1

    MorphSpring {
        id: leanSpring
        springBack: true
        response: 0.42
        damping: 0.9
        epsilon: 0.002
        target: 0
    }
    Timer { id: leanBack; interval: 110; onTriggered: leanSpring.target = 0 }

    function lean(dir) {
        leanSpring.target = dir;
        leanBack.restart();
    }

    MorphSpring {
        id: life
        response: 0.72
        damping: 0.96
        closeMs: 420
        softClose: true
        target: drip.open ? 1 : 0
    }

    property real shownH: drip.cardH
    Behavior on shownH { NumberAnimation { duration: 520; easing.type: Easing.InOutCubic } }

    readonly property real stretch: leanSpring.value
    readonly property real bw: Motion.mix(drip.isleW * 0.42, drip.cardW, drip.g)
                               * (1 + 0.04 * Math.abs(drip.stretch))
    readonly property real bh: Motion.mix(18, drip.shownH, drip.g)
                               * (1 - 0.025 * Math.abs(drip.stretch))
    readonly property real by: Motion.mix(drip.base - 16, drip.base + drip.gap, drip.g)
    readonly property real bx: drip.cx - drip.bw / 2 + 22 * drip.stretch

    RectangularShadow {
        x: drip.bx
        y: drip.by + 12
        width: drip.bw
        height: drip.bh
        radius: drip.radius + 6
        blur: 80
        spread: -6
        color: Colors.alpha(drip.glow, 0.30)
        opacity: drip.g
        visible: opacity > 0.01
    }

    Item {
        id: host
        x: drip.cx - drip.cardW / 2 - 80
        y: drip.base - 24
        width: drip.cardW + 160
        height: drip.cardH + 120

        Item {
            id: twin
            property bool isBlob: true
            width: Math.max(24, Math.min(drip.isleW - 44, 260))
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
        corner: drip.radius
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
        radius: Math.min(drip.radius, height / 2)
        color: "transparent"

        opacity: Math.max(0, Math.min(1, (drip.g - 0.55) / 0.45))
        visible: opacity > 0.01

        readonly property real t: card.visible ? (Phase.ts % 12) / 12 * Math.PI * 2 : 0
        PhaseHold { active: card.visible; slow: true }

        RectangularShadow {
            x: card.width * (0.10 + 0.10 * Math.sin(card.t)) - 40
            y: card.height * (0.22 + 0.14 * Math.cos(card.t * 2)) - 60
            width: 240
            height: 180
            radius: 90
            blur: 100
            color: Colors.alpha(drip.glow, 0.30)
        }
        RectangularShadow {
            x: card.width * (0.60 + 0.16 * Math.cos(card.t)) - 40
            y: card.height * (0.58 + 0.16 * Math.sin(card.t * 2 + 1)) - 60
            width: 260
            height: 190
            radius: 95
            blur: 110
            color: Colors.alpha(Qt.lighter(drip.glow, 1.3), 0.14)
        }

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: 1
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 90
            height: 1
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.16) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

        Item {
            id: face
            anchors.centerIn: parent
            width: drip.cardW
            height: drip.shownH
        }
    }
}
