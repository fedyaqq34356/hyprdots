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
    property var msgs: []
    property bool critical: false

    readonly property bool expanded: card.near && !card.replying

    readonly property bool picture: avatar.status === Image.Ready && avatar.implicitHeight > 0
        && Math.abs(avatar.implicitWidth / avatar.implicitHeight - 1) > 0.22
    readonly property real picH: card.picture ? 128 : 0

    readonly property real wantH: Math.max(mark.height, words.implicitHeight)
        + (card.picture ? card.picH + 12 : 0)
        + (card.toolsH + 10) * card.toolsShow + 4
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

    readonly property real t: card.visible ? (Phase.ts % 11) / 11 * Math.PI * 2 : 0
    PhaseHold { active: card.visible; slow: true }

    property real enter: 1
    NumberAnimation {
        id: enterRun
        target: card; property: "enter"
        from: 0; to: 1; duration: 900
        easing.type: Easing.OutCubic
    }
    onVisibleChanged: if (card.visible) enterRun.restart()
    Component.onCompleted: {
        enterRun.restart();
        card.syncChat();
    }

    Item {
        id: ambient
        anchors.fill: parent
        anchors.margins: -12
        opacity: card.enter

        RectangularShadow {
            x: ambient.width * (0.08 + 0.10 * Math.sin(card.t)) - 30
            y: ambient.height * (0.30 + 0.16 * Math.cos(card.t * 2)) - 55
            width: 190
            height: 130
            radius: 65
            blur: 80
            color: Colors.alpha(card.tint, 0.40)
        }
        RectangularShadow {
            x: ambient.width * (0.58 + 0.14 * Math.cos(card.t)) - 40
            y: ambient.height * (0.55 + 0.18 * Math.sin(card.t * 2 + 1)) - 60
            width: 220
            height: 140
            radius: 70
            blur: 90
            color: Colors.alpha(Qt.lighter(card.tint, 1.3), 0.17)
        }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: -11
        radius: Math.max(0, IslandConfig.s("radius") - 1)
        color: "transparent"
        antialiasing: true
        border.width: 1.6
        border.color: Colors.bad
        visible: card.critical
        property real p: 0.3
        opacity: p
        SequentialAnimation on p {
            running: card.critical && card.visible
            loops: Animation.Infinite
            NumberAnimation { to: 0.85; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.25; duration: 1100; easing.type: Easing.InOutSine }
        }
    }

    Item {
        id: top
        anchors.left: parent.left
        anchors.right: parent.right
        height: Math.max(mark.height, words.implicitHeight)
        y: Math.max(0, (card.height - (card.toolsH + 10) * card.toolsShow
                        - card.picH - (card.picture ? 12 : 0) - top.height) / 2)
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
            anchors.top: parent.top
            width: 42
            height: 42

            readonly property bool face: card.notifImage !== "" && avatar.status === Image.Ready && !card.picture
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
                    font.features: { "tnum": 1 }
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
                    sourceSize.width: 360
                    sourceSize.height: 360
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
            anchors.top: parent.top
            anchors.topMargin: words.implicitHeight < mark.height ? (mark.height - words.implicitHeight) / 2 : 0
            spacing: 2

            Text {
                id: appName
                width: parent.width
                text: card.notifApp + "  ·  " + I18n.t("isle.now")
                color: Colors.alpha(Colors.fg, 0.45)
                font.family: Fonts.display
                font.features: { "tnum": 1 }
                font.pixelSize: 11
                font.letterSpacing: 0.2
                elide: Text.ElideRight
            }

            Text {
                width: parent.width
                text: card.notifSummary
                color: Colors.fg
                font.family: Fonts.display
                font.features: { "tnum": 1 }
                font.pixelSize: 14
                font.weight: Font.DemiBold
                elide: Text.ElideRight
            }

            Text {
                id: bodyText
                width: parent.width
                visible: bodyText.text !== "" && chatModel.count <= 1
                text: card.notifBody
                color: Colors.alpha(Colors.fg, 0.68)
                font.family: Fonts.display
                font.features: { "tnum": 1 }
                font.pixelSize: 12
                lineHeight: 1.15
                wrapMode: Text.WordWrap
                elide: Text.ElideRight
                maximumLineCount: card.expanded ? 6 : 2
                transform: Translate { id: bodyShift }
            }

            ListView {
                id: chat
                width: parent.width
                height: chat.contentHeight
                visible: chatModel.count > 1
                interactive: false
                spacing: 4
                topMargin: 3
                model: chatModel

                add: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic }
                        NumberAnimation { property: "scale"; from: 0.92; to: 1; duration: 480; easing.type: Easing.OutCubic }
                    }
                }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation { property: "opacity"; to: 0; duration: 260; easing.type: Easing.InCubic }
                        NumberAnimation { property: "scale"; to: 0.94; duration: 260 }
                    }
                }
                displaced: Transition {
                    NumberAnimation { properties: "x,y"; duration: 460; easing.type: Easing.OutCubic }
                }

                delegate: Item {
                    id: bubble
                    required property string t
                    required property int index
                    readonly property bool last: bubble.index === chatModel.count - 1
                    width: chat.width
                    height: bubbleText.height + 10
                    transformOrigin: Item.BottomLeft
                    opacity: bubble.last ? 1 : 0.55 + 0.2 * bubble.index

                    Rectangle {
                        width: Math.min(chat.width, bubbleText.implicitWidth + 22)
                        height: parent.height
                        radius: Math.min(13, height / 2)
                        color: bubble.last ? Colors.alpha(card.tint, 0.20) : Qt.rgba(1, 1, 1, 0.06)
                        border.width: bubble.last ? 1 : 0
                        border.color: Colors.alpha(card.tint, 0.32)
                    }
                    Text {
                        id: bubbleText
                        x: 11
                        y: 5
                        width: chat.width - 22
                        text: bubble.t
                        color: Colors.alpha(Colors.fg, bubble.last ? 0.92 : 0.7)
                        font.family: Fonts.display
                        font.features: { "tnum": 1 }
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        elide: Text.ElideRight
                        maximumLineCount: bubble.last ? (card.expanded ? 5 : 2) : 1
                    }
                }
            }
        }
    }

    ListModel { id: chatModel }

    onMsgsChanged: card.syncChat()

    function syncChat() {
        const m = card.msgs && card.msgs.length > 0 ? card.msgs : [card.notifBody];
        const n = chatModel.count;
        if (n > 0 && m.length >= 2 && chatModel.get(n - 1).t === m[m.length - 2]) {
            chatModel.append({ t: m[m.length - 1] });
            while (chatModel.count > 3)
                chatModel.remove(0);
            return;
        }
        chatModel.clear();
        for (const x of m.slice(-3))
            chatModel.append({ t: x });
    }

    ClippingRectangle {
        id: pic
        visible: card.picture
        anchors.left: parent.left
        anchors.right: parent.right
        y: top.y + top.height + 12
        height: card.picH
        radius: 16
        color: Qt.rgba(1, 1, 1, 0.05)
        opacity: card.enter

        Image {
            anchors.fill: parent
            source: card.picture ? card.notifImage : ""
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 720
            smooth: true
        }
    }

    Item {
        id: tray
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: card.toolsH
        visible: card.toolsShow > 0.01
        opacity: Math.min(1, card.toolsShow * 1.4)
        transform: [
            Translate { y: 10 * (1 - card.toolsShow) },
            Scale {
                origin.x: tray.width / 2
                origin.y: tray.height
                xScale: 0.82 + 0.18 * card.toolsShow
                yScale: 0.25 + 0.75 * card.toolsShow
            }
        ]

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
                font.features: { "tnum": 1 }
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
