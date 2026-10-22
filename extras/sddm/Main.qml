import QtQuick
import QtQuick.Effects

Rectangle {
    id: root

    width: 1920
    height: 1080
    color: pal.bg

    readonly property real u: Math.max(0.6, Math.min(height / 1080, width / 1600))
    readonly property string live: "file:///var/lib/f-sddm/"

    QtObject {
        id: fallback
        property color bg: "#17130e"
        property color bgAlt: "#504539"
        property color fg: "#ebe1d8"
        property color fgDim: "#d4c4b4"
        property color accent: "#f7bb75"
        property color accentText: "#472a00"
        property color bad: "#ffb4ab"
    }
    Loader { id: livePal; source: root.live + "Palette.qml" }
    readonly property var pal: livePal.status === Loader.Ready && livePal.item ? livePal.item : fallback

    readonly property string sans: "Adwaita Sans"
    readonly property string glyph: "JetBrainsMono Nerd Font"

    property int userIndex: (typeof userModel !== "undefined" && userModel.lastIndex >= 0) ? userModel.lastIndex : 0
    property int sessionIndex: (typeof sessionModel !== "undefined" && sessionModel.lastIndex >= 0) ? sessionModel.lastIndex : 0

    ListView {
        id: users
        model: typeof userModel !== "undefined" ? userModel : null
        currentIndex: root.userIndex
        width: 1; height: 1; opacity: 0; enabled: false
        delegate: Item {
            required property var model
            property string login: model.name || ""
            property string display: model.realName || model.name || ""
            property string icon: model.icon || ""
        }
    }
    ListView {
        id: sessions
        model: typeof sessionModel !== "undefined" ? sessionModel : null
        currentIndex: root.sessionIndex
        width: 1; height: 1; opacity: 0; enabled: false
        delegate: Item {
            required property var model
            property string label: model.name || ""
        }
    }

    readonly property string userLogin: users.currentItem ? users.currentItem.login
                                       : (typeof userModel !== "undefined" && userModel.lastUser ? userModel.lastUser : "")
    readonly property string userName: {
        const n = users.currentItem && users.currentItem.display !== "" ? users.currentItem.display : userLogin;
        return n.length > 0 ? n.charAt(0).toUpperCase() + n.slice(1) : "";
    }
    readonly property string sessionLabel: sessions.currentItem ? sessions.currentItem.label : ""
    readonly property string layoutLabel: {
        if (typeof keyboard === "undefined" || !keyboard || !keyboard.layouts || keyboard.layouts.length === 0)
            return "";
        const l = keyboard.layouts[keyboard.currentLayout];
        return l ? String(l.shortName).toUpperCase() : "";
    }

    readonly property var weekdays: ["воскресенье", "понедельник", "вторник", "среда", "четверг", "пятница", "суббота"]
    readonly property var months: ["января", "февраля", "марта", "апреля", "мая", "июня", "июля",
                                   "августа", "сентября", "октября", "ноября", "декабря"]
    property string timeText: ""
    property string dateText: ""

    function tick() {
        const d = new Date();
        timeText = String(d.getHours()).padStart(2, "0") + ":" + String(d.getMinutes()).padStart(2, "0");
        dateText = weekdays[d.getDay()] + ", " + d.getDate() + " " + months[d.getMonth()];
        clock.interval = 1000 - (d.getTime() % 1000) + 5;
        clock.restart();
    }
    Timer { id: clock; repeat: false; onTriggered: root.tick() }

    property bool busy: false
    property bool failed: false

    function login() {
        if (busy || pass.text.length === 0 || typeof sddm === "undefined")
            return;
        busy = true;
        failed = false;
        sddm.login(userLogin, pass.text, sessionIndex);
    }

    Connections {
        target: typeof sddm !== "undefined" ? sddm : null
        ignoreUnknownSignals: true
        function onLoginFailed() {
            root.busy = false;
            root.failed = true;
            pass.text = "";
            failTimer.restart();
            pass.forceActiveFocus();
        }
        function onLoginSucceeded() {
            leave.start();
        }
    }
    Timer { id: failTimer; interval: 2600; onTriggered: root.failed = false }

    property real wallIn: 0
    property real uiIn: 0
    property real blurP: 0.0
    property real dimP: 0.0

    Component.onCompleted: {
        tick();
        if (typeof keyboard !== "undefined" && keyboard)
            keyboard.numLock = true;
        intro.start();
        pass.forceActiveFocus();
    }

    ParallelAnimation {
        id: intro
        NumberAnimation { target: root; property: "wallIn"; to: 1; duration: 1100; easing.type: Easing.OutCubic }
        NumberAnimation { target: root; property: "blurP"; from: 0; to: 1; duration: 1600; easing.type: Easing.InOutCubic }
        NumberAnimation { target: root; property: "dimP"; from: 0; to: 1; duration: 1600; easing.type: Easing.InOutCubic }
        SequentialAnimation {
            PauseAnimation { duration: 300 }
            NumberAnimation { target: root; property: "uiIn"; to: 1; duration: 1100; easing.type: Easing.OutCubic }
        }
    }

    ParallelAnimation {
        id: leave
        NumberAnimation { target: root; property: "uiIn"; to: 0; duration: 380; easing.type: Easing.InCubic }
        NumberAnimation { target: root; property: "blurP"; to: 0; duration: 800; easing.type: Easing.InOutCubic }
        NumberAnimation { target: root; property: "dimP"; to: 0; duration: 800; easing.type: Easing.InOutCubic }
        NumberAnimation { target: wall; property: "zoom"; to: 1.0; duration: 800; easing.type: Easing.InOutCubic }
    }

    Image {
        id: wall
        anchors.fill: parent
        visible: false
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: false
        sourceSize: Qt.size(root.width, root.height)
        source: root.live + "wall.png"
        onStatusChanged: if (status === Image.Error && source != Qt.resolvedUrl("assets/wall.png"))
                             source = Qt.resolvedUrl("assets/wall.png")
        property real zoom: 1.0
    }

    MultiEffect {
        id: wallFx
        anchors.fill: parent
        source: wall
        opacity: root.wallIn
        autoPaddingEnabled: false
        blurEnabled: true
        blurMax: 48
        blur: 0.8 * root.blurP
        brightness: -0.18 * root.dimP
        saturation: 0.1 * root.dimP
        property real drift: 0
        scale: 1.06 - 0.04 * root.wallIn + 0.015 * drift
        SequentialAnimation on drift {
            loops: Animation.Infinite
            NumberAnimation { to: 1; duration: 20000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0; duration: 20000; easing.type: Easing.InOutSine }
        }
    }

    Canvas {
        id: light
        width: 1100 * root.u
        height: width
        opacity: 0.16 * root.dimP
        property color tone: root.pal.accent
        onToneChanged: requestPaint()
        onPaint: {
            const c = getContext("2d");
            c.reset();
            const g = c.createRadialGradient(width / 2, height / 2, 0, width / 2, height / 2, width / 2);
            g.addColorStop(0, Qt.rgba(tone.r, tone.g, tone.b, 1));
            g.addColorStop(0.5, Qt.rgba(tone.r, tone.g, tone.b, 0.35));
            g.addColorStop(1, Qt.rgba(tone.r, tone.g, tone.b, 0));
            c.fillStyle = g;
            c.fillRect(0, 0, width, height);
        }
        property real t: 0
        x: root.width * (0.15 + 0.5 * t) - width / 2
        y: root.height * (0.75 - 0.35 * Math.sin(t * Math.PI)) - height / 2
        SequentialAnimation on t {
            loops: Animation.Infinite
            NumberAnimation { to: 1; duration: 26000; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0; duration: 26000; easing.type: Easing.InOutSine }
        }
    }

    Rectangle {
        anchors.fill: parent
        opacity: root.dimP
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(root.pal.bg, 0.35) }
            GradientStop { position: 0.45; color: Qt.alpha(root.pal.bg, 0.05) }
            GradientStop { position: 1.0; color: Qt.alpha(root.pal.bg, 0.65) }
        }
    }

    MouseArea {
        anchors.fill: parent
        onClicked: pass.forceActiveFocus()
    }

    Item {
        id: ui
        anchors.fill: parent
        opacity: root.uiIn

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.17 + 24 * root.u * (1 - root.uiIn)
            spacing: 2 * root.u

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.timeText
                font.family: root.sans
                font.pixelSize: 132 * root.u
                font.weight: Font.Light
                font.features: { "tnum": 1 }
                font.letterSpacing: -2 * root.u
                color: root.pal.fg
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.dateText
                font.family: root.sans
                font.pixelSize: 19 * root.u
                color: root.pal.fgDim
                opacity: 0.85
            }
        }

        Column {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: root.height * 0.58 + 36 * root.u * (1 - root.uiIn)
            spacing: 16 * root.u

            Item {
                id: avatar
                anchors.horizontalCenter: parent.horizontalCenter
                width: 92 * root.u
                height: width

                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width + 6 * root.u
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 1.5 * root.u
                    border.color: Qt.alpha(root.pal.accent, 0.25 + 0.35 * v)
                    property real v: 0
                    SequentialAnimation on v {
                        loops: Animation.Infinite
                        NumberAnimation { to: 1; duration: 3500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0; duration: 3500; easing.type: Easing.InOutSine }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.alpha(root.pal.bgAlt, 0.8)
                    Text {
                        anchors.centerIn: parent
                        visible: face.status !== Image.Ready
                        text: root.userName.charAt(0)
                        font.family: root.sans
                        font.pixelSize: 38 * root.u
                        font.weight: Font.Medium
                        color: root.pal.fg
                    }
                }

                Image {
                    id: face
                    anchors.fill: parent
                    visible: false
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(width * 2, height * 2)
                    source: root.live + "face.png"
                    onStatusChanged: {
                        if (status !== Image.Error)
                            return;
                        if (source == root.live + "face.png")
                            source = Qt.resolvedUrl("assets/face.png");
                        else if (users.currentItem && users.currentItem.icon !== ""
                                 && source != "file://" + users.currentItem.icon)
                            source = "file://" + users.currentItem.icon;
                    }
                }
                Rectangle {
                    id: faceMask
                    anchors.fill: parent
                    radius: width / 2
                    visible: false
                    layer.enabled: true
                }
                MultiEffect {
                    anchors.fill: parent
                    source: face
                    visible: face.status === Image.Ready
                    maskEnabled: true
                    maskSource: faceMask
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: typeof userModel !== "undefined" && users.count > 1
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: root.userIndex = (root.userIndex + 1) % users.count
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.userName
                font.family: root.sans
                font.pixelSize: 21 * root.u
                font.weight: Font.Medium
                color: root.pal.fg
            }

            Item { width: 1; height: 2 * root.u }

            Rectangle {
                id: pill
                anchors.horizontalCenter: parent.horizontalCenter
                width: 330 * root.u
                height: 52 * root.u
                radius: height / 2
                color: Qt.alpha(root.pal.bg, pass.activeFocus ? 0.52 : 0.38)
                Behavior on color { ColorAnimation { duration: 300 } }
                border.width: 1
                border.color: root.failed ? Qt.alpha(root.pal.bad, 0.85)
                            : pass.activeFocus ? Qt.alpha(root.pal.accent, 0.45)
                            : Qt.alpha(root.pal.fg, 0.12)
                Behavior on border.color { ColorAnimation { duration: 360; easing.type: Easing.OutCubic } }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: root.failed ? root.pal.bad : root.pal.accent
                    opacity: root.failed ? 0.10 : (pass.text.length > 0 ? 0.06 : 0)
                    Behavior on opacity { NumberAnimation { duration: 400 } }
                    Behavior on color { ColorAnimation { duration: 360 } }
                }

                TextInput {
                    id: pass
                    anchors.fill: parent
                    opacity: 0
                    echoMode: TextInput.Password
                    passwordMaskDelay: 0
                    enabled: !root.busy
                    focus: true
                    onAccepted: root.login()
                    onTextChanged: if (text.length > 0) root.failed = false
                    Keys.onEscapePressed: text = ""
                }

                Text {
                    anchors.centerIn: parent
                    text: root.failed ? "неверный пароль" : "пароль"
                    font.family: root.sans
                    font.pixelSize: 15 * root.u
                    color: root.failed ? root.pal.bad : root.pal.fgDim
                    opacity: pass.text.length === 0 && !root.busy ? 0.7 : 0
                    Behavior on opacity { NumberAnimation { duration: 220 } }
                    Behavior on color { ColorAnimation { duration: 300 } }
                }

                Row {
                    id: dots
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: go.shown ? -14 * root.u : 0
                    Behavior on anchors.horizontalCenterOffset { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    spacing: 8 * root.u
                    property real breath: 1
                    opacity: root.busy ? 0.35 + 0.65 * breath : 1
                    SequentialAnimation on breath {
                        running: root.busy
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 600; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
                    }
                    Repeater {
                        model: Math.min(pass.text.length, 18)
                        Rectangle {
                            width: 9 * root.u
                            height: width
                            radius: width / 2
                            color: root.pal.fg
                            scale: 0
                            opacity: 0
                            Component.onCompleted: { scale = 1; opacity = 1; }
                            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            Behavior on opacity { NumberAnimation { duration: 180 } }
                        }
                    }
                }

                Rectangle {
                    id: go
                    readonly property bool shown: pass.text.length > 0 || root.busy
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    anchors.rightMargin: 6 * root.u
                    width: parent.height - 12 * root.u
                    height: width
                    radius: width / 2
                    color: root.pal.accent
                    opacity: shown ? 1 : 0
                    scale: shown ? 1 : 0.6
                    Behavior on opacity { NumberAnimation { duration: 240 } }
                    Behavior on scale { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                    Text {
                        anchors.centerIn: parent
                        text: root.busy ? "󰔟" : "󰁔"
                        font.family: root.glyph
                        font.pixelSize: 18 * root.u
                        color: root.pal.accentText
                        RotationAnimation on rotation {
                            running: root.busy
                            loops: Animation.Infinite
                            from: 0; to: 360; duration: 1400
                        }
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.login()
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Caps Lock включён"
                font.family: root.sans
                font.pixelSize: 13 * root.u
                color: root.pal.fgDim
                opacity: typeof keyboard !== "undefined" && keyboard && keyboard.capsLock ? 0.8 : 0
                Behavior on opacity { NumberAnimation { duration: 240 } }
            }
        }

        Row {
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.margins: 32 * root.u
            spacing: 10 * root.u

            Chip {
                text: root.sessionLabel
                icon: "󰍹"
                onClicked: if (sessions.count > 1) root.sessionIndex = (root.sessionIndex + 1) % sessions.count
            }
            Chip {
                text: root.layoutLabel
                icon: "󰌌"
                visible: root.layoutLabel !== ""
                onClicked: if (keyboard.layouts.length > 1)
                               keyboard.currentLayout = (keyboard.currentLayout + 1) % keyboard.layouts.length
            }
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: 32 * root.u
            spacing: 10 * root.u

            Chip {
                icon: "󰒲"
                visible: typeof sddm !== "undefined" && sddm.canSuspend
                onClicked: sddm.suspend()
            }
            Chip {
                icon: "󰜉"
                visible: typeof sddm !== "undefined" && sddm.canReboot
                onClicked: sddm.reboot()
            }
            Chip {
                icon: "󰐥"
                visible: typeof sddm !== "undefined" && sddm.canPowerOff
                onClicked: sddm.powerOff()
            }
        }
    }

    component Chip: Rectangle {
        id: chip
        property string text: ""
        property string icon: ""
        signal clicked()
        height: 38 * root.u
        width: text === "" ? height : label.implicitWidth + height + 4 * root.u
        radius: height / 2
        color: Qt.alpha(root.pal.bg, hover.containsMouse ? 0.55 : 0.32)
        border.width: 1
        border.color: Qt.alpha(root.pal.fg, hover.containsMouse ? 0.18 : 0.08)
        Behavior on color { ColorAnimation { duration: 220 } }
        Behavior on border.color { ColorAnimation { duration: 220 } }
        Row {
            anchors.centerIn: parent
            spacing: 8 * root.u
            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: chip.icon
                font.family: root.glyph
                font.pixelSize: 16 * root.u
                color: hover.containsMouse ? root.pal.accent : root.pal.fgDim
                Behavior on color { ColorAnimation { duration: 220 } }
            }
            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                visible: chip.text !== ""
                text: chip.text
                font.family: root.sans
                font.pixelSize: 13 * root.u
                color: root.pal.fgDim
            }
        }
        MouseArea {
            id: hover
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: chip.clicked()
        }
    }
}
