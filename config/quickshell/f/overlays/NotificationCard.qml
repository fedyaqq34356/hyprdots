import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Rectangle {
    id: card

    required property var modelData

    signal closed()

    readonly property bool critical:
        modelData.urgency === NotificationUrgency.Critical
    readonly property color edge: critical ? Colors.bad : Colors.accent

    readonly property int entryTime: critical ? 300 : 560
    readonly property real entryOvershoot: critical ? 1.7 : 0.45
    readonly property real entryPeak: critical ? 1.07 : 1.02

    readonly property int lifetime:
        modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000

    readonly property string kind: NotifKind.of(modelData)
    readonly property string shot: NotifKind.shotPath(modelData)
    readonly property int headHeight: 46

    property real remaining: 1
    property bool leaving: false

    width: 236
    height: card.headHeight + extra.height
    radius: Shape.chip

    Behavior on height {
        NumberAnimation {
            duration: Motion.base
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.decel
        }
    }

    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.94)
    border.width: 1
    border.color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.14)

    opacity: 0
    transform: Translate { id: slide; x: 340 }

    Component.onCompleted: {
        enter.start();
        if (!card.critical)
            countdown.start();
    }

    ParallelAnimation {
        id: enter

        NumberAnimation {
            target: slide; property: "x"; from: 340; to: 0
            duration: card.entryTime
            easing.type: Easing.OutBack
            easing.overshoot: card.entryOvershoot
        }
        NumberAnimation {
            target: card; property: "opacity"; to: 1
            duration: card.critical ? 150 : 280
            easing.type: Easing.OutCubic
        }
        SequentialAnimation {
            NumberAnimation {
                target: card; property: "scale"
                from: card.critical ? 0.88 : 0.94; to: card.entryPeak
                duration: card.entryTime * 0.7
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: card; property: "scale"; to: 1
                duration: card.entryTime * 0.35
                easing.type: Easing.OutCubic
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

    NumberAnimation {
        id: countdown
        target: card
        property: "remaining"
        from: 1
        to: 0
        duration: card.lifetime
        onFinished: card.close()
    }

    Canvas {
        id: ring
        anchors.fill: parent
        anchors.margins: 1
        renderStrategy: Canvas.Cooperative
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

            const straightH = w - 2 * r;
            const straightV = h - 2 * r;
            const arc = (Math.PI / 2) * r;
            const total = 2 * straightH + 2 * straightV + 4 * arc;
            let budget = total * frac;

            ctx.beginPath();
            ctx.moveTo(w / 2, 0);

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

    Rectangle {
        visible: card.critical
        anchors.fill: parent
        radius: card.radius
        color: "transparent"
        border.width: 2
        border.color: card.edge
    }

    Row {
        id: head

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        height: card.headHeight
        spacing: 9

        Rectangle {
            width: 26
            height: 26
            radius: 8
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(card.edge.r, card.edge.g, card.edge.b, 0.16)

            IconImage {
                anchors.centerIn: parent
                source: card.modelData.image !== ""
                        ? card.modelData.image
                        : Quickshell.iconPath(card.modelData.appIcon,
                                              "dialog-information")
                implicitSize: 17
            }
        }

        Column {
            width: parent.width - 35
            spacing: 1
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: card.modelData.summary
                color: Colors.fg
                font.family: Fonts.display
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
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: card.headHeight
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

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

    Item {
        id: extra

        anchors.top: head.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: bodyLoader.item ? bodyLoader.item.height + 12 : 0
        clip: true

        Loader {
            id: bodyLoader
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            sourceComponent: card.kind === "screenshot" ? shotBody
                           : card.kind === "update" ? updateBody
                           : card.kind === "weather" ? weatherBody
                           : null
        }
    }

    Component {
        id: shotBody

        Item {
            height: 112

            ClippingRectangle {
                anchors.fill: parent
                radius: Shape.chip
                color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.6)

                Image {
                    anchors.fill: parent
                    source: "file://" + card.shot
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 540
                    cache: false
                }
            }

            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 6
                spacing: 6

                IconButton {
                    glyph: "󰆏"
                    tip: I18n.t("act.copy")
                    tint: Colors.accent
                    width: 28
                    height: 28
                    onActivated: Quickshell.execDetached(["sh", "-c",
                        "wl-copy --type image/png < '" + card.shot + "'"])
                }

                IconButton {
                    glyph: "󰈈"
                    tip: I18n.t("act.open")
                    tint: Colors.accentAlt
                    width: 28
                    height: 28
                    onActivated: Quickshell.execDetached(["xdg-open", card.shot])
                }
            }
        }
    }

    Component {
        id: updateBody

        Row {
            height: 34
            spacing: 10

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: countText.implicitWidth + 18
                height: 24
                radius: 8
                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: Updates.count > 0 ? Updates.count + I18n.t("notif.packages") : I18n.t("state.checking")
                    color: Colors.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 130
                text: Updates.all.slice(0, 3).map(u => u.name).join(", ")
                color: Colors.fgDim
                opacity: 0.6
                elide: Text.ElideRight
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 9
            }
        }
    }

    Component {
        id: weatherBody

        Row {
            height: 40
            spacing: 12

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Weather.glyph
                color: Weather.tint
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 26
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Weather.temp) + "°  " + Weather.text.toLowerCase()
                color: Colors.fgDim
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 11
            }
        }
    }
}
