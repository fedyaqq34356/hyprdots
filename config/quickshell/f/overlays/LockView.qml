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

Item {
    id: view

    required property var host
    property var screen: null
    property bool preview: false

    function simType(n) { surface.simType(n); }
    function simFail() { surface.simFail(); }
    function simOk() { surface.simOk(); }
    function simWake(on) { surface.simWake(on); }

    Item {
        id: surface
        anchors.fill: parent
        readonly property var screen: view.screen

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
                    surface.notice = "";
                    okRun.restart();
                    unlockGuard.restart();
                    return;
                }

                surface.attempts++;
                surface.failed = true;
                surface.notice = result === PamResult.MaxTries
                    ? I18n.t("lock.tooMany")
                    : I18n.t("lock.wrong");
                intruder.running = true;
                failRun.restart();
            }

            onError: function (err) {
                surface.failed = true;
                surface.notice = I18n.t("lock.pamError") + err;
                surface.entry = "";
                shake.restart();
            }
        }

        Timer {
            id: unlockGuard
            interval: 1500
            onTriggered: {
                if (view.host.locked && !view.preview) {
                    view.host.unlocked();
                    view.host.locked = false;
                }
            }
        }

        function simType(n) { sink.text = "•".repeat(Math.max(0, n)); }
        function simFail() {
            surface.attempts++;
            surface.failed = true;
            surface.notice = I18n.t("lock.wrong");
            failRun.restart();
        }
        function simOk() { surface.failed = false; surface.notice = ""; okRun.restart(); }
        function simWake(on) { if (on) gate.poke(); else gate.awake = false; }

        function submit() {
            if (view.preview)
                return;
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
                      + "/.config/hypr/scripts/lock/lock-intruder.sh"]
        }

        LockFace {
            id: lockFace
            anchors.fill: parent
            live: view.host.locked
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
                        font.family: Fonts.mono
                        font.features: { "tnum": 1 }
                        font.pixelSize: 15
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Math.round(Weather.temp) + "°"
                        color: Colors.fg
                        opacity: 0.85
                        font.family: Fonts.mono
                        font.features: { "tnum": 1 }
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
                    font.family: Fonts.mono
                    font.features: { "tnum": 1 }
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
                        font.family: Fonts.mono
                        font.features: { "tnum": 1 }
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: surface.batteryPct + "%"
                        color: Colors.fg
                        opacity: 0.85
                        font.family: Fonts.mono
                        font.features: { "tnum": 1 }
                        font.pixelSize: 12
                    }
                }
            }
        }

        Item {
            id: gate
            anchors.fill: parent

            readonly property real barH: BarConfig.s("barHeight", surface.screen ? surface.screen.name : "")
            readonly property real pillH: IslandConfig.s("pillHeight")
            readonly property real topCy: gate.barH / 2
            readonly property real fieldCy: gate.height * 0.64
            readonly property real isleW: 116
            readonly property real fieldW: 360
            readonly property real fieldH: 62

            property bool awake: false
            function poke() {
                gate.awake = true;
                doze.restart();
            }
            Timer {
                id: doze
                interval: 30000
                onTriggered: {
                    if (surface.entry === "" && !pam.active)
                        gate.awake = false;
                    else
                        doze.restart();
                }
            }
            Connections {
                target: root
                function onLockedChanged() {
                    if (view.host.locked) {
                        gate.awake = false;
                        gate.snap = 0;
                        gate.merge = 0;
                        gate.burst = 0;
                    }
                }
            }

            MorphSpring {
                id: wake
                response: 0.62
                damping: 0.88
                closeMs: 520
                softClose: true
                target: gate.awake ? 1 : 0
            }
            readonly property real w: Math.max(0, wake.value)
            readonly property real grow: Math.max(0, Math.min(1, (gate.w - 0.25) / 0.6))

            property real sway: 0
            SequentialAnimation {
                id: shake
                NumberAnimation { target: gate; property: "sway"; to: -14; duration: 90; easing.type: Easing.InOutSine }
                NumberAnimation { target: gate; property: "sway"; to: 11;  duration: 140; easing.type: Easing.InOutSine }
                NumberAnimation { target: gate; property: "sway"; to: -7;  duration: 140; easing.type: Easing.InOutSine }
                NumberAnimation { target: gate; property: "sway"; to: 3;   duration: 130; easing.type: Easing.InOutSine }
                NumberAnimation { target: gate; property: "sway"; to: 0;   duration: 130; easing.type: Easing.InOutSine }
            }

            readonly property real bw: Motion.mix(gate.isleW, gate.fieldW, gate.grow) * (1 - 0.18 * Math.sin(Math.PI * gate.w) * (1 - gate.grow))
            readonly property real bh: Motion.mix(gate.pillH, gate.fieldH, gate.grow) * (1 + 0.25 * Math.sin(Math.PI * Math.min(1, gate.w)) * (1 - gate.grow))
            readonly property real bcx: gate.width / 2 + gate.sway
            readonly property real bcy: Motion.mix(gate.topCy, gate.fieldCy, gate.w)

            readonly property real ay: gate.topCy + gate.pillH / 2 - 6
            readonly property real by: gate.bcy - gate.bh / 2 + 8
            readonly property real gap: gate.by - gate.ay
            property real snap: 0
            NumberAnimation { id: breakRun; target: gate; property: "snap"; to: 1; duration: 360; easing.type: Easing.OutCubic }
            NumberAnimation { id: mendRun; target: gate; property: "snap"; to: 0; duration: 320; easing.type: Easing.OutCubic }
            onWChanged: {
                if (gate.awake && (gate.w > 0.9 || gate.gap > 190) && gate.snap < 1 && !breakRun.running) {
                    mendRun.stop();
                    breakRun.restart();
                } else if (!gate.awake && gate.snap > 0 && !mendRun.running && gate.w < 0.6) {
                    breakRun.stop();
                    mendRun.restart();
                }
            }
            function neckW(s) {
                const th = Math.max(0, Math.min(1, 1 - gate.gap / 260));
                const base = Motion.mix(16, 30, s * s);
                const pinch = 1 - (1 - Math.pow(th, 0.7)) * 0.88 * Math.sin(Math.PI * s);
                const mid = 1 - Math.abs(2 * s - 1);
                const cut = Math.max(0, Math.min(1, 1 - gate.snap * (1 + 2 * mid)));
                return base * pinch * cut;
            }

            Item {
                id: gooHost
                anchors.fill: parent

                Item {
                    property bool isBlob: true
                    width: gate.isleW
                    height: gate.pillH
                    x: gate.width / 2 - width / 2
                    y: gate.topCy - height / 2
                }
                Item {
                    property bool isBlob: true
                    width: gate.bw
                    height: gate.bh
                    x: gate.bcx - width / 2
                    y: gate.bcy - height / 2
                    onXChanged: lockGoo.applySync()
                    onYChanged: lockGoo.applySync()
                    onWidthChanged: lockGoo.applySync()
                    onHeightChanged: lockGoo.applySync()
                }
                Repeater {
                    model: 7
                    Item {
                        id: bead
                        required property int index
                        property bool isBlob: true
                        readonly property real s0: (bead.index + 0.5) / 7
                        readonly property real u: bead.s0 < 0.5 ? bead.s0 * (1 - gate.snap) : bead.s0 + (1 - bead.s0) * gate.snap
                        readonly property real bw: gate.gap > 4 ? gate.neckW(bead.s0) : 0
                        visible: bead.bw > 1.5
                        width: Math.max(0.1, bead.bw)
                        height: Math.max(bead.bw, gate.gap / 7 * 1.6)
                        x: gate.width / 2 + gate.sway * bead.u - width / 2
                        y: Motion.mix(gate.ay, gate.by, bead.u) - height / 2
                        onXChanged: lockGoo.applySync()
                        onYChanged: lockGoo.applySync()
                        onWidthChanged: lockGoo.applySync()
                        onVisibleChanged: lockGoo.applySync()
                    }
                }
            }

            property real breath: 0
            SequentialAnimation on breath {
                running: pam.active
                loops: Animation.Infinite
                onStopped: gate.breath = 0
                NumberAnimation { to: 1; duration: 700; easing.type: Easing.InOutSine }
                NumberAnimation { to: 0; duration: 700; easing.type: Easing.InOutSine }
            }
            RectangularShadow {
                x: gate.bcx - gate.bw / 2
                y: gate.bcy - gate.bh / 2 + 6
                width: gate.bw
                height: gate.bh
                radius: gate.bh / 2
                blur: 40 + 20 * gate.breath
                spread: 2 * gate.breath
                color: Colors.alpha(surface.failed ? Colors.bad : Colors.accent,
                                    (0.35 + 0.3 * gate.breath) * gate.grow)
                Behavior on color { ColorAnimation { duration: 500 } }
            }

            Blobs {
                id: lockGoo
                host: gooHost
                fuse: 24
                corner: 40
                stroke: 1
                shadow: false
                fillColor: "black"
                fillAlpha: 0.92
                hoverColor: "black"
                hoverAlpha: 0.92
                strokeColor: surface.failed ? Colors.bad : "white"
                strokeAlpha: surface.failed ? 0.7 : 0.10 + 0.12 * gate.grow
            }
            Timer { interval: 80; running: true; onTriggered: lockGoo.applySync() }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                y: gate.topCy - height / 2
                text: "󰌾"
                color: Qt.rgba(1, 1, 1, 0.8)
                font.family: Fonts.glyph
                font.pixelSize: 15
                opacity: 1 - gate.grow * 0.4
            }

            Item {
                id: field
                x: gate.bcx - gate.fieldW / 2
                y: gate.bcy - gate.fieldH / 2
                width: gate.fieldW
                height: gate.fieldH
                opacity: Math.max(0, Math.min(1, (gate.w - 0.7) / 0.3))
                visible: opacity > 0.01

                ClippingRectangle {
                    id: avatar
                    x: 11
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: 20
                    color: Qt.rgba(1, 1, 1, 0.08)
                    Image {
                        anchors.fill: parent
                        source: "file://" + Quickshell.env("HOME") + "/.local/share/avatar/avatar.png"
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                Text {
                    anchors.left: avatar.right
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.t("lock.prompt")
                    color: Qt.rgba(1, 1, 1, 0.42)
                    font.family: Fonts.display
                    font.features: { "tnum": 1 }
                    font.pixelSize: 14
                    opacity: surface.entry.length === 0 && !pam.active && gate.merge === 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 260 } }
                }

                Item {
                    anchors.fill: parent
                    clip: true
                    visible: pam.active
                    Rectangle {
                        width: 120
                        height: parent.height
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: "transparent" }
                            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.12) }
                            GradientStop { position: 1.0; color: "transparent" }
                        }
                        NumberAnimation on x {
                            running: pam.active
                            loops: Animation.Infinite
                            from: -120; to: gate.fieldW
                            duration: 1200
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                Item {
                    id: beadRow
                    anchors.left: avatar.right
                    anchors.leftMargin: 16
                    anchors.right: go.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter
                    height: 30

                    readonly property int n: Math.min(18, surface.entry.length)
                    readonly property real step: 17
                    readonly property real span: Math.max(0, beadRow.n - 1) * beadRow.step
                    readonly property real x0: (beadRow.width - beadRow.span) / 2

                    Repeater {
                        model: beadRow.n
                        Item {
                            id: dot
                            required property int index
                            property bool isBlob: true
                            property real born: 0
                            Component.onCompleted: bornRun.start()
                            NumberAnimation {
                                id: bornRun
                                target: dot; property: "born"; to: 1
                                duration: 360; easing.type: Easing.OutBack; easing.overshoot: 1.2
                            }
                            readonly property real size: 10 * dot.born * (1 - gate.burst)
                                * (1 + 0.7 * gate.merge)
                            property real cx: Motion.mix(beadRow.x0 + dot.index * beadRow.step,
                                                                  beadRow.width / 2, gate.merge)
                            Behavior on cx { enabled: gate.merge === 0; NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            width: Math.max(0.1, dot.size)
                            height: Math.max(0.1, dot.size)
                            x: dot.cx - width / 2
                            y: beadRow.height / 2 - height / 2 - 6 * gate.burst * ((dot.index % 3) - 1)
                            onXChanged: dotGoo.applySync()
                            onYChanged: dotGoo.applySync()
                            onWidthChanged: dotGoo.applySync()
                        }
                    }
                }

                Blobs {
                    id: dotGoo
                    host: beadRow
                    fuse: 11
                    corner: 6
                    stroke: 0
                    shadow: false
                    fillColor: surface.failed ? Colors.bad : gate.merge > 0 ? Colors.good : "white"
                    fillAlpha: 0.95
                    hoverColor: "white"
                    hoverAlpha: 0.95
                    strokeAlpha: 0
                }

                Rectangle {
                    id: go
                    anchors.right: parent.right
                    anchors.rightMargin: 11
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    radius: 20
                    color: Colors.alpha(Colors.accent, surface.entry !== "" ? 0.9 : 0.12)
                    scale: surface.entry !== "" ? 1 : 0.8
                    Behavior on color { ColorAnimation { duration: 260 } }
                    Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    Text {
                        anchors.centerIn: parent
                        text: "󰁔"
                        color: surface.entry !== "" ? Colors.accentText : Qt.rgba(1, 1, 1, 0.4)
                        font.family: Fonts.glyph
                        font.pixelSize: 18
                    }
                    TapHandler { onTapped: surface.submit() }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                y: gate.bcy + gate.fieldH / 2 + 18
                spacing: 10
                opacity: field.opacity
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: sink.capsOn
                    text: "Caps Lock"
                    color: Colors.alpha(Colors.bad, 0.9)
                    font.family: Fonts.display
                    font.features: { "tnum": 1 }
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: text !== ""
                    text: surface.notice !== "" ? surface.notice : pam.message
                    color: surface.failed ? Colors.alpha(Colors.bad, 0.95) : Qt.rgba(1, 1, 1, 0.6)
                    font.family: Fonts.display
                    font.features: { "tnum": 1 }
                    font.pixelSize: 12
                    Behavior on color { ColorAnimation { duration: 400 } }
                }
            }

            property real burst: 0
            property real merge: 0

            SequentialAnimation {
                id: failRun
                ScriptAction { script: shake.restart() }
                NumberAnimation { target: gate; property: "burst"; to: 1; duration: 380; easing.type: Easing.InCubic }
                ScriptAction {
                    script: {
                        surface.entry = "";
                        sink.text = "";
                        gate.burst = 0;
                    }
                }
            }

            SequentialAnimation {
                id: okRun
                NumberAnimation { target: gate; property: "merge"; to: 1; duration: 340; easing.type: Easing.InOutCubic }
                PauseAnimation { duration: 120 }
                ScriptAction {
                    script: {
                        view.host.unlocked();
                        view.host.locked = false;
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                z: -1
                property point last: Qt.point(-1, -1)
                onPositionChanged: (m) => {
                    if (last.x >= 0 && (Math.abs(m.x - last.x) + Math.abs(m.y - last.y)) > 6)
                        gate.poke();
                    last = Qt.point(m.x, m.y);
                }
                onClicked: { gate.poke(); sink.forceActiveFocus(); }
            }

            TextInput {
                id: sink
                x: -10000
                width: 10
                focus: true
                enabled: !pam.active
                echoMode: TextInput.NoEcho
                property bool capsOn: false
                onTextChanged: {
                    surface.entry = text;
                    if (text !== "")
                        surface.failed = false;
                    gate.poke();
                }
                Keys.onReturnPressed: surface.submit()
                Keys.onEnterPressed: surface.submit()
                Keys.onEscapePressed: { sink.text = ""; gate.awake = false; }
                Keys.onPressed: event => {
                    gate.poke();
                    sink.capsOn = (event.modifiers & Qt.KeypadModifier) === 0
                        && event.text.length === 1
                        && event.text === event.text.toUpperCase()
                        && event.text !== event.text.toLowerCase()
                        && (event.modifiers & Qt.ShiftModifier) === 0;
                }
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
                        family: Fonts.mono
                        pixelSize: 12
                        weight: Font.DemiBold
                    }

                    Text {
                        visible: text !== ""
                        width: parent.width
                        text: Media.artist
                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                       Colors.fgDim.b, 0.7)
                        font.family: Fonts.mono
                        font.features: { "tnum": 1 }
                        font.pixelSize: 10
                        elide: Text.ElideRight
                    }

                    Text {
                        visible: text !== ""
                        text: Media.source.toLowerCase()
                        color: Colors.accentAlt
                        font.family: Fonts.mono
                        font.features: { "tnum": 1 }
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
                    font.family: Fonts.mono
                    font.features: { "tnum": 1 }
                    font.pixelSize: 10
                    font.weight: Font.Bold
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.t("lock.missed") + surface.missedWord(surface.missed)
                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.7)
                font.family: Fonts.mono
                font.features: { "tnum": 1 }
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
                font.family: Fonts.mono
                font.features: { "tnum": 1 }
                font.pixelSize: 10
            }
        }
    }
}
