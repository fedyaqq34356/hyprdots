import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick

// One notification popup.
//
// Enters by sliding in from off the right edge, leaves the same way. The
// remaining lifetime is drawn as a stroke that retreats around the card's own
// rounded border, so the countdown is part of the shape instead of a separate
// progress bar.
Rectangle {
    id: card

    required property var modelData

    // Emitted once the leave animation has played; the parent does the dismiss.
    signal closed()

    readonly property bool critical:
        modelData.urgency === NotificationUrgency.Critical
    readonly property color edge: critical ? Colors.bad : Colors.accent

    readonly property int lifetime:
        modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000

    // 1 at spawn, 0 when the card is due to go away.
    property real remaining: 1
    property bool leaving: false

    width: 270
    height: 54
    radius: 14

    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.94)
    border.width: 1
    border.color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.14)

    opacity: 0
    transform: Translate { id: slide; x: 340 }

    // --- lifecycle -------------------------------------------------------

    Component.onCompleted: {
        enter.start();
        if (!card.critical)
            countdown.start();
    }

    ParallelAnimation {
        id: enter

        NumberAnimation {
            target: slide; property: "x"; from: 340; to: 0
            duration: 520; easing.type: Easing.OutExpo
        }
        NumberAnimation {
            target: card; property: "opacity"; to: 1
            duration: 260; easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            // Lands with a small settle rather than a bounce.
            NumberAnimation {
                target: card; property: "scale"; from: 0.92; to: 1.03
                duration: 380; easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: card; property: "scale"; to: 1
                duration: 180; easing.type: Easing.OutCubic
            }
        }
    }

    ParallelAnimation {
        id: leave
        onFinished: card.closed()

        NumberAnimation {
            target: slide; property: "x"; to: 340
            duration: 340; easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: card; property: "opacity"; to: 0
            duration: 300; easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: card; property: "scale"; to: 0.94
            duration: 340; easing.type: Easing.InCubic
        }
    }

    function close() {
        if (card.leaving)
            return;
        card.leaving = true;
        countdown.stop();
        leave.start();
    }

    // Drives both the border countdown and the dismissal.
    NumberAnimation {
        id: countdown
        target: card
        property: "remaining"
        from: 1
        to: 0
        duration: card.lifetime
        onFinished: card.close()
    }

    // --- countdown border ------------------------------------------------

    Canvas {
        id: ring
        anchors.fill: parent
        anchors.margins: 1
        renderStrategy: Canvas.Cooperative
        // Critical notifications stay until clicked, so no countdown is drawn.
        visible: !card.critical

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const w = width;
            const h = height;
            const r = card.radius - 1;
            const frac = Math.max(0, Math.min(1, card.remaining));
            if (frac <= 0)
                return;

            // Perimeter of the rounded rect, walked clockwise from top-centre.
            const straightH = w - 2 * r;
            const straightV = h - 2 * r;
            const arc = (Math.PI / 2) * r;
            const total = 2 * straightH + 2 * straightV + 4 * arc;
            let budget = total * frac;

            ctx.beginPath();
            ctx.moveTo(w / 2, 0);

            // Each leg consumes from the budget and stops mid-way when it runs
            // out, which is what makes the stroke retreat smoothly.
            function line(x1, y1, x2, y2, len) {
                if (budget <= 0) return false;
                const t = Math.min(1, budget / len);
                ctx.lineTo(x1 + (x2 - x1) * t, y1 + (y2 - y1) * t);
                budget -= len;
                return budget > 0;
            }

            function corner(cx, cy, from, to) {
                if (budget <= 0) return false;
                const t = Math.min(1, budget / arc);
                ctx.arc(cx, cy, r, from, from + (to - from) * t);
                budget -= arc;
                return budget > 0;
            }

            line(w / 2, 0, w - r, 0, straightH / 2)
                && corner(w - r, r, -Math.PI / 2, 0)
                && line(w, r, w, h - r, straightV)
                && corner(w - r, h - r, 0, Math.PI / 2)
                && line(w - r, h, r, h, straightH)
                && corner(r, h - r, Math.PI / 2, Math.PI)
                && line(0, h - r, 0, r, straightV)
                && corner(r, r, Math.PI, Math.PI * 1.5)
                && line(r, 0, w / 2, 0, straightH / 2);

            ctx.strokeStyle = card.edge;
            ctx.lineWidth = 2;
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }

    onRemainingChanged: ring.requestPaint()
    onEdgeChanged: ring.requestPaint()

    // Critical notifications get a static border instead of a countdown.
    Rectangle {
        visible: card.critical
        anchors.fill: parent
        radius: card.radius
        color: "transparent"
        border.width: 2
        border.color: card.edge
    }

    // --- content ---------------------------------------------------------

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.leftMargin: 14
        anchors.rightMargin: 14
        spacing: 10

        Rectangle {
            width: 30
            height: 30
            radius: 9
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(card.edge.r, card.edge.g, card.edge.b, 0.16)

            IconImage {
                anchors.centerIn: parent
                source: card.modelData.image !== ""
                        ? card.modelData.image
                        : Quickshell.iconPath(card.modelData.appIcon,
                                              "dialog-information")
                implicitSize: 20
            }
        }

        Column {
            width: parent.width - 54
            spacing: 1
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: card.modelData.summary
                color: Colors.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: card.modelData.body !== ""
                      ? card.modelData.body.replace(/<[^>]*>/g, "")
                      : card.modelData.appName
                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                               Colors.fgDim.b, 0.62)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        // Hovering pauses the countdown so a notification can be read.
        onEntered: {
            if (!card.leaving && countdown.running)
                countdown.pause();
        }
        onExited: {
            if (countdown.paused)
                countdown.resume();
        }
        onClicked: card.close()
    }
}
