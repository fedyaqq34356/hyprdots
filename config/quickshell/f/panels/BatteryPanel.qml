import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    function toggle() {
        root.shown = !root.shown;
    }

    function close() {
        root.shown = false;
    }

    property var sys: ({})

    readonly property real watts: {
        const p = Number(root.sys.POWER_NOW || 0);
        if (p > 0)
            return p / 1e6;
        const i = Number(root.sys.CURRENT_NOW || 0);
        const v = Number(root.sys.VOLTAGE_NOW || 0);
        return i > 0 && v > 0 ? i * v / 1e12 : 0;
    }
    readonly property real energyNow: Number(root.sys.ENERGY_NOW || 0) / 1e6
    readonly property real energyFull: Number(root.sys.ENERGY_FULL || 0) / 1e6
    readonly property real energyDesign: Number(root.sys.ENERGY_FULL_DESIGN || 0) / 1e6
    readonly property int cycles: Number(root.sys.CYCLE_COUNT || 0)
    readonly property int health: root.energyDesign > 0
        ? Math.round(root.energyFull / root.energyDesign * 100) : -1

    readonly property real seconds: {
        const d = Power.dev;
        const t = d ? (Power.charging ? d.timeToFull : d.timeToEmpty) : 0;
        if (t > 0)
            return t;
        if (root.watts <= 0.05)
            return 0;
        if (Power.charging)
            return Math.max(0, root.energyFull - root.energyNow) / root.watts * 3600;
        if (!Power.plugged)
            return root.energyNow / root.watts * 3600;
        return 0;
    }

    function span(t) {
        const h = Math.floor(t / 3600);
        const m = Math.max(1, Math.round((t % 3600) / 60));
        return (h > 0 ? h + I18n.t("unit.hourSpace") : "") + m + I18n.t("unit.min");
    }

    readonly property string headline: {
        if (!Power.present)
            return I18n.t("bat.none");
        if (Power.full || (Power.plugged && Power.percent >= 99))
            return I18n.t("bat.full");
        if (Power.charging)
            return root.seconds > 0 ? I18n.t("bat.toFull") + " " + root.span(root.seconds)
                                    : I18n.t("bat.charging");
        if (Power.plugged)
            return I18n.t("bat.resting");
        return root.seconds > 0 ? I18n.t("bat.lasts") + " " + root.span(root.seconds)
                                : I18n.t("bat.counting");
    }

    property date now: new Date()

    readonly property string subline: {
        if (!Power.present || root.seconds <= 0)
            return Power.plugged ? I18n.t("bat.onAc") : I18n.t("bat.onBattery");
        const at = new Date(root.now.getTime() + root.seconds * 1000);
        return (Power.charging ? I18n.t("bat.fullAt") : I18n.t("bat.emptyAt"))
            + " " + Qt.formatTime(at, "HH:mm");
    }

    readonly property color ink: {
        if (Power.charging || Power.plugged)
            return Colors.good;
        if (Power.percent <= Power.lowAt)
            return Colors.bad;
        if (Power.percent <= 30)
            return Colors.warn;
        return Colors.good;
    }

    Process {
        id: reader
        command: ["sh", "-c",
                  "for b in /sys/class/power_supply/BAT*; do cat \"$b/uevent\"; break; done"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = {};
                for (const line of text.split("\n")) {
                    const eq = line.indexOf("=");
                    if (eq > 0)
                        out[line.slice(0, eq).replace("POWER_SUPPLY_", "")] = line.slice(eq + 1).trim();
                }
                root.sys = out;
            }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: root.shown
        onTriggered: {
            root.now = new Date();
            reader.running = false;
            reader.running = true;
        }
    }

    component Swap: Item {
        id: sw
        property string text: ""
        property color color: Colors.fg
        property string family: Fonts.display
        property int pixelSize: Fonts.medium
        property int weight: Font.Medium

        implicitWidth: Math.max(a.implicitWidth, b.implicitWidth)
        implicitHeight: a.implicitHeight

        property bool flip: false
        property string shownA: ""
        property string shownB: ""
        Component.onCompleted: sw.shownA = sw.text

        onTextChanged: {
            if (sw.flip) sw.shownA = sw.text; else sw.shownB = sw.text;
            sw.flip = !sw.flip;
        }

        Text {
            id: a
            anchors.horizontalCenter: parent.horizontalCenter
            text: sw.shownA
            color: sw.color
            font.family: sw.family
            font.features: { "tnum": 1 }
            font.pixelSize: sw.pixelSize
            font.weight: sw.weight
            opacity: sw.flip ? 0 : 1
            y: sw.flip ? -6 : 0
            Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        }
        Text {
            id: b
            anchors.horizontalCenter: parent.horizontalCenter
            text: sw.shownB
            color: sw.color
            font.family: sw.family
            font.features: { "tnum": 1 }
            font.pixelSize: sw.pixelSize
            font.weight: sw.weight
            opacity: sw.flip ? 1 : 0
            y: sw.flip ? 0 : 6
            Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
            Behavior on y { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
        }
    }

    component Fact: Column {
        id: fact
        property string value: ""
        property string label: ""
        spacing: 4
        width: 110

        Swap {
            anchors.horizontalCenter: parent.horizontalCenter
            text: fact.value
            family: Fonts.mono
            pixelSize: Fonts.large
            weight: Font.DemiBold
            color: Colors.fg
        }
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: fact.label
            color: Colors.alpha(Colors.fgDim, 0.6)
            font.family: Fonts.mono
            font.features: { "tnum": 1 }
            font.pixelSize: Fonts.tiny
            font.weight: Font.DemiBold
            font.letterSpacing: 2
        }
    }

    Loader {
        active: root.shown || closeDelay.running

        sourceComponent: Component {
            PanelWindow {
                id: win
                WlrLayershell.namespace: "qs-battery"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                screen: Focus.screen

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                exclusiveZone: -1
                color: "transparent"

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                FocusScope {
                    anchors.fill: parent
                    focus: true
                    Keys.onEscapePressed: root.close()
                    Component.onCompleted: forceActiveFocus()
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: root.shown ? 0.22 : 0
                    Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }
                }

                IsleDrip {
                    id: drip
                    anchors.fill: parent
                    open: root.shown
                    cardW: 440
                    cardH: body.height + 64
                    radius: 34
                    glow: root.ink

                    MouseArea { anchors.fill: parent }

                    Canvas {
                        id: halo
                        width: 520
                        height: 360
                        x: (parent.width - width) / 2
                        y: hero.y + body.y + hero.height / 2 - height / 2
                        property color tone: root.ink
                        onToneChanged: requestPaint()
                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            const g = ctx.createRadialGradient(width / 2, height / 2, 0,
                                                               width / 2, height / 2, width / 2);
                            g.addColorStop(0, Colors.alpha(halo.tone, 0.30));
                            g.addColorStop(0.5, Colors.alpha(halo.tone, 0.08));
                            g.addColorStop(1, Colors.alpha(halo.tone, 0));
                            ctx.fillStyle = g;
                            ctx.save();
                            ctx.translate(width / 2, height / 2);
                            ctx.scale(1, height / width);
                            ctx.translate(-width / 2, -height / 2);
                            ctx.fillRect(0, 0, width, width);
                            ctx.restore();
                        }

                        SequentialAnimation on opacity {
                            running: root.shown
                            loops: Animation.Infinite
                            NumberAnimation { from: 0.55; to: 1.0; duration: 3600; easing.type: Easing.InOutSine }
                            NumberAnimation { from: 1.0; to: 0.55; duration: 3600; easing.type: Easing.InOutSine }
                        }
                    }

                    Column {
                        id: body
                        anchors.top: parent.top
                        anchors.topMargin: 28
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: I18n.t("bat.title")
                            color: Colors.alpha(Colors.fgDim, 0.55)
                            font.family: Fonts.mono
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.tiny
                            font.weight: Font.DemiBold
                            font.letterSpacing: 3
                        }

                        Item { width: 1; height: 26 }

                        Item {
                            id: hero
                            width: 320
                            height: 140
                            anchors.horizontalCenter: parent.horizontalCenter

                            property real fill: 0
                            readonly property real target: Math.max(0, Math.min(1, Power.fraction))
                            Behavior on fill { NumberAnimation { duration: 1500; easing.type: Easing.OutCubic } }

                            Connections {
                                target: root
                                function onShownChanged() { if (!root.shown) hero.fill = 0; }
                            }
                            Timer {
                                interval: 140
                                running: root.shown
                                onTriggered: hero.fill = Qt.binding(() => hero.target)
                            }

                            property real phase: 0
                            NumberAnimation on phase {
                                from: 0; to: Math.PI * 2
                                duration: Power.charging ? 1800 : 5200
                                loops: Animation.Infinite
                                running: root.shown
                            }

                            readonly property real cap: 12
                            readonly property real bodyW: hero.width - hero.cap - 4

                            Rectangle {
                                id: shell
                                width: hero.bodyW
                                height: hero.height
                                radius: 40
                                color: Colors.alpha(Colors.fg, 0.04)
                                border.width: 2
                                border.color: Colors.alpha(Colors.fg, 0.20)
                                antialiasing: true
                            }

                            Rectangle {
                                x: hero.bodyW + 3
                                anchors.verticalCenter: shell.verticalCenter
                                width: hero.cap
                                height: 46
                                radius: 6
                                color: Colors.alpha(Colors.fg, 0.20)
                                antialiasing: true
                            }

                            ClippingRectangle {
                                id: well
                                x: 7
                                y: 7
                                width: shell.width - 14
                                height: shell.height - 14
                                radius: shell.radius - 7
                                color: "transparent"

                                Item {
                                    id: liquid
                                    anchors.fill: parent

                                    readonly property real amp: Power.charging ? 6 : 3
                                    readonly property real edge: width * hero.fill
                                    property color tone: root.ink
                                    Behavior on tone { ColorAnimation { duration: 600; easing.type: Easing.InOutCubic } }

                                    Water {
                                        anchors.fill: parent
                                        visible: liquid.edge > 0.5
                                        axis: 1
                                        level: liquid.edge + 4
                                        phase1: hero.phase + Math.PI * 0.7; amp1: liquid.amp; waves1: 1
                                        phase2: hero.phase * 2 + Math.PI * 0.7; amp2: liquid.amp * 0.35; waves2: 0.5
                                        nearColor: liquid.tone; nearAlpha: 0.35
                                        farColor: liquid.tone; farAlpha: 0.35
                                        crestAlpha: 0
                                    }

                                    Water {
                                        anchors.fill: parent
                                        visible: liquid.edge > 0.5
                                        axis: 1
                                        level: liquid.edge
                                        phase1: hero.phase; amp1: liquid.amp; waves1: 1
                                        phase2: hero.phase * 2; amp2: liquid.amp * 0.35; waves2: 0.5
                                        nearColor: Qt.lighter(liquid.tone, 1.35); nearAlpha: 1
                                        farColor: Qt.darker(liquid.tone, 1.45); farAlpha: 1
                                        crestColor: Qt.lighter(liquid.tone, 1.6); crestAlpha: 0.7
                                        crestWidth: 1.6
                                    }

                                    Rectangle {
                                        width: Math.max(0, liquid.edge - liquid.amp)
                                        height: parent.height * 0.45
                                        gradient: Gradient {
                                            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.22) }
                                            GradientStop { position: 1.0; color: "transparent" }
                                        }
                                    }
                                }

                                Repeater {
                                    model: Power.charging && root.shown ? 9 : 0

                                    Rectangle {
                                        id: bub
                                        required property int index
                                        readonly property real lane: ((bub.index * 0.618) % 1) * 0.85 + 0.05

                                        width: 4 + (bub.index % 3) * 2
                                        height: width
                                        radius: width / 2
                                        color: Qt.rgba(1, 1, 1, 0.45)
                                        x: well.width * hero.fill * bub.lane
                                        y: well.height
                                        visible: hero.fill > 0.1

                                        SequentialAnimation on y {
                                            loops: Animation.Infinite
                                            PauseAnimation { duration: bub.index * 340 }
                                            NumberAnimation {
                                                from: well.height + 6; to: -10
                                                duration: 2200 + (bub.index % 4) * 380
                                                easing.type: Easing.InSine
                                            }
                                        }
                                        SequentialAnimation on opacity {
                                            loops: Animation.Infinite
                                            NumberAnimation { from: 0.2; to: 1; duration: 900; easing.type: Easing.InOutSine }
                                            NumberAnimation { from: 1; to: 0.2; duration: 1300; easing.type: Easing.InOutSine }
                                        }
                                    }
                                }

                                Rectangle {
                                    id: glint
                                    width: well.width * 0.3
                                    height: well.height * 3
                                    anchors.verticalCenter: parent.verticalCenter
                                    rotation: 18
                                    visible: Power.charging
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.16) }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                    SequentialAnimation on x {
                                        running: Power.charging && root.shown
                                        loops: Animation.Infinite
                                        NumberAnimation {
                                            from: -glint.width * 2; to: well.width + glint.width
                                            duration: 2600; easing.type: Easing.InOutCubic
                                        }
                                        PauseAnimation { duration: 1800 }
                                    }
                                }
                            }

                            Text {
                                anchors.centerIn: shell
                                text: "󱐋"
                                color: "white"
                                font.family: Fonts.glyph
                                font.pixelSize: 54
                                opacity: Power.charging ? 0.92 : 0
                                scale: Power.charging ? breath : 0.6
                                property real breath: 1
                                Behavior on opacity { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                Behavior on scale { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }
                                SequentialAnimation on breath {
                                    running: Power.charging && root.shown
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 1.08; duration: 1400; easing.type: Easing.InOutSine }
                                    NumberAnimation { to: 1.0; duration: 1600; easing.type: Easing.InOutSine }
                                }
                            }

                            SequentialAnimation on opacity {
                                running: Power.low && root.shown
                                loops: Animation.Infinite
                                alwaysRunToEnd: true
                                NumberAnimation { to: 0.6; duration: 1100; easing.type: Easing.InOutSine }
                                NumberAnimation { to: 1.0; duration: 1100; easing.type: Easing.InOutSine }
                            }
                        }

                        Item { width: 1; height: 22 }

                        Row {
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 2

                            Text {
                                id: pct
                                text: Math.round(hero.fill * 100)
                                color: Colors.fg
                                font.family: Fonts.display
                                font.pixelSize: 64
                                font.weight: Font.Bold
                                font.features: { "tnum": 1 }
                            }
                            Text {
                                text: "%"
                                anchors.baseline: pct.baseline
                                color: Colors.alpha(Colors.fg, 0.45)
                                font.family: Fonts.display
                                font.features: { "tnum": 1 }
                                font.pixelSize: Fonts.bigger
                                font.weight: Font.DemiBold
                            }
                        }

                        Item { width: 1; height: 4 }

                        Swap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.headline
                            pixelSize: Fonts.large
                            weight: Font.DemiBold
                            color: Colors.fg
                        }

                        Item { width: 1; height: 6 }

                        Swap {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.subline
                            pixelSize: Fonts.text
                            weight: Font.Normal
                            color: Colors.alpha(Colors.fgDim, 0.75)
                        }

                        Item { width: 1; height: 26 }

                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 360
                            height: 1
                            color: Colors.alpha(Colors.fg, 0.07)
                        }

                        Item { width: 1; height: 18 }

                        Row {
                            id: facts
                            anchors.horizontalCenter: parent.horizontalCenter
                            spacing: 12
                            opacity: root.shown ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

                            Fact {
                                value: root.watts > 0.05 ? root.watts.toFixed(1) + I18n.t("bat.w") : "—"
                                label: Power.charging ? I18n.t("bat.in") : I18n.t("bat.draw")
                            }
                            Fact {
                                value: root.health >= 0 ? root.health + "%" : "—"
                                label: I18n.t("bat.health")
                            }
                            Fact {
                                value: root.cycles > 0 ? String(root.cycles) : "—"
                                label: I18n.t("bat.cycles")
                            }
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: closeDelay
        interval: 760
    }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (!root.shown)
            closeDelay.restart();
        else
            closeDelay.stop();
    }
}
