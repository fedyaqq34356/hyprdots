import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Services.UPower
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool locked: false

    WeatherHold { active: root.locked }

    signal unlocked()

    readonly property string shot:
        "file://" + Quickshell.env("XDG_RUNTIME_DIR") + "/lock-bg.png"

    readonly property string mono: Fonts.mono

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

            readonly property var battery: UPower.displayDevice
            readonly property bool hasBattery:
                surface.battery !== null && surface.battery.isLaptopBattery
            readonly property int batteryPct:
                surface.hasBattery ? Math.round(surface.battery.percentage * 100) : 0
            readonly property bool charging: surface.hasBattery
                && surface.battery.state === UPowerDeviceState.Charging

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
                    sink.text = "";
                    intruder.running = true;
                    shake.restart();
                }

                onError: function (err) {
                    surface.failed = true;
                    surface.notice = I18n.t("lock.pamError") + err;
                    surface.entry = "";
                    shake.restart();
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

            LockFace {
                id: lockFace
                anchors.fill: parent
                live: root.locked
            }

            SystemClock {
                id: lockClock
                precision: SystemClock.Minutes
            }

            Row {
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: 40
                spacing: 10

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Weather.ready
                    width: weatherRow.implicitWidth + 26
                    height: 36
                    radius: Shape.chip
                    antialiasing: true
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)
                    border.width: 1
                    border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                          Colors.outline.b, 0.18)

                    Row {
                        id: weatherRow
                        anchors.centerIn: parent
                        spacing: 9

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Weather.glyph
                            color: Weather.tint
                            font.family: root.mono
                            font.pixelSize: 15
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Math.round(Weather.temp) + "°"
                            color: Colors.fg
                            opacity: 0.85
                            font.family: root.mono
                            font.pixelSize: 13
                        }
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: Keyboard.code !== ""
                    width: layoutLabel.implicitWidth + 24
                    height: 36
                    radius: Shape.chip
                    antialiasing: true
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)
                    border.width: 1
                    border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                          Colors.outline.b, 0.18)

                    Text {
                        id: layoutLabel
                        anchors.centerIn: parent
                        text: Keyboard.code.toUpperCase()
                        color: Colors.fgDim
                        opacity: 0.85
                        font.family: root.mono
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                    }
                }

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: surface.hasBattery
                    width: batteryRow.implicitWidth + 26
                    height: 36
                    radius: Shape.chip
                    antialiasing: true
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)
                    border.width: 1
                    border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                          Colors.outline.b, 0.18)

                    Row {
                        id: batteryRow
                        anchors.centerIn: parent
                        spacing: 9

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: surface.charging ? "󰂄" : "󰁹"
                            color: surface.charging ? Colors.good
                                 : surface.batteryPct <= 15 ? Colors.bad : Colors.accent
                            font.family: root.mono
                            font.pixelSize: 14
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: surface.batteryPct + "%"
                            color: Colors.fg
                            opacity: 0.85
                            font.family: root.mono
                            font.pixelSize: 12
                        }
                    }
                }
            }

            Item {
                id: gate

                anchors.horizontalCenter: parent.horizontalCenter
                y: parent.height * 0.6
                width: 320
                height: 200

                property real sway: 0
                transform: Translate { x: gate.sway }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: gate; property: "sway"; to: -11; duration: 120; easing.type: Easing.InOutSine }
                    NumberAnimation { target: gate; property: "sway"; to: 8;   duration: 200; easing.type: Easing.InOutSine }
                    NumberAnimation { target: gate; property: "sway"; to: -5;  duration: 190; easing.type: Easing.InOutSine }
                    NumberAnimation { target: gate; property: "sway"; to: 2;   duration: 180; easing.type: Easing.InOutSine }
                    NumberAnimation { target: gate; property: "sway"; to: 0;   duration: 180; easing.type: Easing.InOutSine }
                }

                Item {
                    id: face
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 72
                    height: 72

                    property real breath: 0
                    SequentialAnimation on breath {
                        running: pam.active
                        loops: Animation.Infinite
                        onStopped: face.breath = 0
                        NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0; duration: 700; easing.type: Easing.InOutSine }
                    }

                    RectangularShadow {
                        anchors.fill: parent
                        radius: width / 2
                        blur: 30 + 14 * face.breath
                        spread: 2 * face.breath
                        color: Colors.alpha(surface.failed ? Colors.bad : Colors.accent,
                                            0.35 + 0.3 * face.breath)
                        Behavior on color { ColorAnimation { duration: 500 } }
                    }

                    ClippingRectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(0, 0, 0, 0.4)

                        Image {
                            anchors.fill: parent
                            source: "file://" + Quickshell.env("HOME")
                                    + "/.local/share/avatar/avatar.png"
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: "transparent"
                        antialiasing: true
                        border.width: 1.5
                        border.color: Qt.rgba(1, 1, 1, 0.35)
                    }
                }

                Text {
                    id: who
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: face.bottom
                    anchors.topMargin: 12
                    text: Quickshell.env("USER")
                    color: Qt.rgba(1, 1, 1, 0.92)
                    font.family: Fonts.display
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    id: box

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: who.bottom
                    anchors.topMargin: 16
                    width: 250
                    height: 40
                    radius: height / 2
                    antialiasing: true
                    clip: true

                    color: Qt.rgba(0, 0, 0, 0.30)
                    border.width: 1
                    border.color: surface.failed ? Colors.alpha(Colors.bad, 0.85)
                                 : Qt.rgba(1, 1, 1, 0.16 + 0.22 * box.typedGlow)

                    property real typedGlow: 0
                    Behavior on typedGlow { NumberAnimation { duration: 600; easing.type: Easing.OutCubic } }
                    Behavior on border.color { ColorAnimation { duration: 450 } }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: Colors.bad
                        opacity: surface.failed ? 0.22 : 0
                        Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.InOutCubic } }
                    }

                    Rectangle {
                        id: sweep
                        width: 90
                        height: parent.height
                        visible: pam.active
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.16) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        NumberAnimation on x {
                            running: pam.active
                            loops: Animation.Infinite
                            from: -90; to: 250
                            duration: 1300
                            easing.type: Easing.InOutSine
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: I18n.t("lock.prompt")
                        color: Qt.rgba(1, 1, 1, 0.45)
                        font.family: Fonts.display
                        font.pixelSize: 13
                        opacity: surface.entry.length === 0 && !pam.active ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 260 } }
                    }

                    Row {
                        id: dots
                        anchors.centerIn: parent
                        spacing: 8

                        readonly property int shown: Math.min(16, surface.entry.length)

                        Repeater {
                            model: dots.shown

                            Rectangle {
                                id: dot
                                width: 7
                                height: 7
                                radius: 3.5
                                antialiasing: true
                                anchors.verticalCenter: parent.verticalCenter
                                color: surface.failed ? Colors.bad : "white"
                                opacity: 0
                                scale: 0.4
                                Behavior on color { ColorAnimation { duration: 300 } }

                                Component.onCompleted: dotIn.start()
                                ParallelAnimation {
                                    id: dotIn
                                    NumberAnimation { target: dot; property: "opacity"; to: 0.95; duration: 280; easing.type: Easing.OutCubic }
                                    NumberAnimation { target: dot; property: "scale"; to: 1; duration: 340; easing.type: Easing.OutCubic }
                                }
                            }
                        }
                    }
                }

                Row {
                    anchors.top: box.bottom
                    anchors.topMargin: 14
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: sink.capsOn
                        text: "Caps Lock"
                        color: Colors.alpha(Colors.bad, 0.9)
                        font.family: Fonts.display
                        font.pixelSize: 12
                        font.weight: Font.DemiBold
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: text !== ""
                        text: surface.notice !== "" ? surface.notice : pam.message
                        color: surface.failed ? Colors.alpha(Colors.bad, 0.95) : Qt.rgba(1, 1, 1, 0.6)
                        font.family: Fonts.display
                        font.pixelSize: 12
                        Behavior on color { ColorAnimation { duration: 400 } }
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

            Item {
                id: nowCard

                visible: Media.has && Media.label !== ""
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.bottomMargin: 40
                anchors.leftMargin: 40

                width: 348
                height: 96

                Glass {
                    anchors.fill: parent
                    radius: Shape.card
                    elevation: 2
                    specular: false
                }

                Row {
                    anchors.fill: parent
                    anchors.leftMargin: Shape.padBase
                    anchors.rightMargin: Shape.padBase
                    spacing: 16

                    Item {
                        id: discSlot

                        width: 64
                        height: 64
                        anchors.verticalCenter: parent.verticalCenter

                        Bloom {
                            target: disc
                            tint: Colors.accent
                            amount: Media.playing ? 0.20 : 0.07
                            radius: disc.width / 2
                            inset: -14
                            blurMax: 32
                        }

                        ProgressRing {
                            anchors.fill: parent
                            visible: Media.hasPosition
                            value: Math.max(0, Math.min(1, Media.progress))
                            color: Colors.accent
                            trackColor: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                Colors.outline.b, 0.22)
                            thickness: 2.5
                            inset: 1
                        }

                        Vinyl {
                            id: disc

                            anchors.centerIn: parent
                            width: parent.width - 12
                            height: width
                            art: Media.art
                            spinning: Media.playing
                            grooves: 6
                            labelRatio: 0.58
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - discSlot.width - parent.spacing
                        spacing: 6

                        Marquee {
                            width: parent.width
                            text: Media.title === "" ? Media.label : Media.title
                            color: Colors.fg
                            family: root.mono
                            pixelSize: 12
                            weight: Font.DemiBold
                        }

                        Text {
                            visible: text !== ""
                            width: parent.width
                            text: Media.artist
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.7)
                            font.family: root.mono
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }

                        Text {
                            visible: text !== ""
                            text: Media.source.toLowerCase()
                            color: Colors.accentAlt
                            font.family: root.mono
                            font.pixelSize: 9
                            font.letterSpacing: 2
                            opacity: 0.75
                        }
                    }
                }
            }

            Row {
                visible: surface.missed > 0
                anchors.bottom: parent.bottom
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottomMargin: 44
                spacing: 10

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 24
                    height: 24
                    radius: 12
                    antialiasing: true
                    color: Colors.accent

                    Text {
                        anchors.centerIn: parent
                        text: surface.missed > 99 ? "99+" : String(surface.missed)
                        color: Colors.accentText
                        font.family: root.mono
                        font.pixelSize: 10
                        font.weight: Font.Bold
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.t("lock.missed") + surface.missedWord(surface.missed)
                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.7)
                    font.family: root.mono
                    font.pixelSize: 11
                }
            }

            Rectangle {
                visible: surface.attempts > 0
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                anchors.margins: 40
                width: attemptsLabel.implicitWidth + 24
                height: 30
                radius: Shape.chip
                antialiasing: true
                color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.16)
                border.width: 1
                border.color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.35)

                Text {
                    id: attemptsLabel
                    anchors.centerIn: parent
                    text: I18n.t("lock.attempts") + surface.attempts + I18n.t("bar.shot")
                    color: Colors.bad
                    opacity: 0.9
                    font.family: root.mono
                    font.pixelSize: 10
                }
            }
        }
    }
}
