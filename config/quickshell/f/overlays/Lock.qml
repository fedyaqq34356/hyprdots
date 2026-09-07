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

    signal unlocked()

    readonly property string shot:
        "file://" + Quickshell.env("XDG_RUNTIME_DIR") + "/lock-bg.png"

    readonly property string mono: "JetBrainsMono Nerd Font"

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

            Image {
                id: wall
                anchors.fill: parent
                source: root.shot
                fillMode: Image.PreserveAspectCrop
                cache: false
                asynchronous: true
                visible: false
            }

            MultiEffect {
                anchors.fill: parent
                source: wall
                blurEnabled: true
                blur: 1.0
                blurMax: 64
                saturation: -0.25
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.72)
                    }
                    GradientStop {
                        position: 0.45
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.58)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.82)
                    }
                }
            }

            Grain {
                anchors.fill: parent
                amount: 0.03
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

            Column {
                id: clockStack

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.18
                spacing: 6

                RollText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(lockClock.date, "HH:mm")
                    color: Colors.fg
                    family: root.mono
                    pixelSize: 148
                    weight: Font.Thin
                    rollDuration: 520
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 14

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 2
                        radius: 1
                        color: Colors.accent
                        opacity: 0.7
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(lockClock.date, "dddd, d MMMM")
                            .toLowerCase()
                        color: Colors.fgDim
                        opacity: 0.75
                        font.family: root.mono
                        font.pixelSize: 14
                        font.letterSpacing: 3
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 28
                        height: 2
                        radius: 1
                        color: Colors.accent
                        opacity: 0.7
                    }
                }
            }

            Item {
                id: gate

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: clockStack.bottom
                anchors.topMargin: 56
                width: 460
                height: 200

                transform: Translate { id: nudge; x: 0 }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: nudge; property: "x"; to: -14; duration: 55 }
                    NumberAnimation { target: nudge; property: "x"; to: 12;  duration: 65 }
                    NumberAnimation { target: nudge; property: "x"; to: -8;  duration: 65 }
                    NumberAnimation { target: nudge; property: "x"; to: 5;   duration: 60 }
                    NumberAnimation { target: nudge; property: "x"; to: 0;   duration: 70 }
                }

                Rectangle {
                    z: -2
                    anchors.centerIn: card
                    width: card.width - 30
                    height: card.height - 24
                    radius: Shape.modal
                    color: surface.failed ? Colors.bad : Colors.accent
                    opacity: surface.failed ? 0.34 : (pam.active ? 0.28 : 0.18)
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 56
                    }
                }

                Glass {
                    id: card

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: parent.width
                    height: 132
                    radius: Shape.modal
                    elevation: 3
                    tint: Colors.bg
                    tintOpacity: 0.62
                    edge: surface.failed ? Colors.bad : Colors.accent

                    Row {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 18

                        Item {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 76
                            height: 76

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                antialiasing: true
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                               Colors.accent.b, 0.14)
                            }

                            ClippingRectangle {
                                anchors.centerIn: parent
                                width: 68
                                height: 68
                                radius: 34
                                color: "transparent"
                                border.width: 2
                                border.color: surface.failed ? Colors.bad : Colors.accent
                                Behavior on border.color { ColorAnimation { duration: Motion.base } }

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 2
                                    source: "file://" + Quickshell.env("HOME")
                                            + "/.local/share/avatar/avatar.png"
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                visible: pam.active
                                radius: width / 2
                                color: "transparent"
                                antialiasing: true
                                border.width: 2
                                border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                      Colors.accent.b, 0.25)

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.topMargin: -3
                                    width: 7
                                    height: 7
                                    radius: 3.5
                                    antialiasing: true
                                    color: Colors.accent
                                }

                                RotationAnimator on rotation {
                                    running: pam.active
                                    loops: Animation.Infinite
                                    from: 0
                                    to: 360
                                    duration: 1100
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 76 - 18
                            spacing: 10

                            Text {
                                text: Quickshell.env("USER")
                                color: Colors.fg
                                font.family: Fonts.display
                                font.pixelSize: Fonts.headingSize
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                id: box

                                width: parent.width
                                height: 48
                                radius: Shape.field
                                antialiasing: true

                                color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                               Colors.bgAlt.b, 0.5)
                                border.width: 1.5
                                border.color: surface.failed
                                    ? Colors.bad
                                    : (pam.active
                                       ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                 Colors.accent.b, 0.9)
                                       : Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                 Colors.accent.b,
                                                 0.30 + box.typedGlow * 0.55))

                                property real typedGlow: 0
                                Behavior on typedGlow {
                                    NumberAnimation { duration: 480; easing.type: Easing.OutCubic }
                                }
                                Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                                Text {
                                    id: keyhole
                                    anchors.left: parent.left
                                    anchors.leftMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: surface.failed ? "󰍁" : (pam.active ? "󰦝" : "󰌾")
                                    color: surface.failed ? Colors.bad : Colors.accent
                                    font.family: root.mono
                                    font.pixelSize: 17
                                    opacity: 0.9
                                    Behavior on color { ColorAnimation { duration: Motion.fast } }
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
                                            id: dot

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
                                                target: dot
                                                property: "scale"
                                                from: 0.2; to: 1.0
                                                duration: Motion.base
                                                easing.type: Easing.Bezier
                                                easing.bezierCurve: Motion.snap
                                            }
                                            Behavior on scale {
                                                NumberAnimation { duration: Motion.fast }
                                            }
                                            Behavior on color {
                                                ColorAnimation { duration: Motion.fast }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        visible: surface.entry.length > 14
                                        text: "+" + (surface.entry.length - 14)
                                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                       Colors.fgDim.b, 0.6)
                                        font.family: root.mono
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
                                    font.family: root.mono
                                    font.pixelSize: 13
                                }

                                Rectangle {
                                    id: submit

                                    anchors.right: parent.right
                                    anchors.rightMargin: 7
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 34
                                    height: 34
                                    radius: width / 2
                                    antialiasing: true

                                    color: surface.entry.length > 0 && !pam.active
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                  Colors.accent.b, 0.9)
                                        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                  Colors.fgDim.b, 0.10)
                                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                                    scale: submitArea.pressed ? 0.92 : 1
                                    Behavior on scale { NumberAnimation { duration: Motion.fast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "󰌑"
                                        color: surface.entry.length > 0
                                            ? Colors.accentText
                                            : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                      Colors.fgDim.b, 0.5)
                                        font.family: root.mono
                                        font.pixelSize: 14
                                    }

                                    MouseArea {
                                        id: submitArea
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        enabled: !pam.active
                                        onClicked: surface.submit()
                                    }
                                }
                            }
                        }
                    }
                }

                Row {
                    anchors.top: card.bottom
                    anchors.topMargin: 16
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: sink.capsOn
                        width: capsText.implicitWidth + 16
                        height: 20
                        radius: Shape.detail
                        antialiasing: true
                        color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.20)

                        Text {
                            id: capsText
                            anchors.centerIn: parent
                            text: "CAPS"
                            color: Colors.bad
                            font.family: root.mono
                            font.pixelSize: 9
                            font.weight: Font.Bold
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: text !== ""
                        text: surface.notice !== "" ? surface.notice : pam.message
                        color: surface.failed ? Colors.bad
                             : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                       Colors.fgDim.b, 0.7)
                        font.family: root.mono
                        font.pixelSize: 12
                        Behavior on color { ColorAnimation { duration: Motion.base } }
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

            Rectangle {
                visible: Media.has && Media.label !== ""
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.bottomMargin: 40
                anchors.leftMargin: 40

                width: nowRow.implicitWidth + 36
                height: 76
                radius: Shape.card
                antialiasing: true
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.5)

                Sheen {
                    anchors.fill: parent
                    radius: Shape.card
                    edgeOpacity: 0.18
                }

                Row {
                    id: nowRow
                    anchors.centerIn: parent
                    spacing: 14

                    ClippingRectangle {
                        width: 50
                        height: 50
                        radius: Shape.chip
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
                            font.family: root.mono
                            font.pixelSize: 18
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5

                        Text {
                            text: Media.title === "" ? Media.label : Media.title
                            color: Colors.fg
                            font.family: root.mono
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
                            font.family: root.mono
                            font.pixelSize: 10
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, 320)
                        }

                        Rectangle {
                            visible: Media.hasPosition
                            width: Math.min(320, Math.max(120, nowRow.implicitWidth - 80))
                            height: 3
                            radius: 1.5
                            color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                           Colors.outline.b, 0.25)

                            Rectangle {
                                width: parent.width
                                       * Math.max(0, Math.min(1, Media.progress))
                                height: parent.height
                                radius: parent.radius
                                color: Colors.accent
                                Behavior on width { NumberAnimation { duration: Motion.base } }
                            }
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
