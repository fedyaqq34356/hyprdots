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
                        unlockFx.running = true;
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
                id: unlockFx
                command: ["qs", "-c", "f", "ipc", "call", "curtain", "up"]
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
                        id: pulse
                        anchors.top: parent.top
                        width: parent.width
                        height: 46
                        radius: 23
                        color: "transparent"
                        border.width: 1
                        border.color: surface.failed ? Colors.bad : Colors.accent
                        opacity: 0
                        scale: 1.0
                    }

                    ParallelAnimation {
                        id: pulseBeat
                        NumberAnimation {
                            target: pulse; property: "opacity"
                            from: 0.75; to: 0; duration: 420
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target: pulse; property: "scale"
                            from: 0.97; to: 1.06; duration: 420
                            easing.type: Easing.OutCubic
                        }
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
                              : (pam.message !== "" ? pam.message : I18n.t("lock.prompt"))
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
                            pulseBeat.restart();
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
