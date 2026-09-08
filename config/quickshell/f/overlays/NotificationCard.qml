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

    WeatherHold { active: card.kind === "weather" && card.visible }
    readonly property string shot: NotifKind.shotPath(modelData)
    readonly property int headHeight: 54

    readonly property color appTint: NotifHistory.appColor(modelData.appName)

    property real remaining: 1
    property bool leaving: false

    width: 330
    height: card.headHeight + extra.height
    radius: Shape.field + 4

    Behavior on height {
        NumberAnimation {
            duration: Motion.base
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.decel
        }
    }

    color: card.critical
        ? Qt.rgba(Colors.bad.r * 0.35 + Colors.bg.r * 0.65,
                  Colors.bad.g * 0.35 + Colors.bg.g * 0.65,
                  Colors.bad.b * 0.35 + Colors.bg.b * 0.65, 0.95)
        : Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.94)
    border.width: 1
    border.color: card.critical
        ? Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.55)
        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.14)

    Sheen {
        anchors.fill: parent
        radius: card.radius
        border: false
        grainOpacity: 0.025
    }

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
            easing.type: Easing.Bezier
            easing.bezierCurve: card.critical ? Motion.elastic : Motion.expo
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

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 1
        anchors.rightMargin: 1
        anchors.bottomMargin: 1
        height: 3
        radius: 1.5
        visible: !card.critical
        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.10)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, card.remaining))
            height: parent.height
            radius: parent.radius
            color: card.edge
        }
    }

    Rectangle {
        visible: card.critical
        anchors.fill: parent
        radius: card.radius
        color: "transparent"
        border.width: 2
        border.color: card.edge
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 9
        anchors.topMargin: 13
        width: 3
        height: card.headHeight - 26
        radius: 1.5
        antialiasing: true
        color: card.critical ? Colors.bad : card.appTint
    }

    Row {
        id: head

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: 20
        anchors.rightMargin: 14
        height: card.headHeight
        spacing: 11

        Rectangle {
            id: badge

            width: 32
            height: 32
            radius: Shape.chip
            antialiasing: true
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(card.appTint.r, card.appTint.g, card.appTint.b, 0.18)

            readonly property string icon: {
                if (card.modelData.image !== "")
                    return card.modelData.image;
                if (!card.modelData.appIcon || card.modelData.appIcon === "")
                    return "";
                return Quickshell.iconPath(card.modelData.appIcon, "");
            }

            Loader {
                anchors.centerIn: parent
                active: badge.icon !== ""
                sourceComponent: IconImage {
                    source: badge.icon
                    implicitSize: 20
                }
            }

            Text {
                anchors.centerIn: parent
                visible: badge.icon === ""
                text: NotifHistory.appLetter(card.modelData.appName)
                color: card.appTint
                font.family: Fonts.mono
                font.pixelSize: 14
                font.weight: Font.Bold
            }
        }

        Column {
            width: parent.width - badge.width - parent.spacing
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            Text {
                width: parent.width
                text: card.modelData.summary
                color: Colors.fg
                font.family: Fonts.display
                font.pixelSize: 13
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
                               Colors.fgDim.b, 0.68)
                font.family: Fonts.mono
                font.pixelSize: 10
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
            height: 132

            ClippingRectangle {
                anchors.fill: parent
                radius: Shape.field
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
                    font.family: Fonts.mono
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
                font.family: Fonts.mono
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
                font.family: Fonts.mono
                font.pixelSize: 26
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Weather.temp) + "°  " + Weather.text.toLowerCase()
                color: Colors.fgDim
                font.family: Fonts.mono
                font.pixelSize: 11
            }
        }
    }
}
