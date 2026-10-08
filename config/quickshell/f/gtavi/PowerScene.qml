import Quickshell
import QtQuick

FocusScope {
    id: sc

    property var ctl
    anchors.fill: parent
    focus: true

    readonly property real u: Math.max(0.5, Math.min(height / 1080, width / 1500))
    readonly property color cream: "#fff9cb"
    readonly property color lilac: "#e5ddff"
    readonly property color blush: "#ffb2c6"
    readonly property color pink: "#f976b0"
    readonly property color navyDeep: "#0b0a15"
    readonly property var easeOut: [0.32, 0.72, 0, 1, 1, 1]
    readonly property var easeInOut: [0.645, 0.045, 0.355, 1, 1, 1]
    readonly property var easeIn: [0.55, 0.085, 0.68, 0.53, 1, 1]

    readonly property string home: Quickshell.env("HOME")
    readonly property var actions: [
        { key: "L", label: "LOCK", sub: "SCREEN OFF · SESSION STAYS",
          run: ["/bin/sh", "-c", home + "/.config/hypr/scripts/lock.sh"], farewell: false },
        { key: "S", label: "SLEEP", sub: "TO RAM · WAKES INSTANTLY",
          run: ["loginctl", "suspend"], farewell: false },
        { key: "E", label: "LOG OUT", sub: "END THE HYPRLAND SESSION",
          run: ["hyprctl", "dispatch", "exit"], farewell: true },
        { key: "R", label: "RESTART", sub: "EVERY PROGRAM WILL CLOSE",
          run: ["loginctl", "reboot"], farewell: true },
        { key: "P", label: "SHUT DOWN", sub: "EVERY PROGRAM WILL CLOSE",
          run: ["loginctl", "poweroff"], farewell: true }
    ]
    property int selected: 0

    property real curtainP: 0
    property real bgIn: 0
    property real eyebrowP: 0
    property real titleP: 0
    property real hintP: 0
    property real chromeP: 0
    property real outP: 0
    property real px: 0
    property real py: 0
    Behavior on px { NumberAnimation { duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut } }
    Behavior on py { NumberAnimation { duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut } }

    property real c0: 0; property real c1: 0; property real c2: 0; property real c3: 0; property real c4: 0
    function cardRise(i) { return [c0, c1, c2, c3, c4][i]; }

    Component.onCompleted: {
        slides.start(Math.floor(Math.random() * slides.sources.length), true);
        intro.start();
    }

    Keys.onEscapePressed: ctl.close()
    Keys.onLeftPressed: selected = (selected + actions.length - 1) % actions.length
    Keys.onRightPressed: selected = (selected + 1) % actions.length
    Keys.onTabPressed: selected = (selected + 1) % actions.length
    Keys.onReturnPressed: activate(selected)
    Keys.onEnterPressed: activate(selected)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_H) { selected = (selected + actions.length - 1) % actions.length; event.accepted = true; return; }
        const t = event.text.toUpperCase();
        for (let i = 0; i < actions.length; i++) {
            if (actions[i].key === t) {
                activate(i);
                event.accepted = true;
                return;
            }
        }
    }

    property bool leaving: false
    property var pending: null

    function activate(i) {
        if (leaving || !actions[i])
            return;
        selected = i;
        leave(actions[i]);
    }

    function leave(action) {
        if (leaving)
            return;
        leaving = true;
        pending = action;
        intro.stop();
        exit.duration = action ? 520 : 340;
        exit.start();
    }

    NumberAnimation {
        id: exit
        target: sc; property: "outP"; to: 1
        easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeIn
        onFinished: {
            if (sc.pending)
                sc.ctl.run(sc.pending);
            else
                sc.ctl.finished();
        }
    }

    ParallelAnimation {
        id: intro
        NumberAnimation { target: sc; property: "bgIn"; to: 1; duration: 380 }
        NumberAnimation { target: sc; property: "curtainP"; to: 1; duration: 1150
                          easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeInOut }
        SequentialAnimation {
            PauseAnimation { duration: 260 }
            NumberAnimation { target: sc; property: "eyebrowP"; to: 1; duration: 1000
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 340 }
            NumberAnimation { target: sc; property: "titleP"; to: 1; duration: 1000
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation { PauseAnimation { duration: 480 }
            NumberAnimation { target: sc; property: "c0"; to: 1; duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut } }
        SequentialAnimation { PauseAnimation { duration: 550 }
            NumberAnimation { target: sc; property: "c1"; to: 1; duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut } }
        SequentialAnimation { PauseAnimation { duration: 620 }
            NumberAnimation { target: sc; property: "c2"; to: 1; duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut } }
        SequentialAnimation { PauseAnimation { duration: 690 }
            NumberAnimation { target: sc; property: "c3"; to: 1; duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut } }
        SequentialAnimation { PauseAnimation { duration: 760 }
            NumberAnimation { target: sc; property: "c4"; to: 1; duration: 900; easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut } }
        SequentialAnimation {
            PauseAnimation { duration: 900 }
            NumberAnimation { target: sc; property: "hintP"; to: 1; duration: 800
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 700 }
            NumberAnimation { target: sc; property: "chromeP"; to: 1; duration: 800
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onPositionChanged: mouse => {
            sc.px = (mouse.x / width) * 2 - 1;
            sc.py = (mouse.y / height) * 2 - 1;
        }
        onClicked: sc.ctl.close()
    }

    Rectangle {
        anchors.fill: parent
        color: sc.navyDeep
        opacity: sc.bgIn * (1 - sc.outP)
    }

    Slides {
        id: slides
        anchors.fill: parent
        u: sc.u
        running: !sc.leaving
        opacity: sc.bgIn * (1 - sc.outP)
        scale: 1 + 0.08 * sc.outP
        transform: Translate { x: -16 * sc.u * sc.px; y: -10 * sc.u * sc.py }
    }

    Rectangle {
        anchors.fill: parent
        opacity: 1 - sc.outP
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(0.043, 0.039, 0.082, 0.86) }
            GradientStop { position: 0.45; color: Qt.rgba(0.043, 0.039, 0.082, 0.45) }
            GradientStop { position: 0.85; color: Qt.rgba(0.043, 0.039, 0.082, 0.05) }
        }
    }
    Rectangle {
        anchors.fill: parent
        opacity: 1 - sc.outP
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.043, 0.039, 0.082, 0.45) }
            GradientStop { position: 0.25; color: Qt.rgba(0.043, 0.039, 0.082, 0.0) }
            GradientStop { position: 0.5; color: Qt.rgba(0.043, 0.039, 0.082, 0.10) }
            GradientStop { position: 1.0; color: Qt.rgba(0.043, 0.039, 0.082, 0.95) }
        }
    }

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/grain.png")
        fillMode: Image.Tile
        opacity: 0.05 * (1 - sc.outP)
        smooth: false
    }

    Item {
        width: parent.width * 1.4
        height: parent.height
        x: -parent.width * 0.4 + sc.curtainP * parent.width * 1.45
        visible: sc.curtainP < 1
        Rectangle {
            width: parent.width * 0.3
            height: parent.height
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: sc.navyDeep }
            }
        }
        Rectangle {
            x: parent.width * 0.3
            width: parent.width * 0.7
            height: parent.height
            color: sc.navyDeep
        }
    }

    Image {
        x: 56 * sc.u
        y: 36 * sc.u
        height: 64 * sc.u
        width: height * sourceSize.width / Math.max(1, sourceSize.height)
        source: Qt.resolvedUrl("assets/vi-mark.png")
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        opacity: sc.chromeP * (1 - sc.outP)
    }

    Column {
        id: hero
        x: 120 * sc.u
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 96 * sc.u
        opacity: 1 - sc.outP
        transform: Translate { x: 5 * sc.u * sc.px; y: 4 * sc.u * sc.py - 30 * sc.u * sc.outP }

        Text {
            readonly property real track: (0.40 + 0.8 * (1 - sc.eyebrowP)) * 18 * sc.u
            text: (Quickshell.env("USER") || "").toUpperCase()
                  + (sc.ctl.uptimeText !== "" ? "  ·  UP " + sc.ctl.uptimeText.toUpperCase() : "")
            color: "#ffffff"
            opacity: sc.eyebrowP
            font.family: "Lexend"
            font.weight: Font.DemiBold
            font.pixelSize: 18 * sc.u
            font.letterSpacing: track
        }

        Item { width: 1; height: 6 * sc.u }

        Item {
            width: title.implicitWidth
            height: 0.80 * title.font.pixelSize
            clip: true
            Text {
                id: title
                y: -(fm.ascent - 0.75 * font.pixelSize) + (1 - sc.titleP) * parent.height * 1.1
                opacity: Math.min(1, sc.titleP * 1.6)
                text: "LEAVING VICE CITY?"
                color: sc.cream
                font.family: "Barlow Condensed"
                font.weight: Font.ExtraBold
                font.pixelSize: 150 * sc.u
                font.letterSpacing: -0.01 * 150 * sc.u
                FontMetrics { id: fm; font: title.font }
            }
        }

        Item { width: 1; height: 34 * sc.u }

        Row {
            spacing: 14 * sc.u
            Repeater {
                model: sc.actions
                Card {
                    required property var modelData
                    required property int index
                    action: modelData
                    idx: index
                }
            }
        }

        Item { width: 1; height: 22 * sc.u }

        Text {
            opacity: 0.6 * sc.hintP
            text: "←  →  CHOOSE    ·    ENTER  CONFIRM    ·    L  S  E  R  P  DIRECT    ·    ESC  CLOSE"
            color: sc.lilac
            font.family: "Lexend"
            font.weight: Font.DemiBold
            font.pixelSize: 11 * sc.u
            font.letterSpacing: 0.3 * 11 * sc.u
        }
    }

    component Card: Item {
        id: card
        property var action
        property int idx: 0
        readonly property bool current: sc.selected === idx
        readonly property real rise: sc.cardRise(idx)
        readonly property bool danger: action.key === "R" || action.key === "P"

        width: 262 * sc.u
        height: 168 * sc.u

        Accessible.role: Accessible.Button
        Accessible.name: action.label

        Item {
            anchors.fill: parent
            clip: true

            Item {
                id: face
                width: parent.width
                height: parent.height
                y: (1 - card.rise) * parent.height * 1.05 + (card.current ? -2 * sc.u : 0)
                opacity: Math.min(1, card.rise * 1.5)
                Behavior on y { enabled: card.rise >= 1; NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut } }

                Rectangle {
                    anchors.fill: parent
                    radius: 22 * sc.u
                    color: card.current ? Qt.rgba(1, 1, 1, 0.13) : Qt.rgba(0.043, 0.039, 0.082, 0.5)
                    border.width: Math.max(1, (card.current ? 2 : 1) * sc.u)
                    border.color: card.current ? (card.danger ? sc.pink : sc.blush) : Qt.rgba(1, 1, 1, 0.14)
                    Behavior on color { ColorAnimation { duration: 220 } }
                    Behavior on border.color { ColorAnimation { duration: 220 } }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 16 * sc.u
                    width: 30 * sc.u
                    height: 30 * sc.u
                    radius: width / 2
                    color: card.current ? sc.blush : Qt.rgba(1, 1, 1, 0.12)
                    Behavior on color { ColorAnimation { duration: 220 } }
                    Text {
                        anchors.centerIn: parent
                        text: card.action.key
                        color: card.current ? "#1b1526" : "#ffffff"
                        font.family: "Lexend"
                        font.weight: Font.Bold
                        font.pixelSize: 13 * sc.u
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.bottom: parent.bottom
                    anchors.margins: 20 * sc.u
                    spacing: 2 * sc.u

                    Item {
                        width: label.implicitWidth
                        height: label.implicitHeight
                        Text {
                            id: label
                            text: card.action.label
                            color: sc.cream
                            visible: !card.current
                            font.family: "Barlow Condensed"
                            font.weight: Font.ExtraBold
                            font.pixelSize: 50 * sc.u
                            font.letterSpacing: -0.005 * 50 * sc.u
                        }
                        Item {
                            anchors.fill: parent
                            visible: card.current
                            layer.enabled: card.current
                            layer.effect: SunsetFx {
                                c0: "#ffd687"; c1: "#fc5243"; c2: "#e963c7"
                            }
                            Text {
                                text: card.action.label
                                color: "#ffffff"
                                font: label.font
                            }
                        }
                    }

                    Text {
                        text: card.action.sub
                        color: sc.lilac
                        opacity: card.current ? 0.85 : 0.5
                        font.family: "Lexend"
                        font.weight: Font.DemiBold
                        font.pixelSize: 10 * sc.u
                        font.letterSpacing: 0.22 * 10 * sc.u
                        Behavior on opacity { NumberAnimation { duration: 220 } }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: sc.selected = card.idx
            onClicked: sc.activate(card.idx)
        }
    }
}
