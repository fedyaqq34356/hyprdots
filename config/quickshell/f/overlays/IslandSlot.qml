import QtQuick
import QtQuick.Shapes as Vec
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: slot

    property string kind: ""
    property color tint: Colors.accent
    property real size: 28
    property bool live: true

    readonly property var timer: Timers.soonest
    readonly property bool busy: slot.kind === "print"

    readonly property real value: {
        if (slot.kind !== "timer" || !slot.timer)
            return 0;
        return Math.max(0, Math.min(1, Timers.progress(slot.timer)));
    }

    readonly property int secs:
        slot.kind === "timer" && slot.timer
            ? Math.max(0, Math.round(Timers.left(slot.timer) / 1000))
            : 0
    readonly property bool counting: slot.kind === "timer" && slot.secs <= 60

    readonly property string glyph: {
        switch (slot.kind) {
        case "print": return "󰐪";
        case "timer": return "󰔛";
        }
        return "";
    }

    width: slot.size
    height: slot.size

    property real shown: 0
    onValueChanged: slot.shown = slot.value

    Behavior on shown {
        NumberAnimation {
            duration: Motion.isleContentMs
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.isleContent
        }
    }

    Vec.Shape {
        id: ring

        anchors.fill: parent
        asynchronous: false
        preferredRendererType: Vec.Shape.CurveRenderer
        visible: slot.live

        readonly property real thick: Math.max(1.6, slot.size * 0.085)
        readonly property real rad: slot.size / 2 - ring.thick / 2 - 1.5

        property real spin: 0
        NumberAnimation on spin {
            running: slot.busy && slot.live
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: 1500
        }

        Vec.ShapePath {
            strokeColor: Colors.alpha(slot.tint, 0.16)
            strokeWidth: ring.thick
            fillColor: "transparent"

            PathAngleArc {
                centerX: slot.size / 2
                centerY: slot.size / 2
                radiusX: ring.rad
                radiusY: ring.rad
                startAngle: 0
                sweepAngle: 360
            }
        }

        Vec.ShapePath {
            strokeColor: slot.tint
            strokeWidth: ring.thick
            fillColor: "transparent"
            capStyle: Vec.ShapePath.RoundCap

            PathAngleArc {
                centerX: slot.size / 2
                centerY: slot.size / 2
                radiusX: ring.rad
                radiusY: ring.rad
                startAngle: -90 + ring.spin
                sweepAngle: slot.busy ? 96 : Math.max(0.5, slot.shown * 360)
            }
        }
    }

    Text {
        anchors.centerIn: parent
        visible: !slot.counting && slot.glyph !== ""
        text: slot.glyph
        color: slot.tint
        font.family: Fonts.glyph
        font.pixelSize: Math.max(9, Math.round(slot.size * 0.42))

        SequentialAnimation on opacity {
            running: slot.busy && slot.live
            loops: Animation.Infinite
            NumberAnimation { to: 0.45; duration: 750; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 750; easing.type: Easing.InOutSine }
        }
    }

    RollText {
        anchors.centerIn: parent
        visible: slot.counting
        text: slot.counting ? String(slot.secs) : ""
        color: Colors.fg
        family: Fonts.mono
        pixelSize: Math.max(9, Math.round(slot.size * 0.40))
        weight: Font.DemiBold
        rollDuration: 240
    }

    Rectangle {
        visible: slot.busy && slot.live
        width: Math.round(slot.size * 0.26)
        height: 2
        radius: 1
        color: Colors.alpha(slot.tint, 0.85)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(slot.size * 0.62)

        SequentialAnimation on opacity {
            running: slot.busy && slot.live
            loops: Animation.Infinite
            NumberAnimation { to: 1;   duration: 220 }
            PauseAnimation  { duration: 320 }
            NumberAnimation { to: 0;   duration: 260 }
            PauseAnimation  { duration: 300 }
        }
    }
}
