import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: card
    readonly property Item hero: mark
    readonly property real heroRadius: mark.face ? mark.width / 2 : 12
    property string notifApp: ""
    property string notifBody: ""
    property string notifSummary: ""
    property string notifImage: ""
    property string notifIcon: ""
    property color tint: Colors.accent
    property int count: 1
    property int page: 0
    property int total: 1

    property var live: null
    property bool tools: false
    property bool replying: false
    property bool near: true

    Timer {
        interval: 6000
        running: card.replying && !card.near && field.text === ""
        onTriggered: card.reply(false)
    }

    signal reply(bool on)
    signal done()

    readonly property var acts: {
        const a = card.live ? card.live.actions : null;
        const out = [];
        for (let i = 0; a && i < a.length; i++) {
            if (!a[i].text || a[i].text === "" || a[i].identifier === "default"
                || a[i].identifier === "inline-reply")
                continue;
            out.push(a[i]);
        }
        return out;
    }

    readonly property bool canReply: !!card.live && card.live.hasInlineReply
    readonly property bool hasTools: card.canReply || card.acts.length > 0

    readonly property real toolsH: 30
    property real toolsShow: card.tools && card.hasTools ? 1 : 0
    Behavior on toolsShow { NumberAnimation { duration: Motion.base; easing.type: Easing.OutCubic } }

    readonly property string iconSrc:
        card.notifIcon === "" ? ""
        : card.notifIcon.startsWith("/") || card.notifIcon.startsWith("file:")
          || card.notifIcon.startsWith("image:")
          ? card.notifIcon : Quickshell.iconPath(card.notifIcon, true)

    function openDefault() {
        const a = card.live ? card.live.actions : null;
        for (let i = 0; a && i < a.length; i++) {
            if (a[i].identifier === "default") {
                a[i].invoke();
                card.done();
                return;
            }
        }
    }

    function send() {
        const t = field.text.trim();
        if (t === "" || !card.live)
            return;
        card.live.sendInlineReply(t);
        field.text = "";
        card.reply(false);
        card.done();
    }

    property real t: 0
    NumberAnimation on t {
        running: card.visible
        loops: Animation.Infinite
        from: 0; to: Math.PI * 2
        duration: 11000
    }

    property real enter: 1
    NumberAnimation {
        id: enterRun
        target: card; property: "enter"
        from: 0; to: 1; duration: 900
        easing.type: Easing.OutCubic
    }
    onVisibleChanged: if (card.visible) enterRun.restart()
    Component.onCompleted: enterRun.restart()

    Item {
        id: ambient
        anchors.fill: parent
        anchors.margins: -12
        opacity: 0.55 * card.enter

        IconImage {
            readonly property real size: 320
            width: size
            height: size
            implicitSize: size
            x: 70 + Math.sin(card.t) * 26 - size / 2
            y: ambient.height / 2 + Math.cos(card.t * 2) * 12 - size / 2
            rotation: card.t * 180 / Math.PI
            scale: 0.9 + 0.1 * card.enter
            source: card.iconSrc !== "" ? card.iconSrc
                  : card.notifImage !== "" ? card.notifImage : ""
            asynchronous: true
            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                saturation: 0.3
            }
        }

        RectangularShadow {
            x: ambient.width * (0.12 + 0.08 * Math.sin(card.t * 2)) - 60
            y: ambient.height * (0.3 + 0.2 * Math.cos(card.t)) - 50
            width: 180
            height: 120
            radius: 60
            blur: 70
            color: Colors.alpha(card.tint, 0.35)
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.12) }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.55) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.82) }
            }
        }
    }

    Item {
        id: top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(mark.height, words.implicitHeight)
        y: Math.max(0, (card.height - (card.toolsH + 10) * card.toolsShow
                        - top.height) / 2)
        transform: [
            Translate { id: pageShift },
            Translate { y: 10 * (1 - card.enter) },
            Scale { id: pageScale; origin.x: top.width / 2; yScale: pageScale.xScale }
        ]
        opacity: Math.min(1, card.enter * 1.4)

        TapHandler {
            enabled: !!card.live && !card.replying
            onTapped: card.openDefault()
        }

        Item {
            id: mark
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: 42
            height: 42

            readonly property bool face: card.notifImage !== "" && avatar.status === Image.Ready
            readonly property bool logo: !mark.face && card.iconSrc !== ""
                                         && logoImg.status === Image.Ready

            scale: 0.5
            Component.onCompleted: mark.scale = 1
            Behavior on scale { Spring {} }

            Rectangle {
                anchors.fill: parent
                visible: !mark.face && !mark.logo
                radius: 12
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(card.tint, 1.15) }
                    GradientStop { position: 1.0; color: Qt.darker(card.tint, 1.45) }
                }

                Text {
                    anchors.centerIn: parent
                    text: NotifHistory.appLetter(card.notifApp)
                    color: "white"
                    font.family: Fonts.display
                    font.pixelSize: 19
                    font.weight: Font.Bold
                }
            }

            IconImage {
                id: logoImg
                anchors.fill: parent
                visible: mark.logo
                source: card.iconSrc
                asynchronous: true
            }

            ClippingRectangle {
                anchors.fill: parent
                visible: mark.face
                radius: width / 2
                color: "transparent"

                Image {
                    id: avatar
                    anchors.fill: parent
                    source: card.notifImage
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 84
                    sourceSize.height: 84
                    asynchronous: true
                    smooth: true
                }
            }

            Rectangle {
                visible: mark.face && card.iconSrc !== ""
                width: 20
                height: 20
                radius: 6
                x: parent.width - width + 4
                y: parent.height - height + 4
                color: "black"

                IconImage {
                    anchors.fill: parent
                    anchors.margins: 1.5
                    source: card.iconSrc
                    asynchronous: true
                }
            }

            Rectangle {
                id: badge
                visible: card.count > 1
                height: 18
                width: Math.max(height, countText.implicitWidth + 10)
                radius: height / 2
                x: parent.width - width + 6
                y: -6
                color: card.tint
                border.width: 2
                border.color: "black"

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: card.count > 99 ? "99+" : card.count
                    color: "white"
                    font.family: Fonts.display
                    font.pixelSize: 11
                    font.weight: Font.Bold
                    font.features: { "tnum": 1 }
                }

                Behavior on scale { Spring {} }
                Behavior on color { ColorAnimation { duration: Motion.slow } }
            }
        }

        Column {
            id: words
            anchors.left: mark.right
            anchors.leftMargin: 12
            anchors.right: parent.right
            anchors.rightMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Item {
                width: parent.width
                height: appName.implicitHeight

                Text {
                    id: appName
                    anchors.left: parent.left
                    anchors.right: nowText.left
                    anchors.rightMargin: 8
                    text: card.notifApp
                    color: Colors.alpha(Colors.fg, 0.45)
                    font.family: Fonts.display
                    font.pixelSize: 11
                    font.capitalization: Font.AllUppercase
                    font.letterSpacing: 0.4
                    elide: Text.ElideRight
                }

                Text {
                    id: nowText
                    anchors.right: parent.right
                    text: card.total > 1 ? (card.page + 1) + " / " + card.total
                                         : I18n.t("isle.now")
                    font.features: { "tnum": 1 }
                    color: Colors.alpha(Colors.fg, 0.4)
                    font.family: Fonts.display
                    font.pixelSize: 11
                }
            }

            Text {
                width: parent.width
                text: card.notifSummary
                color: Colors.fg
                font.family: Fonts.display
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                id: bodyText
                width: parent.width
                visible: bodyText.text !== ""
                text: card.notifBody
                color: Colors.alpha(Colors.fg, 0.68)
                font.family: Fonts.display
                font.pixelSize: 12
                lineHeight: 1.15
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: 2
                transform: Translate { id: bodyShift }
            }
        }
    }

    Item {
        id: tray
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: card.toolsH
        visible: card.toolsShow > 0.01
        opacity: card.toolsShow
        transform: Translate { y: 8 * (1 - card.toolsShow) }

        Row {
            anchors.fill: parent
            spacing: 6
            visible: !card.replying

            readonly property int n: (card.canReply ? 1 : 0) + card.acts.length
            readonly property real each: n > 0 ? (width - spacing * (n - 1)) / n : 0

            NotifKey {
                visible: card.canReply
                width: parent.each
                height: parent.height
                tint: card.tint
                lead: true
                label: I18n.t("isle.reply")
                onHit: card.reply(true)
            }

            Repeater {
                model: card.acts
                NotifKey {
                    required property var modelData
                    width: parent.each
                    height: parent.height
                    tint: card.tint
                    label: modelData.text
                    onHit: {
                        modelData.invoke();
                        card.done();
                    }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            visible: card.replying
            radius: height / 2
            color: Colors.alpha(Colors.fg, 0.10)
            border.width: 1
            border.color: Colors.alpha(card.tint, 0.55)

            TextInput {
                id: field
                anchors.left: parent.left
                anchors.right: sendKey.left
                anchors.leftMargin: 14
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                color: Colors.fg
                selectionColor: Colors.alpha(card.tint, 0.5)
                font.family: Fonts.display
                font.pixelSize: 13
                clip: true

                Keys.onReturnPressed: card.send()
                Keys.onEnterPressed: card.send()
                Keys.onEscapePressed: card.reply(false)

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: field.text === ""
                    text: card.live && card.live.inlineReplyPlaceholder
                          ? card.live.inlineReplyPlaceholder : I18n.t("isle.replyHint")
                    color: Colors.alpha(Colors.fg, 0.35)
                    font: field.font
                }
            }

            Rectangle {
                id: sendKey
                anchors.right: parent.right
                anchors.rightMargin: 3
                anchors.verticalCenter: parent.verticalCenter
                width: parent.height - 6
                height: width
                radius: width / 2
                color: field.text.trim() === "" ? Colors.alpha(Colors.fg, 0.15) : card.tint
                scale: sendTap.pressed ? 0.88 : 1
                Behavior on color { ColorAnimation { duration: Motion.fast } }
                Behavior on scale { Spring {} }

                Text {
                    anchors.centerIn: parent
                    text: "󰁝"
                    color: "white"
                    font.family: Fonts.glyph
                    font.pixelSize: 14
                }

                TapHandler { id: sendTap; onTapped: card.send() }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
            }
        }
    }

    property string pendingBody: ""

    onCountChanged: {
        if (card.count <= 1)
            return;
        badge.scale = 1.45;
        badge.scale = 1;
    }

    onNotifBodyChanged: {
        if (card.count <= 1) {
            bodyText.text = card.notifBody;
            return;
        }
        card.pendingBody = card.notifBody;
        swap.restart();
    }

    SequentialAnimation {
        id: swap
        ParallelAnimation {
            NumberAnimation { target: bodyText; property: "opacity"; to: 0; duration: 180; easing.type: Easing.InOutCubic }
            NumberAnimation { target: bodyShift; property: "y"; to: -5; duration: 180; easing.type: Easing.InOutCubic }
        }
        ScriptAction {
            script: {
                bodyText.text = card.pendingBody;
                card.pendingBody = "";
                bodyShift.y = 7;
            }
        }
        ParallelAnimation {
            NumberAnimation { target: bodyText; property: "opacity"; to: 1; duration: 420; easing.type: Easing.OutCubic }
            NumberAnimation { target: bodyShift; property: "y"; to: 0; duration: 520; easing.type: Easing.OutCubic }
        }
    }

    property int lastPage: 0
    onPageChanged: {
        const dir = card.page > card.lastPage ? 1 : -1;
        card.lastPage = card.page;
        pageIn.dir = dir;
        pageIn.restart();
    }

    ParallelAnimation {
        id: pageIn
        property int dir: 1
        NumberAnimation { target: pageShift; property: "y"; from: 12 * pageIn.dir; to: 0; duration: 520; easing.type: Easing.OutCubic }
        NumberAnimation { target: pageScale; property: "xScale"; from: 0.97; to: 1; duration: 520; easing.type: Easing.OutCubic }
    }

    onReplyingChanged: {
        if (card.replying)
            Qt.callLater(() => field.forceActiveFocus());
        else
            field.text = "";
    }
}
