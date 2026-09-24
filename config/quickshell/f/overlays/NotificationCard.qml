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
    readonly property color edge: critical ? Colors.bad : card.appTint

    readonly property int entryTime: critical ? 300 : 560
    readonly property real entryPeak: critical ? 1.07 : 1.02

    readonly property int lifetime:
        modelData.expireTimeout > 0 ? modelData.expireTimeout : 5000

    readonly property string kind: NotifKind.of(modelData)

    WeatherHold { active: card.kind === "weather" && card.visible }
    readonly property string shot: NotifKind.shotPath(modelData)

    readonly property color appTint: NotifHistory.appColor(modelData.appName)

    readonly property var acts: {
        const a = card.modelData.actions;
        const out = [];
        for (let i = 0; a && i < a.length; i++) {
            if (a[i].text && a[i].text !== "")
                out.push(a[i]);
        }
        return out;
    }

    property real remaining: 1
    property bool leaving: false
    property bool hovering: false

    width: 360
    height: head.height + extra.height + acts2.height

    radius: Shape.card

    Behavior on height {
        NumberAnimation {
            duration: Motion.base
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.decel
        }
    }

    color: card.critical
        ? Qt.rgba(Colors.bad.r * 0.28 + Colors.bg.r * 0.72,
                  Colors.bad.g * 0.28 + Colors.bg.g * 0.72,
                  Colors.bad.b * 0.28 + Colors.bg.b * 0.72, 0.96)
        : Colors.alpha(Colors.bg, 0.95)

    border.width: 1
    border.color: card.critical
        ? Colors.alpha(Colors.bad, 0.55)
        : Qt.rgba(card.appTint.r, card.appTint.g, card.appTint.b,
                  card.hovering ? 0.42 : 0.26)

    Behavior on border.color { ColorAnimation { duration: Motion.base } }

    Sheen {
        anchors.fill: parent
        radius: card.radius
        border: false
        grainOpacity: 0.025
    }

    ClippingRectangle {
        anchors.fill: parent
        radius: card.radius
        color: "transparent"

        Rectangle {
            width: parent.width * 0.55
            height: parent.height
            opacity: card.critical ? 0.20 : 0.16
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: card.edge }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }
    }

    opacity: 0
    transform: Translate { id: slide; x: 380 }

    Component.onCompleted: {
        enter.start();
        if (!card.critical)
            countdown.start();
    }

    ParallelAnimation {
        id: enter

        NumberAnimation {
            target: slide; property: "x"; from: 380; to: 0
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
            target: slide; property: "x"; to: 380
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
        anchors.leftMargin: card.radius * 0.6
        anchors.rightMargin: card.radius * 0.6
        anchors.bottomMargin: 5
        height: 2
        radius: 1
        visible: !card.critical
        color: Colors.alpha(Colors.fgDim, 0.10)

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, card.remaining))
            height: parent.height
            radius: parent.radius
            color: card.edge
            opacity: card.hovering ? 0.45 : 1
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }
    }

    Rectangle {
        id: alarm
        visible: card.critical
        anchors.fill: parent
        radius: card.radius
        color: "transparent"
        border.width: 2
        border.color: Colors.bad

        SequentialAnimation on opacity {
            running: card.critical
            loops: Animation.Infinite
            NumberAnimation { to: 0.45; duration: 1100; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1.0;  duration: 1100; easing.type: Easing.InOutSine }
        }
    }

    Item {
        id: head

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: Math.max(58, headCol.implicitHeight + 24)

        Item {
            id: badge

            width: 36
            height: 36
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 11

            readonly property string icon: {
                if (card.modelData.image !== "")
                    return card.modelData.image;
                if (!card.modelData.appIcon || card.modelData.appIcon === "")
                    return "";
                return Quickshell.iconPath(card.modelData.appIcon, "");
            }

            readonly property bool portrait: card.modelData.image !== ""

            Rectangle {
                anchors.fill: parent
                radius: badge.portrait ? width / 2 : Shape.chip
                antialiasing: true
                color: Qt.rgba(card.appTint.r, card.appTint.g,
                               card.appTint.b, 0.18)
                border.width: badge.portrait ? 1 : 0
                border.color: Colors.alpha(card.appTint, 0.45)
            }

            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 1
                visible: badge.portrait
                radius: width / 2
                color: "transparent"

                Image {
                    anchors.fill: parent
                    source: badge.portrait ? badge.icon : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 72
                }
            }

            Loader {
                anchors.centerIn: parent
                active: !badge.portrait && badge.icon !== ""
                sourceComponent: IconImage {
                    source: badge.icon
                    implicitSize: 21
                }
            }

            Text {
                anchors.centerIn: parent
                visible: !badge.portrait && badge.icon === ""
                text: NotifHistory.appLetter(card.modelData.appName)
                color: card.appTint
                font.family: Fonts.mono
                font.pixelSize: 15
                font.weight: Font.Bold
            }
        }

        Column {
            id: headCol
            anchors.left: badge.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 14
            anchors.top: parent.top
            anchors.topMargin: 12
            spacing: 3

            Row {
                width: parent.width
                spacing: 8

                Text {
                    width: parent.width - appName.width - parent.spacing
                    text: card.modelData.summary
                    color: Colors.fg
                    font.family: Fonts.display
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                Text {
                    id: appName
                    text: card.modelData.appName
                    color: Colors.alpha(Colors.fgDim, 0.45)
                    font.family: Fonts.mono
                    font.pixelSize: 9
                    y: 3
                }
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: card.modelData.body.replace(/<[^>]*>/g, "").trim()
                color: Colors.alpha(Colors.fgDim, 0.72)
                font.family: Fonts.mono
                font.pixelSize: 10
                lineHeight: 1.25
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
            }
        }
    }

    Rectangle {
        id: dismiss
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 7
        width: 20
        height: 20
        radius: 10
        antialiasing: true
        opacity: card.hovering ? 1 : 0
        visible: opacity > 0.01
        color: closeHover.hovered ? Colors.alpha(Colors.bad, 0.85)
                                  : Colors.alpha(Colors.fgDim, 0.16)

        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: closeHover.hovered ? Colors.bg : Colors.fgDim
            font.family: Fonts.glyph
            font.pixelSize: 10
        }

        HoverHandler { id: closeHover }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: card.close()
        }
    }

    MouseArea {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: head.height
        cursorShape: Qt.PointingHandCursor
        hoverEnabled: true

        onEntered: {
            card.hovering = true;
            if (!card.leaving && countdown.running)
                countdown.pause();
        }
        onExited: {
            card.hovering = false;
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
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            sourceComponent: card.kind === "screenshot" ? shotBody
                           : card.kind === "update" ? updateBody
                           : card.kind === "weather" ? weatherBody
                           : null
        }
    }

    Item {
        id: acts2
        anchors.top: extra.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        height: card.acts.length > 0 ? 42 : 12

        Row {
            anchors.left: parent.left
            anchors.leftMargin: 14
            anchors.top: parent.top
            spacing: 6

            Repeater {
                model: card.acts

                Rectangle {
                    required property var modelData

                    height: 26
                    width: Math.min(150, actText.implicitWidth + 22)
                    radius: Shape.chip
                    antialiasing: true
                    color: actHover.hovered
                        ? Colors.alpha(card.edge, 0.28)
                        : Colors.alpha(Colors.fgDim, 0.09)
                    border.width: 1
                    border.color: actHover.hovered
                        ? Colors.alpha(card.edge, 0.55)
                        : Colors.alpha(Colors.outline, 0.18)

                    Behavior on color { ColorAnimation { duration: Motion.fast } }
                    Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                    Text {
                        id: actText
                        anchors.centerIn: parent
                        width: Math.min(implicitWidth, 128)
                        text: parent.modelData.text
                        color: actHover.hovered ? Colors.fg : Colors.fgDim
                        elide: Text.ElideRight
                        font.family: Fonts.display
                        font.pixelSize: 11
                    }

                    HoverHandler { id: actHover }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            parent.modelData.invoke();
                            card.close();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: shotBody

        Item {
            height: 142

            ClippingRectangle {
                anchors.fill: parent
                radius: Shape.field
                color: Colors.alpha(Colors.bgAlt, 0.6)

                Image {
                    anchors.fill: parent
                    source: "file://" + card.shot
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 560
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
                radius: Shape.chip
                antialiasing: true
                color: Colors.alpha(Colors.accent, 0.18)

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: Updates.count > 0 ? Updates.count + I18n.t("notif.packages")
                                            : I18n.t("state.checking")
                    color: Colors.accent
                    font.family: Fonts.mono
                    font.pixelSize: 10
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                width: 150
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
