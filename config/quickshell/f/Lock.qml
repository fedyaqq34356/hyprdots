import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

Scope {
    id: root

    property bool locked: false

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

            PamContext {
                id: pam
                config: "hyprlock"

                onPamMessage: {
                    if (pam.responseRequired)
                        pam.respond(surface.entry);
                }

                onCompleted: function (result) {
                    if (result === PamResult.Success) {
                        root.locked = false;
                        return;
                    }

                    surface.attempts++;
                    surface.failed = true;
                    surface.notice = result === PamResult.MaxTries
                        ? "слишком много попыток"
                        : "неверный пароль";
                    surface.entry = "";
                    intruder.running = true;
                    shake.restart();
                }

                onError: function (err) {
                    surface.failed = true;
                    surface.notice = "ошибка PAM: " + err;
                    surface.entry = "";
                }
            }

            function submit() {
                if (surface.entry === "" || pam.active)
                    return;
                surface.notice = "проверяю…";
                surface.failed = false;
                pam.start();
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

                    transform: Translate { id: shift }

                    SequentialAnimation {
                        id: shake
                        NumberAnimation { target: shift; property: "x"; to: 14; duration: 55 }
                        NumberAnimation { target: shift; property: "x"; to: -12; duration: 55 }
                        NumberAnimation { target: shift; property: "x"; to: 7; duration: 55 }
                        NumberAnimation { target: shift; property: "x"; to: 0; duration: 55 }
                    }

                    WaveMeter {
                        anchors.top: parent.top
                        width: parent.width
                        height: 46

                        value: Math.min(0.95, 0.18 + surface.entry.length * 0.09)
                        animating: true
                        spectrum: Cava.active ? Cava.levels : []

                        fillColor: surface.failed ? Colors.bad : Colors.accent
                        trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                            Colors.fgDim.b, 0.22)
                    }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: surface.notice !== "" ? surface.notice
                              : (pam.message !== "" ? pam.message : "введи пароль")
                        color: surface.failed ? Colors.bad
                             : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                       Colors.fgDim.b, 0.65)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    TextInput {
                        id: sink
                        anchors.fill: parent
                        opacity: 0
                        focus: true
                        enabled: !pam.active
                        echoMode: TextInput.NoEcho

                        onTextChanged: {
                            surface.entry = text;
                            if (text !== "")
                                surface.failed = false;
                        }

                        Keys.onReturnPressed: surface.submit()
                        Keys.onEnterPressed: surface.submit()

                        Component.onCompleted: forceActiveFocus()
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

            Text {
                visible: surface.attempts > 0
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 40
                text: "неудачных попыток: " + surface.attempts + "  ·  снимок сохранён"
                color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.7)
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 10
            }
        }
    }
}
