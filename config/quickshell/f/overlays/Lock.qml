import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool locked: false

    signal unlocked()

    readonly property string shot:
        "file://" + Quickshell.env("XDG_RUNTIME_DIR") + "/lock-bg.png"

    function lock() {
        if (root.locked) return;
        root.locked = true;
    }

    IpcHandler {
        target: "lock"

        function lock(): string {
            root.lock();
            return "locked";
        }

        function state(): string {
            return root.locked ? "locked" : "unlocked";
        }
    }

    WlSessionLock {
        id: session
        locked: root.locked

        surface: WlSessionLockSurface {
            id: surface
            color: "transparent"

            property string entry: ""
            property string notice: ""
            property bool failed: false
            property int attempts: 0
            property int missed: 0

            function missedWord(n) {
                return I18n.plural("plural.notification", n);
            }

            PamContext {
                id: pam
                config: "hyprlock"

                onPamMessage: {
                    if (pam.responseRequired)
                        pam.respond(surface.entry);
                }

                onCompleted: function (result) {
                    if (result === PamResult.Success) {
                        root.unlocked();
                        root.locked = false;
                        return;
                    }

                    surface.attempts++;
                    surface.failed = true;
                    surface.notice = result === PamResult.MaxTries
                        ? I18n.t("lock.tooMany")
                        : I18n.t("lock.wrong");
                    surface.entry = "";
                    intruder.running = true;
                    dissolve.restart();
                }

                onError: function (err) {
                    surface.failed = true;
                    surface.notice = I18n.t("lock.pamError") + err;
                    surface.entry = "";
                }
            }

            function submit() {
                if (surface.entry === "" || pam.active)
                    return;
                surface.notice = I18n.t("state.checking");
                surface.failed = false;
                pam.start();
            }

            Process {
                id: missedProbe
                command: ["sh", "-c",
                          "cat \"${XDG_RUNTIME_DIR:-/tmp}/missed-notifications\" 2>/dev/null || echo 0"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const n = parseInt(this.text.trim(), 10);
                        surface.missed = isNaN(n) ? 0 : n;
                    }
                }
            }

            Timer {
                interval: 2000
                running: true
                repeat: true
                triggeredOnStart: true
                onTriggered: missedProbe.running = true
            }

            Process {
                id: intruder
                command: [Quickshell.env("HOME")
                          + "/.config/hypr/scripts/lock-intruder.sh"]
            }

            Image {
                anchors.fill: parent
                source: root.shot
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
            }

            SystemClock {
                id: lockClock
                precision: SystemClock.Minutes
            }

            Column {
                anchors.centerIn: parent
                spacing: 34

                Item {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 108
                    height: 108

                    Rectangle {
                        anchors.centerIn: parent
                        width: 108
                        height: 108
                        radius: 54
                        color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                       Colors.accent.b, 0.14)
                    }

                    ClippingRectangle {
                        anchors.centerIn: parent
                        width: 92
                        height: 92
                        radius: 46
                        color: "transparent"
                        border.width: 2
                        border.color: Colors.accent

                        Image {
                            anchors.fill: parent
                            anchors.margins: 2
                            source: "file://" + Quickshell.env("HOME")
                                    + "/.local/share/avatar/avatar.png"
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }
                }

                HandClock {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(lockClock.date, "HH:mm")
                    color: Colors.fg
                    thickness: 4
                    glyphWidth: 76
                    glyphHeight: 124
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(lockClock.date, "dddd, d MMMM")
                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                   Colors.fgDim.b, 0.7)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 14
                }

                Item {
                    id: field
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 360
                    height: 96

                    SequentialAnimation {
                        id: dissolve
                        NumberAnimation {
                            target: field; property: "opacity"
                            to: 0.0; duration: 260; easing.type: Easing.InCubic
                        }
                        PauseAnimation { duration: 90 }
                        NumberAnimation {
                            target: field; property: "opacity"
                            to: 1.0; duration: 320; easing.type: Easing.OutCubic
                        }
                    }

                    Rectangle {
                        id: box

                        anchors.top: parent.top
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width
                        height: 52
                        radius: 26

                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b,
                                       0.55)
                        border.width: 1.5
                        border.color: surface.failed
                            ? Colors.bad
                            : (pam.active
                               ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                         Colors.accent.b, 0.9)
                               : Qt.rgba(Colors.accent.r, Colors.accent.g,
                                         Colors.accent.b,
                                         0.30 + typedGlow * 0.55))

                        property real typedGlow: 0
                        Behavior on typedGlow {
                            NumberAnimation { duration: 480; easing.type: Easing.OutCubic }
                        }
                        Behavior on border.color { ColorAnimation { duration: 180 } }

                        Text {
                            id: keyhole
                            anchors.left: parent.left
                            anchors.leftMargin: 20
                            anchors.verticalCenter: parent.verticalCenter
                            text: surface.failed ? "󰍁" : (pam.active ? "󰦝" : "󰌾")
                            color: surface.failed ? Colors.bad : Colors.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                            opacity: 0.9
                            Behavior on color { ColorAnimation { duration: 180 } }
                        }

                        Row {
                            id: dots
                            anchors.left: keyhole.right
                            anchors.leftMargin: 14
                            anchors.right: submit.left
                            anchors.rightMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 7

                            readonly property int shown:
                                Math.min(14, surface.entry.length)

                            Repeater {
                                model: dots.shown

                                Rectangle {
                                    required property int index
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 8
                                    height: 8
                                    radius: 4
                                    antialiasing: true
                                    color: surface.failed ? Colors.bad : Colors.accent
                                    scale: index === dots.shown - 1 ? 1.0 : 0.85
                                    opacity: index === dots.shown - 1 ? 1.0 : 0.7

                                    Component.onCompleted: pop.start()
                                    NumberAnimation {
                                        id: pop
                                        target: parent
                                        property: "scale"
                                        from: 0.2; to: 1.0
                                        duration: 220
                                        easing.type: Easing.OutBack
                                    }
                                    Behavior on scale {
                                        NumberAnimation { duration: 180 }
                                    }
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: surface.entry.length > 14
                                text: "+" + (surface.entry.length - 14)
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.6)
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }

                        Text {
                            anchors.left: keyhole.right
                            anchors.leftMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            visible: surface.entry.length === 0 && !pam.active
                            text: I18n.t("lock.prompt")
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.45)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                        }

                        Item {
                            id: submit
                            anchors.right: parent.right
                            anchors.rightMargin: 8
                            anchors.verticalCenter: parent.verticalCenter
                            width: 36
                            height: 36

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                antialiasing: true
                                color: surface.entry.length > 0 && !pam.active
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                              Colors.accent.b, 0.9)
                                    : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                              Colors.fgDim.b, 0.10)
                                Behavior on color { ColorAnimation { duration: 180 } }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !pam.active
                                    text: "󰌑"
                                    color: surface.entry.length > 0
                                        ? Colors.accentText
                                        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                  Colors.fgDim.b, 0.5)
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 14
                                }

                                Rectangle {
                                    id: spinner
                                    anchors.centerIn: parent
                                    visible: pam.active
                                    width: 20
                                    height: 20
                                    radius: 10
                                    color: "transparent"
                                    antialiasing: true
                                    border.width: 2
                                    border.color: Qt.rgba(Colors.accent.r,
                                                          Colors.accent.g,
                                                          Colors.accent.b, 0.35)

                                    Rectangle {
                                        anchors.top: parent.top
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        anchors.topMargin: -2
                                        width: 4
                                        height: 4
                                        radius: 2
                                        antialiasing: true
                                        color: Colors.accent
                                    }

                                    RotationAnimator on rotation {
                                        running: spinner.visible
                                        loops: Animation.Infinite
                                        from: 0
                                        to: 360
                                        duration: 900
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                enabled: !pam.active
                                onClicked: surface.submit()
                            }
                        }
                    }

                    Row {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: sink.capsOn
                            width: capsText.implicitWidth + 12
                            height: 16
                            radius: 8
                            color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.18)

                            Text {
                                id: capsText
                                anchors.centerIn: parent
                                text: "CAPS"
                                color: Colors.bad
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: Keyboard.code !== ""
                            text: Keyboard.code.toUpperCase()
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.5)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: text !== ""
                            text: surface.notice !== "" ? surface.notice : pam.message
                            color: surface.failed ? Colors.bad
                                 : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.65)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }
                    }

                    TextInput {
                        id: sink
                        anchors.fill: parent
                        opacity: 0
                        focus: true
                        enabled: !pam.active
                        echoMode: TextInput.NoEcho

                        property bool capsOn: false

                        onTextChanged: {
                            surface.entry = text;
                            if (text !== "")
                                surface.failed = false;
                            box.typedGlow = 1;
                            glowOff.restart();
                        }

                        Keys.onReturnPressed: surface.submit()
                        Keys.onEnterPressed: surface.submit()
                        Keys.onPressed: event => {
                            sink.capsOn = (event.modifiers & Qt.KeypadModifier) === 0
                                && event.text.length === 1
                                && event.text === event.text.toUpperCase()
                                && event.text !== event.text.toLowerCase()
                                && (event.modifiers & Qt.ShiftModifier) === 0;
                        }

                        Component.onCompleted: forceActiveFocus()
                    }

                    Timer {
                        id: glowOff
                        interval: 90
                        onTriggered: box.typedGlow = 0
                    }

                    Connections {
                        target: surface
                        function onEntryChanged() {
                            if (surface.entry === "" && sink.text !== "")
                                sink.text = "";
                        }
                    }
                }
            }

            Rectangle {
                visible: Media.has && Media.label !== ""
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.bottomMargin: 40
                anchors.leftMargin: 40

                width: nowRow.implicitWidth + 32
                height: 72
                radius: 18
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
                border.width: 1
                border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                      Colors.outline.b, 0.25)

                Row {
                    id: nowRow
                    anchors.centerIn: parent
                    spacing: 14

                    Rectangle {
                        width: 48
                        height: 48
                        radius: 12
                        clip: true
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                       Colors.bgAlt.b, 0.6)

                        Image {
                            id: lockCover
                            anchors.fill: parent
                            source: Media.art
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 256
                            visible: Media.art !== "" && status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !lockCover.visible
                            text: Media.playing ? "󰝚" : "󰎈"
                            color: Colors.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 18
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            text: Media.title === "" ? Media.label : Media.title
                            color: Colors.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 320)
                        }

                        Text {
                            visible: text !== ""
                            text: Media.artist
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.65)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 320)
                        }
                    }
                }
            }

            Row {
                visible: surface.missed > 0
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 40
                spacing: 8

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 22
                    height: 22
                    radius: 11
                    color: Colors.accent

                    Text {
                        anchors.centerIn: parent
                        text: surface.missed > 99 ? "99+" : String(surface.missed)
                        color: Colors.accentText
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.t("lock.missed") + surface.missedWord(surface.missed)
                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.7)
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }

            Text {
                visible: surface.attempts > 0
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 40
                text: I18n.t("lock.attempts") + surface.attempts + I18n.t("bar.shot")
                color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.7)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
            }
        }
    }
}
