import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes as Vec
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: card
    property string glyph: ""
    property color tint: Colors.accent

    Item {
        id: water
        anchors.fill: parent
        anchors.margins: -12
        visible: Feedback.showBar

        readonly property real v: Math.max(0, Math.min(1, Feedback.value))
        readonly property bool mic: Feedback.channel === "source" && !Feedback.flat

        readonly property bool listen: water.mic && card.visible
        onListenChanged: water.listen ? MicLevel.hold() : MicLevel.release()
        Component.onCompleted: if (water.listen) MicLevel.hold()
        Component.onDestruction: if (water.listen) MicLevel.release()

        MorphSpring {
            id: front
            springBack: true
            response: 0.72
            damping: 0.9
            epsilon: 0.2
            target: water.v * water.width
            Component.onCompleted: front.land()
        }

        property real slosh: 0
        property real voice: 0
        FrameAnimation {
            running: water.visible
            onTriggered: {
                const want = Math.min(6, Math.abs(front.velocity) / 100);
                const k = want > water.slosh ? Math.min(1, frameTime * 5) : Math.min(1, frameTime * 1.6);
                water.slosh += (want - water.slosh) * k;
                const heard = water.mic ? Math.min(1, MicLevel.level * 1.6) : 0;
                water.voice += (heard - water.voice) * Math.min(1, frameTime * (heard > water.voice ? 9 : 3));
            }
        }

        property real phase: 0
        NumberAnimation on phase {
            running: water.visible
            loops: Animation.Infinite
            from: 0; to: Math.PI * 2
            duration: 3000
        }

        readonly property real amp: 1.2 + water.slosh + 5 * water.voice

        readonly property var crest: {
            const pts = [];
            const n = 24;
            const h = water.height;
            for (let i = 0; i <= n; i++) {
                const y = h * i / n;
                const k = i / n;
                pts.push(Qt.point(Math.max(0, front.value
                    + water.amp * Math.sin(water.phase + k * Math.PI * 2.2)
                    + water.voice * 2 * Math.sin(water.phase * 2 + k * Math.PI * 4)), y));
            }
            return pts;
        }
        readonly property var body: [Qt.point(0, 0)].concat(water.crest).concat([Qt.point(0, water.height)])

        Vec.Shape {
            anchors.fill: parent
            preferredRendererType: Vec.Shape.CurveRenderer

            Vec.ShapePath {
                strokeColor: "transparent"
                strokeWidth: 0
                fillGradient: Vec.LinearGradient {
                    x1: 0; y1: 0
                    x2: Math.max(1, front.value); y2: 0
                    GradientStop { position: 0; color: Colors.alpha(card.tint, 0.14) }
                    GradientStop { position: 1; color: Colors.alpha(card.tint, 0.40) }
                }
                PathPolyline { path: water.body }
            }

            Vec.ShapePath {
                strokeColor: Colors.alpha(Qt.lighter(card.tint, 1.35), 0.9)
                strokeWidth: 2
                fillColor: "transparent"
                PathPolyline { path: water.crest }
            }
        }

        RectangularShadow {
            x: front.value - 30
            y: 0
            width: 60
            height: water.height
            radius: 30
            blur: 30
            color: Colors.alpha(card.tint, 0.28 + 0.3 * water.voice)
        }
    }

    IslandTile {
        id: osdTile
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        size: 46
        glyph: card.glyph
        tint: card.tint
    }

    Column {
        anchors.left: osdTile.right
        anchors.leftMargin: 16
        anchors.right: osdValue.left
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 10

        Text {
            text: Feedback.label !== ""
                  && Feedback.label !== Feedback.percent(Feedback.value)
                  ? Feedback.label
                  : Feedback.channel === "source" ? I18n.t("isle.osd.mic")
                  : Feedback.channel === "light" ? I18n.t("isle.osd.light")
                  : I18n.t("audio.volume2")
            color: Colors.alpha(Colors.fg, 0.6)
            font.family: Fonts.display
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }

    }

    Item {
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        width: osdEm.width + 2
        height: osdValue.height

        RollText {
            id: osdValue
            anchors.right: parent.right
            text: Feedback.showBar ? Feedback.percent(Feedback.value) : ""
            color: Colors.fg
            family: Fonts.display
            pixelSize: 26
            weight: Font.DemiBold
            rollDuration: 240
        }

        TextMetrics {
            id: osdEm
            font.family: Fonts.display
            font.pixelSize: 26
            font.weight: Font.DemiBold
            text: "100%"
        }
    }
}
