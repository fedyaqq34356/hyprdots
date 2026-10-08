import Quickshell.Widgets
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
    property string taskGlyph: "󰣪"
    property string result: ""
    property string icon: ""

    readonly property var timer: Timers.soonest
    readonly property bool busy:
        slot.kind === "print"
        || ((slot.kind === "task" || slot.kind === "launch" || slot.kind === "download")
            && slot.result === "")
    readonly property bool finished:
        (slot.kind === "task" || slot.kind === "launch" || slot.kind === "download")
        && slot.result !== ""

    readonly property real value: {
        if (slot.finished)
            return 1;
        if (slot.kind !== "timer" || !slot.timer)
            return 0;
        return Math.max(0, Math.min(1, Timers.progress(slot.timer)));
    }

    readonly property int secs:
        slot.kind === "timer" && slot.timer
            ? Math.max(0, Timers.left(slot.timer))
            : 0
    readonly property bool counting: slot.kind === "timer" && slot.secs <= 60

    readonly property string glyph: {
        switch (slot.kind) {
        case "print": return "󰐪";
        case "timer": return "󰔛";
        case "task":
            return slot.result === "ok" ? "󰄬"
                 : slot.result === "bad" ? "󰅖" : slot.taskGlyph;
        case "launch":
            return slot.result === "ok" ? "󰄬"
                 : slot.result === "bad" ? "󰅖" : "";
        case "download":
            return slot.result === "ok" ? "󰄬" : "󰇚";
        }
        return "";
    }

    width: slot.size
    height: slot.size

    onResultChanged: {
        if (slot.result === "ok")
            okPop.restart();
        else if (slot.result === "bad")
            badShake.restart();
    }

    SequentialAnimation {
        id: okPop
        NumberAnimation { target: slot; property: "scale"; to: 1.28; duration: 130; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
        NumberAnimation { target: slot; property: "scale"; to: 1.0;  duration: 300; easing.type: Easing.OutCubic }
    }

    property real jolt: 0
    transform: Translate { x: slot.jolt }

    SequentialAnimation {
        id: badShake
        NumberAnimation { target: slot; property: "jolt"; to: -3;  duration: 50 }
        NumberAnimation { target: slot; property: "jolt"; to: 3;   duration: 70 }
        NumberAnimation { target: slot; property: "jolt"; to: -2;  duration: 60 }
        NumberAnimation { target: slot; property: "jolt"; to: 1;   duration: 60 }
        NumberAnimation { target: slot; property: "jolt"; to: 0;   duration: 60 }
    }

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
        id: mark
        anchors.centerIn: parent
        visible: !slot.counting && slot.glyph !== ""
        text: slot.glyph
        color: slot.tint
        font.family: Fonts.glyph
        font.pixelSize: Math.max(9, Math.round(slot.size * 0.42))

        SequentialAnimation on opacity {
            running: slot.busy && slot.live
            loops: Animation.Infinite
            onStopped: mark.opacity = 1
            NumberAnimation { to: 0.45; duration: 750; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 750; easing.type: Easing.InOutSine }
        }
    }

    Item {
        id: pulse
        anchors.centerIn: parent
        width: appIcon.implicitSize
        height: appIcon.implicitSize
        visible: slot.kind === "launch" && slot.icon !== "" && appIcon.opacity > 0.01

        SequentialAnimation on scale {
            running: slot.kind === "launch" && slot.result === "" && slot.live
            loops: Animation.Infinite
            onStopped: pulse.scale = 1
            NumberAnimation { to: 0.86; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
        }

        IconImage {
            id: appIcon
            anchors.centerIn: parent
            implicitSize: Math.round(slot.size * 0.56)
            source: slot.icon
            asynchronous: true
            opacity: slot.result === "" ? 1 : 0
            scale: slot.result === "" ? 1 : 0.4
            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.InBack } }
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
        visible: slot.kind === "print" && slot.live
        width: Math.round(slot.size * 0.26)
        height: 2
        radius: 1
        color: Colors.alpha(slot.tint, 0.85)
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(slot.size * 0.62)

        SequentialAnimation on opacity {
            running: slot.kind === "print" && slot.live
            loops: Animation.Infinite
            NumberAnimation { to: 1;   duration: 220 }
            PauseAnimation  { duration: 320 }
            NumberAnimation { to: 0;   duration: 260 }
            PauseAnimation  { duration: 300 }
        }
    }
}
