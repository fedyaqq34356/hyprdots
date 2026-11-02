import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import QtQuick.Shapes as Vec
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    readonly property string mono: Fonts.mono

    property string hoverMode: ""
    readonly property string viewMode: !Aula.on ? "__off" : (root.hoverMode || Aula.mode)
    property string fromMode: "__off"
    property real sweep: 1

    onViewModeChanged: {
        root.fromMode = root.lastView;
        root.lastView = root.viewMode;
        sweepAnim.restart();
    }
    property string lastView: "__off"

    NumberAnimation {
        id: sweepAnim
        target: root
        property: "sweep"
        from: 0
        to: 1
        duration: 620
        easing.type: Easing.Bezier
        easing.bezierCurve: Motion.decel
    }

    property var frame: []
    property color average: Colors.accent
    property real energy: 0

    function shadeOf(modeKey, k, i, t, X, paint) {
        if (modeKey === "__off")
            return [0, 0, 0];
        if (paint) {
            const p = paint[k.name];
            if (p)
                return p;
        }
        return Aula.shade(k, i, t, modeKey, X);
    }

    function paintFor(modeKey) {
        if (modeKey === "__off" || Aula.modeOf(modeKey).kind === "native")
            return null;
        const src = Aula.paint, out = {};
        for (const name in src) {
            const q = Qt.color(src[name]);
            out[name] = [q.r, q.g, q.b];
        }
        return out;
    }

    function recompute() {
        const keys = Aula.keys;
        const t = root.clock;
        const out = new Array(keys.length);
        let r = 0, g = 0, b = 0;
        const front = root.sweep * 1.5;
        const X = Aula.context();
        const view = root.viewMode, from = root.fromMode;
        const pv = root.paintFor(view);
        const pf = root.sweep < 1 ? root.paintFor(from) : null;
        for (let i = 0; i < keys.length; i++) {
            const k = keys[i];
            let c = root.shadeOf(view, k, i, t, X, pv);
            if (root.sweep < 1) {
                const f = Math.max(0, Math.min(1, (front - k.cx * 0.5) * 2));
                if (f < 1) {
                    const o = root.shadeOf(from, k, i, t, X, pf);
                    c = Aula.lerp(o, c, f);
                }
            }
            out[i] = Qt.rgba(c[0], c[1], c[2], 1);
            r += c[0];
            g += c[1];
            b += c[2];
        }
        root.frame = out;
        const n = Math.max(1, keys.length);
        const m = Math.max(r, g, b) / n;
        const k = root.animating && root.sweep >= 1 ? 0.12 : 1;
        root.energy += (m - root.energy) * k;
        if (m > 0.02)
            root.average = Colors.mix(root.average, Qt.rgba(r / n / m, g / n / m, b / n / m, 1), k);
    }

    function moving(key) {
        if (key === "__off" || key === "solid" || key === "gradient")
            return false;
        if (key === "static")
            return Aula.palette >= 7;
        return true;
    }

    readonly property bool animating: Aula.on && Aula.keys.length > 0
        && (root.moving(root.viewMode) || sweepAnim.running)

    property real clock: 0
    readonly property double epoch: Date.now()

    Timer {
        interval: 40
        repeat: true
        running: root.shown && root.animating
        onTriggered: {
            root.clock = (Date.now() - root.epoch) / 1000;
            root.recompute();
        }
    }

    readonly property var still: [Aula.color, Aula.color2, Aula.palette, Aula.paint,
                                  Aula.on, root.viewMode, Aula.keys, root.shown]
    onStillChanged: if (root.shown) Qt.callLater(root.recompute)

    property real light: Math.pow(Aula.brightness / 9, 1.1)
    Behavior on light { NumberAnimation { duration: Motion.base } }

    readonly property var sink: Pipewire.defaultAudioSink
    PwObjectTracker { objects: root.sink ? [root.sink] : [] }
    readonly property real volume: root.sink && root.sink.audio ? root.sink.audio.volume : 0
    readonly property bool muted: !!(root.sink && root.sink.audio && root.sink.audio.muted)

    property bool brush: false
    property string tab: Aula.kind === "native" ? "native" : "own"
    property int target: 1

    readonly property bool twoColors: Aula.mode === "gradient" || Aula.mode === "aurora" || Aula.mode === "music"
    readonly property color editing: root.target === 2 && root.twoColors ? Aula.color2 : Aula.color

    function pickColor(c) {
        if (root.target === 2 && root.twoColors)
            Aula.setColor2(c);
        else
            Aula.setColor(c);
    }

    function modeName(key) { return I18n.t("aula.m." + key); }

    function batGlyph(p) {
        const g = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"];
        return g[Math.max(0, Math.min(10, Math.round(p / 10)))];
    }

    readonly property string connGlyph: ({ wired: "󰈀", dongle: "󱔐", bt: "󰂯", none: "󰌐" })[Aula.connection] || "󰌐"
    readonly property string connLabel: I18n.t("aula.conn." + Aula.connection)

    readonly property string kindNote: {
        if (!Aula.on)
            return I18n.t("aula.offNote");
        if (Aula.kind === "native")
            return I18n.t("aula.nativeNote");
        if (Aula.kind === "live")
            return I18n.t("aula.liveNote");
        return I18n.t("aula.storedNote");
    }

    readonly property string udevCmd:
        "sudo install -Dm644 ~/Projects/pc-build/tools/70-aula-f75.rules /etc/udev/rules.d/70-aula-f75.rules"
        + " && sudo udevadm control --reload-rules && sudo udevadm trigger"

    Process { id: copier }

    property bool copied: false

    function copyUdev() {
        copier.command = ["wl-copy", root.udevCmd];
        copier.running = true;
        root.copied = true;
        copiedReset.restart();
    }

    Timer {
        id: copiedReset
        interval: 2200
        onTriggered: root.copied = false
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win
        WlrLayershell.namespace: "qs-aula"
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.38 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Emerge {
            id: emerge
            card: cardHost
            win: win
            open: root.shown
            cache: false
        }

        Item {
            id: cardHost
            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(24, (parent.height - height) / 2 - 10)
            width: card.width
            height: card.height

            opacity: emerge.on ? emerge.cardOpacity : (root.shown ? 1 : 0)
            scale: emerge.on ? 1 : (root.shown ? 1 : 0.94)
            transform: Translate { x: emerge.dx; y: emerge.on ? emerge.dy : (root.shown ? 0 : 26)
                Behavior on y {
                    enabled: !emerge.on
                    NumberAnimation {
                        duration: Motion.slow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.expo
                    }
                }
            }

            Behavior on opacity { enabled: !emerge.on; NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                enabled: !emerge.on
                SpringAnimation {
                    spring: Motion.panelSpring
                    damping: Motion.panelDamping
                    mass: Motion.panelMass
                    epsilon: 0.001
                }
            }

            Bloom {
                target: card
                tint: Aula.on && Aula.kind !== "native" ? Colors.mix(Colors.accentGlow, Aula.color, 0.6)
                                                       : Colors.accentGlow
                tintAlt: Aula.on && Aula.kind !== "native" ? Colors.mix(Colors.accentAlt, Aula.color2, 0.5)
                                                          : Colors.accentAlt
                amount: Aula.on ? 0.24 * Math.max(0.4, root.light) : 0.14
                inset: 44
            }

            Item {
                anchors.fill: parent
                z: -1

                RectangularShadow {
                    anchors.fill: parent
                    anchors.topMargin: 12
                    anchors.bottomMargin: -12
                    radius: Shape.modal
                    blur: 34
                    spread: -2
                    color: Colors.shadowTone
                    opacity: 0.55
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Shape.modal
                    color: Colors.bg
                }
            }

            Rectangle {
                id: card
                width: 900
                height: controls.y + controls.height + 30 + footer.height + 18
                radius: Shape.modal

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Colors.alpha(Colors.bgAlt, 0.96) }
                    GradientStop { position: 0.45; color: Colors.alpha(Colors.bg, 0.985) }
                    GradientStop { position: 1.0; color: Colors.alpha(Colors.bg, 0.99) }
                }

                Sheen {
                    anchors.fill: parent
                    radius: Shape.modal
                    edge: Colors.accent
                    edgeOpacity: 0.26
                }

                focus: true
                Keys.onEscapePressed: root.close()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_B) {
                        root.brush = !root.brush;
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Space) {
                        Aula.setOn(!Aula.on);
                        Sfx.flip(Aula.on);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
                        Aula.setBrightness(Aula.brightness + 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Minus) {
                        Aula.setBrightness(Aula.brightness - 1);
                        event.accepted = true;
                    }
                }

                Item {
                    id: header
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    anchors.topMargin: 20
                    anchors.leftMargin: 26
                    anchors.rightMargin: 24
                    height: 44

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        Rectangle {
                            width: 42
                            height: 42
                            radius: Shape.field
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.step(Colors.bg, Aula.on ? root.average : Colors.bgAlt, Aula.on ? 0.20 : 0.6)
                            border.width: 1
                            border.color: Colors.alpha(Aula.on ? root.average : Colors.outline, 0.45)

                            Text {
                                anchors.centerIn: parent
                                text: "󰌌"
                                color: Aula.on ? Colors.mix(Colors.fg, root.average, 0.55) : Colors.fgDim
                                font.family: Fonts.glyph
                                font.pixelSize: 22
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: "AULA F75"
                                color: Colors.fg
                                font.family: Fonts.display
                                font.pixelSize: Fonts.large
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: Aula.busy || Aula.pending ? I18n.t("aula.writing") : root.kindNote
                                color: Aula.busy || Aula.pending ? Colors.accent : Colors.fgDim
                                opacity: 0.7
                                font.family: root.mono
                                font.pixelSize: Fonts.small
                                Behavior on color { ColorAnimation { duration: Motion.base } }
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            height: 32
                            width: connRow.implicitWidth + 24
                            radius: height / 2
                            color: Aula.ready ? Colors.accentWash : Colors.alpha(Colors.bgAlt, 0.6)
                            border.width: 1
                            border.color: Aula.ready ? Colors.alpha(Colors.accent, 0.38)
                                                     : Colors.alpha(Colors.outline, 0.18)
                            Behavior on color { ColorAnimation { duration: Motion.base } }
                            Behavior on width { Spring {} }

                            Row {
                                id: connRow
                                anchors.centerIn: parent
                                spacing: 8

                                Rectangle {
                                    width: 7
                                    height: 7
                                    radius: 4
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: Aula.ready ? Colors.good
                                         : Aula.found ? Colors.warn : Colors.alpha(Colors.fgDim, 0.5)

                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.connGlyph
                                    color: Aula.ready ? Colors.accent : Colors.fgDim
                                    font.family: Fonts.glyph
                                    font.pixelSize: Fonts.medium
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.connLabel
                                    color: Aula.ready ? Colors.fg : Colors.fgDim
                                    font.family: root.mono
                                    font.pixelSize: Fonts.small
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: Aula.charging || Aula.battery >= 0
                                    text: "·"
                                    color: Colors.fgDim
                                    opacity: 0.5
                                    font.family: root.mono
                                    font.pixelSize: Fonts.small
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: Aula.charging || Aula.battery >= 0
                                    text: Aula.charging ? "󰂄" : root.batGlyph(Aula.battery)
                                    color: Aula.charging ? Colors.good
                                         : Aula.battery <= 10 ? Colors.bad
                                         : Aula.battery <= 20 ? Colors.warn : Colors.fgDim
                                    opacity: Aula.batteryStale ? 0.5 : 1
                                    font.family: Fonts.glyph
                                    font.pixelSize: Fonts.medium
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: Aula.charging || Aula.battery >= 0
                                    text: Aula.charging && Aula.liveBattery < 0 ? I18n.t("aula.charging")
                                        : Aula.battery + "%"
                                          + (Aula.hoursLeft >= 0 ? "  " + Aula.leftText(Aula.hoursLeft) : "")
                                    color: !Aula.charging && Aula.battery <= 10 ? Colors.bad
                                         : !Aula.charging && Aula.battery <= 20 ? Colors.warn : Colors.fg
                                    opacity: Aula.batteryStale ? 0.5 : 0.9
                                    font.family: root.mono
                                    font.pixelSize: Fonts.small
                                    font.features: Fonts.nums
                                }
                            }
                        }

                        Switch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: Aula.on
                            tint: Colors.accent
                            onToggled: v => Aula.setOn(v)
                        }
                    }
                }

                Item {
                    id: stage
                    anchors { top: header.bottom; left: parent.left; right: parent.right }
                    anchors.topMargin: 14
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    height: 330

                    readonly property real s: Math.min((width - 64) / 604, (height - 56) / 234)
                    readonly property real ox: (width - 604 * s) / 2 - 30 * s
                    readonly property real oy: (height - 234 * s) / 2 - 27 * s

                    RectangularShadow {
                        anchors.fill: plate
                        anchors.margins: 30
                        radius: Shape.card
                        blur: 60
                        spread: 6
                        color: root.average
                        opacity: Aula.on ? (0.10 + 0.32 * root.energy) * root.light * (Aula.ready ? 1 : 0.5) : 0
                    }

                    Rectangle {
                        id: plate
                        anchors.fill: parent
                        radius: Shape.card
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Colors.surface2 }
                            GradientStop { position: 1.0; color: Colors.surface1 }
                        }
                        border.width: 1
                        border.color: Colors.alpha(Colors.outline, 0.16)

                        Sheen {
                            anchors.fill: parent
                            radius: Shape.card
                            edge: Colors.outline
                            edgeOpacity: 0.12
                            strength: 0.8
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: 14
                            radius: Shape.field
                            color: Colors.step(Colors.bg, Colors.shadowTone, 0.5)
                            opacity: 0.85
                        }
                    }

                    Item {
                        id: glow
                        anchors.fill: parent
                        opacity: root.light * (Aula.ready ? 1 : 0.8)

                        Repeater {
                            model: Aula.keys
                            RectangularShadow {
                                required property var modelData
                                required property int index
                                readonly property color lit: root.frame[index] || "black"
                                x: stage.ox + modelData.x * stage.s - 1
                                y: stage.oy + modelData.y * stage.s + 1
                                width: modelData.w * stage.s + 2
                                height: modelData.h * stage.s + 2
                                radius: 6
                                blur: 13
                                spread: 1
                                color: lit
                                opacity: 0.25 + 0.75 * Math.max(lit.r, lit.g, lit.b)
                            }
                        }
                    }

                    Repeater {
                        model: Aula.keys

                        Item {
                            id: cap
                            required property var modelData
                            required property int index

                            readonly property bool painted: !!Aula.paint[modelData.name]

                            x: stage.ox + modelData.x * stage.s
                            y: stage.oy + modelData.y * stage.s
                            width: modelData.w * stage.s
                            height: modelData.h * stage.s

                            scale: tap.pressed ? 0.92 : (hover.hovered && root.brush ? 1.07 : 1)
                            Behavior on scale { Spring {} }

                            Rectangle {
                                anchors.fill: parent
                                anchors.bottomMargin: 2
                                radius: 6
                                border.width: 1
                                border.color: root.capEdge
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: root.capTop }
                                    GradientStop { position: 0.5; color: root.capMid }
                                    GradientStop { position: 1.0; color: root.capLow }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    anchors.verticalCenterOffset: -1
                                    text: cap.modelData.label
                                    color: root.capLegend
                                    font.family: root.mono
                                    font.pixelSize: cap.modelData.label.length > 3 ? 9 : 10
                                    font.weight: Font.DemiBold
                                }

                                Rectangle {
                                    visible: cap.painted && Aula.canPaint
                                    width: 4
                                    height: 4
                                    radius: 2
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.margins: 4
                                    color: Colors.fg
                                    opacity: 0.7
                                }
                            }

                            HoverHandler {
                                id: hover
                                cursorShape: root.brush ? Qt.CrossCursor : Qt.ArrowCursor
                            }

                            TapHandler {
                                id: tap
                                enabled: root.brush && Aula.canPaint
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onTapped: (pt, button) => {
                                    Sfx.tick();
                                    Aula.paintKey(cap.modelData.name,
                                                  button === Qt.RightButton ? null : root.editing);
                                }
                            }
                        }
                    }

                    Item {
                        id: knob
                        readonly property real d: Aula.knob[2] * stage.s
                        x: stage.ox + Aula.knob[0] * stage.s
                        y: stage.oy + Aula.knob[1] * stage.s
                        width: d
                        height: d

                        RectangularShadow {
                            anchors.fill: parent
                            anchors.topMargin: 3
                            anchors.bottomMargin: -3
                            radius: width / 2
                            blur: 8
                            color: Colors.shadow(0.7)
                        }

                        Vec.Shape {
                            anchors.fill: parent
                            anchors.margins: -5
                            preferredRendererType: Vec.Shape.CurveRenderer
                            Vec.ShapePath {
                                fillColor: "transparent"
                                strokeColor: Colors.alpha(Colors.outline, 0.22)
                                strokeWidth: 2
                                capStyle: Vec.ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: knob.d / 2 + 5; centerY: knob.d / 2 + 5
                                    radiusX: knob.d / 2 + 3; radiusY: knob.d / 2 + 3
                                    startAngle: 135; sweepAngle: 270
                                }
                            }
                            Vec.ShapePath {
                                fillColor: "transparent"
                                strokeColor: root.muted ? Colors.bad : Colors.accent
                                strokeWidth: 2
                                capStyle: Vec.ShapePath.RoundCap
                                PathAngleArc {
                                    centerX: knob.d / 2 + 5; centerY: knob.d / 2 + 5
                                    radiusX: knob.d / 2 + 3; radiusY: knob.d / 2 + 3
                                    startAngle: 135
                                    sweepAngle: 270 * Math.min(1, knobTurn.shown)
                                }
                            }
                        }

                        Rectangle {
                            id: knobBody
                            anchors.fill: parent
                            radius: width / 2
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Colors.step(Colors.surface3, Colors.fg, 0.22) }
                                GradientStop { position: 1.0; color: Colors.surface2 }
                            }
                            border.width: 1
                            border.color: Colors.alpha(Colors.outline, 0.35)

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width * 0.62
                                height: width
                                radius: width / 2
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Colors.surface2 }
                                    GradientStop { position: 1.0; color: Colors.step(Colors.surface3, Colors.fg, 0.14) }
                                }
                            }

                            Item {
                                id: knobTurn
                                anchors.fill: parent
                                property real shown: root.volume
                                Behavior on shown {
                                    SpringAnimation {
                                        spring: Motion.tapSpring
                                        damping: Motion.tapDamping
                                        mass: Motion.tapMass
                                        epsilon: 0.001
                                    }
                                }
                                rotation: -135 + 270 * Math.min(1, knobTurn.shown)

                                Rectangle {
                                    width: 2.5
                                    height: parent.height * 0.26
                                    radius: 1.25
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    y: 3
                                    color: root.muted ? Colors.bad : Colors.fg
                                    opacity: 0.85
                                }
                            }
                        }

                        HoverHandler { id: knobHover }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: parent.bottom
                            anchors.topMargin: 6
                            text: root.muted ? I18n.t("aula.knobMuted")
                                             : Math.round(root.volume * 100) + "%"
                            color: root.muted ? Colors.bad : Colors.fgDim
                            opacity: knobHover.hovered ? 0.9 : 0
                            font.family: root.mono
                            font.pixelSize: Fonts.tiny
                            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                        }
                    }

                    Rectangle {
                        id: notice
                        readonly property string why: !Aula.found ? "none"
                            : Aula.connection === "bt" && !Aula.controllable ? "bt"
                            : Aula.error === "permission" ? "perm"
                            : Aula.error !== "" ? "error" : ""
                        visible: opacity > 0.01
                        opacity: why !== "" ? 1 : 0
                        scale: why !== "" ? 1 : 0.94
                        Behavior on opacity { NumberAnimation { duration: Motion.base } }
                        Behavior on scale { Spring {} }

                        anchors.centerIn: parent
                        width: noticeRow.implicitWidth + 36
                        height: 64
                        radius: height / 2
                        color: Colors.alpha(Colors.bg, 0.86)
                        border.width: 1
                        border.color: Colors.alpha(notice.why === "error" || notice.why === "perm"
                                                   ? Colors.warn : Colors.outline, 0.3)

                        RectangularShadow {
                            z: -1
                            anchors.fill: parent
                            anchors.topMargin: 6
                            anchors.bottomMargin: -6
                            radius: parent.radius
                            blur: 24
                            color: Colors.shadow(0.55)
                        }

                        Row {
                            id: noticeRow
                            anchors.centerIn: parent
                            spacing: 14

                            Rectangle {
                                width: 40
                                height: 40
                                radius: 20
                                anchors.verticalCenter: parent.verticalCenter
                                color: notice.why === "perm" || notice.why === "error"
                                       ? Colors.alpha(Colors.warn, 0.16) : Colors.accentWash
                                Text {
                                    anchors.centerIn: parent
                                    text: notice.why === "bt" ? "󰂲" : notice.why === "perm" ? "󰌾"
                                        : notice.why === "error" ? "󰀦" : "󰈀"
                                    color: notice.why === "perm" || notice.why === "error" ? Colors.warn : Colors.accent
                                    font.family: Fonts.glyph
                                    font.pixelSize: 19
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 3

                                Text {
                                    text: I18n.t("aula.notice." + (notice.why || "none"))
                                    color: Colors.fg
                                    font.family: Fonts.display
                                    font.pixelSize: Fonts.medium
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: notice.why === "error" && Aula.errorText !== "" ? Aula.errorText
                                        : I18n.t("aula.notice." + (notice.why || "none") + "Sub")
                                    color: Colors.fgDim
                                    opacity: 0.75
                                    font.family: root.mono
                                    font.pixelSize: Fonts.small
                                }
                            }

                            Rectangle {
                                visible: notice.why === "perm"
                                anchors.verticalCenter: parent.verticalCenter
                                width: copyRow.implicitWidth + 24
                                height: 32
                                radius: 16
                                color: copyArea.containsMouse ? Colors.accentSoft : Colors.accentWash
                                border.width: 1
                                border.color: Colors.alpha(Colors.accent, 0.4)
                                scale: copyArea.pressed ? 0.95 : 1
                                Behavior on scale { Spring {} }
                                Behavior on color { ColorAnimation { duration: Motion.fast } }

                                Row {
                                    id: copyRow
                                    anchors.centerIn: parent
                                    spacing: 7
                                    Text {
                                        text: root.copied ? "󰄬" : "󰆏"
                                        color: Colors.accent
                                        font.family: Fonts.glyph
                                        font.pixelSize: Fonts.text
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                    Text {
                                        text: root.copied ? I18n.t("aula.copied") : I18n.t("aula.copyCmd")
                                        color: Colors.fg
                                        font.family: root.mono
                                        font.pixelSize: Fonts.small
                                        anchors.verticalCenter: parent.verticalCenter
                                    }
                                }

                                MouseArea {
                                    id: copyArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: { Sfx.tap(); root.copyUdev(); }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: caption
                    anchors { top: stage.bottom; left: parent.left; right: parent.right }
                    anchors.topMargin: 10
                    anchors.leftMargin: 30
                    anchors.rightMargin: 28
                    height: 32

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Aula.modeOf(root.hoverMode || Aula.mode).glyph
                            color: Colors.accent
                            font.family: Fonts.glyph
                            font.pixelSize: Fonts.larger
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.modeName(root.hoverMode || Aula.mode)
                            color: Colors.fg
                            font.family: Fonts.display
                            font.pixelSize: Fonts.large
                            font.weight: Font.DemiBold
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.hoverMode !== "" && root.hoverMode !== Aula.mode
                                  ? I18n.t("aula.tryOn")
                                  : I18n.t("aula.d." + Aula.mode)
                            color: Colors.fgDim
                            opacity: 0.6
                            font.family: root.mono
                            font.pixelSize: Fonts.small
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8
                        opacity: Aula.canPaint ? 1 : 0.35
                        Behavior on opacity { NumberAnimation { duration: Motion.base } }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: root.brush && Aula.canPaint
                            text: I18n.t("aula.brushHint")
                            color: Colors.fgDim
                            opacity: 0.55
                            font.family: root.mono
                            font.pixelSize: Fonts.tiny
                        }

                        Pill {
                            glyph: "󰆴"
                            label: I18n.t("aula.clear")
                            visible: Object.keys(Aula.paint).length > 0 && Aula.canPaint
                            onClicked: { Sfx.toggleOff(); Aula.clearPaint(); }
                        }

                        Pill {
                            glyph: "󰏫"
                            label: I18n.t("aula.brush")
                            active: root.brush && Aula.canPaint
                            swatch: root.brush ? root.editing : "transparent"
                            enabled: Aula.canPaint
                            onClicked: { Sfx.flip(!root.brush); root.brush = !root.brush; }
                        }
                    }
                }

                Item {
                    id: modes
                    anchors { top: caption.bottom; left: parent.left; right: parent.right }
                    anchors.topMargin: 14
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    height: tabs.height + 10 + tiles.implicitHeight
                    Behavior on height {
                        NumberAnimation { duration: Motion.slow; easing.type: Easing.Bezier; easing.bezierCurve: Motion.decel }
                    }

                    readonly property int count: Aula.modes.filter(m => root.tab === "native"
                                                                     ? m.kind === "native" : m.kind !== "native").length
                    readonly property int cols: Math.min(8, count)
                    readonly property real tileW: Math.floor((width - (cols - 1) * 8) / cols)
                    readonly property real tileH: 62

                    Segment {
                        id: tabs
                        anchors.left: parent.left
                        anchors.top: parent.top
                        options: [
                            { value: "own",    label: I18n.t("aula.tab.own") },
                            { value: "native", label: I18n.t("aula.tab.native") }
                        ]
                        current: root.tab
                        onPicked: v => { Sfx.pick(); root.tab = v; }
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: tabs.verticalCenter
                        text: I18n.t("aula.tabNote." + root.tab)
                        color: Colors.fgDim
                        opacity: 0.5
                        font.family: root.mono
                        font.pixelSize: Fonts.tiny
                    }

                    Flow {
                        id: tiles
                        anchors.top: tabs.bottom
                        anchors.topMargin: 10
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 8

                        Repeater {
                            model: Aula.modes.filter(m => root.tab === "native" ? m.kind === "native"
                                                                                : m.kind !== "native")

                            Rectangle {
                                id: tile
                                required property var modelData
                                required property int index
                                readonly property bool active: Aula.on && Aula.mode === modelData.key

                                width: modes.tileW
                                height: modes.tileH
                                radius: Shape.field
                                color: tile.active ? Colors.accentSoft
                                     : tileHover.hovered ? Colors.surface2 : Colors.alpha(Colors.surface1, 0.7)
                                border.width: 1
                                border.color: tile.active ? Colors.alpha(Colors.accent, 0.55)
                                                          : Colors.alpha(Colors.outline, tileHover.hovered ? 0.24 : 0.12)
                                Behavior on color { ColorAnimation { duration: Motion.fast } }
                                Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                                opacity: 0
                                transform: Translate { id: tileShift; y: 8 }
                                Component.onCompleted: tileIn.start()
                                SequentialAnimation {
                                    id: tileIn
                                    PauseAnimation { duration: Motion.delay(tile.index) }
                                    ParallelAnimation {
                                        NumberAnimation { target: tile; property: "opacity"; to: 1; duration: Motion.base }
                                        NumberAnimation {
                                            target: tileShift; property: "y"; to: 0; duration: Motion.slow
                                            easing.type: Easing.Bezier; easing.bezierCurve: Motion.expo
                                        }
                                    }
                                }

                                scale: tileTap.pressed ? 0.94 : (tileHover.hovered ? 1.03 : 1)
                                Behavior on scale { Spring {} }

                                Column {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.verticalCenterOffset: -3
                                    spacing: 3

                                    Text {
                                        text: tile.modelData.glyph
                                        color: tile.active ? Colors.accent : Colors.fgDim
                                        opacity: tile.active ? 1 : 0.8
                                        font.family: Fonts.glyph
                                        font.pixelSize: 17
                                    }

                                    Text {
                                        width: modes.tileW - 18
                                        elide: Text.ElideRight
                                        text: root.modeName(tile.modelData.key)
                                        color: tile.active ? Colors.fg : Colors.fgDim
                                        font.family: root.mono
                                        font.pixelSize: Fonts.small
                                        font.weight: tile.active ? Font.DemiBold : Font.Normal
                                    }
                                }

                                Text {
                                    visible: tile.modelData.kind === "live"
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 8
                                    text: I18n.t("aula.liveTag")
                                    color: Colors.accent
                                    opacity: 0.55
                                    font.family: root.mono
                                    font.pixelSize: 8
                                    font.capitalization: Font.AllUppercase
                                    font.letterSpacing: 0.8
                                }

                                Row {
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 7
                                    anchors.right: parent.right
                                    anchors.rightMargin: 9
                                    spacing: 2
                                    visible: root.shown

                                    Repeater {
                                        model: 8
                                        Rectangle {
                                            required property int index
                                            readonly property var probe: ({ cx: index / 7, cy: 0.5, name: "", led: 0 })
                                            readonly property var c: {
                                                const _t = tile.active || tileHover.hovered ? root.clock : 0.6;
                                                const _a = Aula.color, _b = Aula.color2, _p = Aula.palette, _s = Aula.speed;
                                                return Aula.shade(probe, index * 9 + 3, _t, tile.modelData.key);
                                            }
                                            width: 4
                                            height: 4
                                            radius: 2
                                            color: Qt.rgba(c[0], c[1], c[2], 1)
                                            opacity: 0.25 + 0.75 * Math.max(c[0], c[1], c[2])
                                        }
                                    }
                                }

                                HoverHandler {
                                    id: tileHover
                                    cursorShape: Qt.PointingHandCursor
                                    onHoveredChanged: {
                                        if (hovered)
                                            root.hoverMode = tile.modelData.key;
                                        else if (root.hoverMode === tile.modelData.key)
                                            root.hoverMode = "";
                                    }
                                }

                                TapHandler {
                                    id: tileTap
                                    onTapped: {
                                        Sfx.pick();
                                        root.hoverMode = "";
                                        Aula.setMode(tile.modelData.key);
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: controls
                    anchors { top: modes.bottom; left: parent.left; right: parent.right }
                    anchors.topMargin: 10
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    height: 188

                    Item {
                        id: wheelBox
                        width: 188
                        height: 188

                        ColorWheel {
                            id: wheel
                            anchors.fill: parent
                            value: root.editing
                            opacity: Aula.canColor ? 1 : 0
                            scale: Aula.canColor ? 1 : 0.86
                            visible: opacity > 0.01
                            enabled: Aula.canColor
                            Behavior on opacity { NumberAnimation { duration: Motion.base } }
                            Behavior on scale { Spring {} }
                            onPicked: c => root.pickColor(c)
                        }

                        Item {
                            anchors.fill: parent
                            opacity: Aula.canPalette ? 1 : (Aula.kind === "native" ? 0.35 : 0)
                            scale: Aula.kind === "native" ? 1 : 0.86
                            visible: opacity > 0.01
                            Behavior on opacity { NumberAnimation { duration: Motion.base } }
                            Behavior on scale { Spring {} }

                            Repeater {
                                model: 8
                                Rectangle {
                                    id: chip
                                    required property int index
                                    readonly property bool center: index === 7
                                    readonly property real a: index / 7 * 2 * Math.PI - Math.PI / 2
                                    readonly property bool chosen: Aula.palette === index
                                    width: center ? 50 : 36
                                    height: width
                                    radius: width / 2
                                    x: (center ? 94 : 94 + Math.cos(a) * 66) - width / 2
                                    y: (center ? 94 : 94 + Math.sin(a) * 66) - height / 2
                                    color: center ? "transparent" : Aula.hwPalette[index]
                                    border.width: chosen ? 3 : 1
                                    border.color: chosen ? Colors.fg : Colors.alpha(Colors.outline, 0.4)
                                    scale: chipArea.pressed ? 0.9 : (chipArea.containsMouse || chosen ? 1.1 : 1)
                                    Behavior on scale { Spring {} }

                                    Vec.Shape {
                                        visible: chip.center
                                        anchors.fill: parent
                                        preferredRendererType: Vec.Shape.CurveRenderer
                                        Vec.ShapePath {
                                            strokeColor: "transparent"
                                            fillGradient: Vec.ConicalGradient {
                                                centerX: 25; centerY: 25; angle: 90
                                                GradientStop { position: 0.0;   color: Qt.hsva(0, 1, 1, 1) }
                                                GradientStop { position: 0.166; color: Qt.hsva(0.166, 1, 1, 1) }
                                                GradientStop { position: 0.333; color: Qt.hsva(0.333, 1, 1, 1) }
                                                GradientStop { position: 0.5;   color: Qt.hsva(0.5, 1, 1, 1) }
                                                GradientStop { position: 0.666; color: Qt.hsva(0.666, 1, 1, 1) }
                                                GradientStop { position: 0.833; color: Qt.hsva(0.833, 1, 1, 1) }
                                                GradientStop { position: 1.0;   color: Qt.hsva(1, 1, 1, 1) }
                                            }
                                            PathAngleArc { centerX: 25; centerY: 25; radiusX: 25; radiusY: 25; startAngle: 0; sweepAngle: 360 }
                                        }
                                    }

                                    Text {
                                        visible: chip.center
                                        anchors.centerIn: parent
                                        text: "󰒝"
                                        color: "#ffffff"
                                        font.family: Fonts.glyph
                                        font.pixelSize: 18
                                        style: Text.Outline
                                        styleColor: Colors.shadow(0.5)
                                    }

                                    MouseArea {
                                        id: chipArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        enabled: Aula.canPalette
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { Sfx.pick(); Aula.setPalette(chip.index); }
                                    }
                                }
                            }
                        }
                    }

                    Column {
                        anchors.left: wheelBox.right
                        anchors.leftMargin: 30
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16

                        Row {
                            spacing: 10
                            height: 36
                            opacity: Aula.canColor ? 1 : 0.35
                            enabled: Aula.canColor
                            Behavior on opacity { NumberAnimation { duration: Motion.base } }

                            Repeater {
                                model: root.twoColors ? [1, 2] : [1]
                                Rectangle {
                                    id: sw
                                    required property int modelData
                                    readonly property bool sel: root.target === modelData || !root.twoColors
                                    width: 36
                                    height: 36
                                    radius: Shape.chip
                                    color: modelData === 2 ? Aula.color2 : Aula.color
                                    border.width: sel ? 2 : 1
                                    border.color: sel ? Colors.fg : Colors.alpha(Colors.outline, 0.35)
                                    scale: swArea.pressed ? 0.92 : 1
                                    Behavior on scale { Spring {} }
                                    Behavior on color { ColorAnimation { duration: Motion.base } }

                                    Text {
                                        visible: root.twoColors
                                        anchors.centerIn: parent
                                        text: String(sw.modelData)
                                        color: Colors.fg
                                        style: Text.Outline
                                        styleColor: Colors.shadow(0.6)
                                        font.family: root.mono
                                        font.pixelSize: Fonts.small
                                        font.weight: Font.DemiBold
                                    }

                                    MouseArea {
                                        id: swArea
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { Sfx.pick(); root.target = sw.modelData; }
                                    }
                                }
                            }

                            Field {
                                id: hex
                                width: 128
                                height: 36
                                text: String(root.editing).toUpperCase()
                                onAccepted: t => {
                                    const s = t.trim().replace(/^#?/, "#");
                                    if (/^#[0-9a-fA-F]{6}$/.test(s)) {
                                        Sfx.tap();
                                        root.pickColor(s.toLowerCase());
                                    }
                                }
                            }

                            Rectangle { width: 1; height: 24; color: Colors.alpha(Colors.outline, 0.2); anchors.verticalCenter: parent.verticalCenter }

                            Repeater {
                                model: [Colors.srcAccent, Colors.srcAccentAlt, Colors.accentGlow,
                                        Colors.selection, Colors.good, Colors.warn, Colors.bad, Colors.srcFg]
                                Rectangle {
                                    id: themeChip
                                    required property color modelData
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: modelData
                                    border.width: 1
                                    border.color: Colors.alpha(Colors.fg, 0.18)
                                    scale: tcArea.pressed ? 0.88 : (tcArea.containsMouse ? 1.18 : 1)
                                    Behavior on scale { Spring {} }
                                    Behavior on color { ColorAnimation { duration: Motion.base } }

                                    MouseArea {
                                        id: tcArea
                                        anchors.fill: parent
                                        anchors.margins: -3
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: { Sfx.pick(); root.pickColor(String(themeChip.modelData)); }
                                    }
                                }
                            }

                            Pill {
                                anchors.verticalCenter: parent.verticalCenter
                                glyph: "󰸉"
                                label: I18n.t("aula.fromWall")
                                onClicked: { Sfx.tap(); Aula.useTheme(); }
                            }
                        }

                        Text {
                            visible: Aula.kind === "native"
                            text: I18n.t("aula.paletteHint")
                            color: Colors.fgDim
                            opacity: 0.55
                            font.family: root.mono
                            font.pixelSize: Fonts.tiny
                        }

                        SliderRow {
                            width: parent.width
                            glyph: "󰃠"
                            label: I18n.t("aula.brightness")
                            value: Aula.brightness
                            steps: 9
                            onMoved: v => Aula.setBrightness(v)
                        }

                        SliderRow {
                            width: parent.width
                            glyph: "󰓅"
                            label: I18n.t("aula.speed")
                            value: Aula.speed
                            steps: 4
                            enabled: Aula.canSpeed
                            onMoved: v => Aula.setSpeed(v)
                        }
                    }
                }

                Item {
                    id: footer
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    anchors.bottomMargin: 18
                    anchors.leftMargin: 24
                    anchors.rightMargin: 24
                    height: 36

                    Rectangle {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: -12
                        height: 1
                        color: Colors.alpha(Colors.outline, 0.12)
                    }

                    Row {
                        id: presetRow
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.t("aula.presets")
                            color: Colors.fgDim
                            opacity: 0.5
                            font.family: root.mono
                            font.pixelSize: Fonts.tiny
                            font.capitalization: Font.AllUppercase
                            font.letterSpacing: 1
                        }

                        Repeater {
                            model: Aula.presets
                            Pill {
                                required property var modelData
                                required property int index
                                label: modelData.name
                                swatch: modelData.color
                                tip: I18n.t("aula.presetHint")
                                onClicked: { Sfx.pick(); Aula.loadPreset(index); }
                                onErased: { Sfx.toggleOff(); Aula.deletePreset(index); }
                            }
                        }

                        Field {
                            id: presetName
                            visible: root.naming
                            width: 150
                            height: 30
                            placeholder: I18n.t("aula.presetName")
                            onAccepted: t => {
                                if (t.trim() !== "") {
                                    Sfx.fill();
                                    Aula.savePreset(t.trim());
                                }
                                presetName.clear();
                                root.naming = false;
                                card.forceActiveFocus();
                            }
                        }

                        Pill {
                            glyph: root.naming ? "󰅖" : "󰐕"
                            label: root.naming ? "" : I18n.t("aula.save")
                            onClicked: {
                                Sfx.tap();
                                root.naming = !root.naming;
                                if (root.naming)
                                    presetName.grab();
                                else
                                    card.forceActiveFocus();
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰸉"
                            color: Aula.wallSync ? Colors.accent : Colors.fgDim
                            font.family: Fonts.glyph
                            font.pixelSize: Fonts.medium
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: I18n.t("aula.wallSync")
                            color: Colors.fgDim
                            font.family: root.mono
                            font.pixelSize: Fonts.small
                        }

                        Switch {
                            anchors.verticalCenter: parent.verticalCenter
                            checked: Aula.wallSync
                            onToggled: v => Aula.setWallSync(v)
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            leftPadding: 10
                            text: "b · space · +/− · esc"
                            color: Colors.fgDim
                            opacity: 0.3
                            font.family: root.mono
                            font.pixelSize: Fonts.tiny
                        }
                    }
                }
            }
        }
    }

    property bool naming: false

    readonly property bool lit: Aula.on && root.light > 0.05
    readonly property color capEdge: Colors.alpha(Colors.lightTone, root.lit ? 0.22 : 0.14)
    readonly property color capTop: Colors.alpha(Colors.step(Colors.surface3, Colors.lightTone, 0.10), 0.80)
    readonly property color capMid: Colors.alpha(Colors.surface3, 0.52)
    readonly property color capLow: Colors.alpha(Colors.surface3, 0.28)
    readonly property color capLegend: root.lit ? Colors.alpha(Colors.lightTone, 0.88) : Colors.alpha(Colors.fgDim, 0.5)

    Connections {
        target: Aula
        function onKindChanged() { root.tab = Aula.kind === "native" ? "native" : "own"; }
    }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (root.shown) {
            Aula.refresh();
            root.hoverMode = "";
            root.brush = false;
            root.naming = false;
            root.tab = Aula.kind === "native" ? "native" : "own";
            root.fromMode = "__off";
            root.lastView = root.viewMode;
            root.sweep = 0;
            sweepAnim.restart();
            root.recompute();
        }
    }

    component Pill: Rectangle {
        id: pill
        property string glyph: ""
        property string label: ""
        property color swatch: "transparent"
        property bool active: false
        property string tip: ""
        signal clicked()
        signal erased()

        height: 30
        width: pillRow.implicitWidth + 22
        radius: 15
        color: pill.active ? Colors.accentSoft
             : pillArea.containsMouse ? Colors.surface2 : Colors.alpha(Colors.surface1, 0.8)
        border.width: 1
        border.color: pill.active ? Colors.alpha(Colors.accent, 0.5) : Colors.alpha(Colors.outline, 0.16)
        opacity: pill.enabled ? 1 : 0.4
        scale: pillArea.pressed ? 0.94 : 1
        Behavior on scale { Spring {} }
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        Row {
            id: pillRow
            anchors.centerIn: parent
            spacing: 6

            Rectangle {
                visible: pill.swatch.a > 0
                width: 12
                height: 12
                radius: 6
                anchors.verticalCenter: parent.verticalCenter
                color: pill.swatch
                border.width: 1
                border.color: Colors.alpha(Colors.fg, 0.25)
            }

            Text {
                visible: pill.glyph !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pill.glyph
                color: pill.active ? Colors.accent : Colors.fgDim
                font.family: Fonts.glyph
                font.pixelSize: Fonts.text
            }

            Text {
                visible: pill.label !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: pill.label
                color: pill.active ? Colors.fg : Colors.fgDim
                font.family: Fonts.mono
                font.pixelSize: Fonts.small
            }
        }

        MouseArea {
            id: pillArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: pill.enabled
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => mouse.button === Qt.RightButton ? pill.erased() : pill.clicked()
        }
    }

    component SliderRow: Item {
        id: row
        property string glyph: ""
        property string label: ""
        property int value: 0
        property int steps: 9
        signal moved(int v)

        height: 26
        opacity: row.enabled ? 1 : 0.35
        Behavior on opacity { NumberAnimation { duration: Motion.base } }

        Text {
            id: rowGlyph
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: row.glyph
            color: Colors.accent
            font.family: Fonts.glyph
            font.pixelSize: Fonts.medium
        }

        Text {
            id: rowLabel
            anchors.left: rowGlyph.right
            anchors.leftMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            width: 92
            text: row.label
            color: Colors.fgDim
            font.family: Fonts.mono
            font.pixelSize: Fonts.small
        }

        Slider {
            anchors.left: rowLabel.right
            anchors.right: rowValue.left
            anchors.rightMargin: 14
            anchors.verticalCenter: parent.verticalCenter
            value: row.value / row.steps
            step: 1 / row.steps
            enabled: row.enabled
            onMoved: v => row.moved(Math.round(v * row.steps))
        }

        Text {
            id: rowValue
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            width: 32
            horizontalAlignment: Text.AlignRight
            text: row.value + "/" + row.steps
            color: Colors.fg
            opacity: 0.8
            font.family: Fonts.mono
            font.pixelSize: Fonts.small
            font.features: Fonts.nums
        }
    }

    component ColorWheel: Item {
        id: cw
        property color value: "#ffffff"
        signal picked(color c)

        property real h: 0
        property real s: 1
        property real v: 1
        property bool dragging: false

        onValueChanged: {
            if (cw.dragging)
                return;
            const c = cw.value;
            if (c.hsvSaturation > 0.01 && c.hsvValue > 0.01)
                cw.h = Math.max(0, c.hsvHue);
            cw.s = c.hsvSaturation;
            cw.v = c.hsvValue;
        }

        function emit() {
            cw.picked(Qt.hsva(cw.h, cw.s, cw.v, 1));
        }

        readonly property real ring: 18
        readonly property real r: Math.min(width, height) / 2
        readonly property real box: (cw.r - cw.ring - 8) * Math.SQRT2

        RectangularShadow {
            anchors.centerIn: parent
            width: cw.r * 1.5
            height: width
            radius: width / 2
            blur: 40
            color: cw.value
            opacity: 0.35
            Behavior on color { ColorAnimation { duration: Motion.base } }
        }

        Vec.Shape {
            anchors.fill: parent
            preferredRendererType: Vec.Shape.CurveRenderer
            Vec.ShapePath {
                strokeColor: "transparent"
                fillRule: Vec.ShapePath.OddEvenFill
                fillGradient: Vec.ConicalGradient {
                    centerX: cw.r; centerY: cw.r; angle: 90
                    GradientStop { position: 0.0;   color: Qt.hsva(0, 1, 1, 1) }
                    GradientStop { position: 0.166; color: Qt.hsva(0.166, 1, 1, 1) }
                    GradientStop { position: 0.333; color: Qt.hsva(0.333, 1, 1, 1) }
                    GradientStop { position: 0.5;   color: Qt.hsva(0.5, 1, 1, 1) }
                    GradientStop { position: 0.666; color: Qt.hsva(0.666, 1, 1, 1) }
                    GradientStop { position: 0.833; color: Qt.hsva(0.833, 1, 1, 1) }
                    GradientStop { position: 1.0;   color: Qt.hsva(1, 1, 1, 1) }
                }
                PathAngleArc { centerX: cw.r; centerY: cw.r; radiusX: cw.r; radiusY: cw.r; startAngle: 0; sweepAngle: 360 }
                PathAngleArc { centerX: cw.r; centerY: cw.r; radiusX: cw.r - cw.ring; radiusY: cw.r - cw.ring; startAngle: 0; sweepAngle: 360 }
            }
        }

        Rectangle {
            id: sv
            anchors.centerIn: parent
            width: cw.box
            height: cw.box
            radius: Shape.chip
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "#ffffff" }
                GradientStop { position: 1.0; color: Qt.hsva(cw.h, 1, 1, 1) }
            }

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: "#000000" }
                }
            }

            Rectangle {
                width: 14
                height: 14
                radius: 7
                x: cw.s * sv.width - 7
                y: (1 - cw.v) * sv.height - 7
                color: Qt.hsva(cw.h, cw.s, cw.v, 1)
                border.width: 2
                border.color: "#ffffff"
                scale: svArea.pressed ? 1.25 : 1
                Behavior on scale { Spring {} }
            }

            MouseArea {
                id: svArea
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.CrossCursor
                function at(m) {
                    cw.s = Math.max(0, Math.min(1, (m.x - 6) / sv.width));
                    cw.v = 1 - Math.max(0, Math.min(1, (m.y - 6) / sv.height));
                    cw.emit();
                }
                onPressed: m => { cw.dragging = true; at(m); }
                onPositionChanged: m => { if (pressed) at(m); }
                onReleased: { cw.dragging = false; Sfx.tap(); }
            }
        }

        Rectangle {
            readonly property real a: -Math.PI / 2 - cw.h * 2 * Math.PI
            width: cw.ring + 6
            height: width
            radius: width / 2
            x: cw.r + Math.cos(a) * (cw.r - cw.ring / 2) - width / 2
            y: cw.r + Math.sin(a) * (cw.r - cw.ring / 2) - height / 2
            color: Qt.hsva(cw.h, 1, 1, 1)
            border.width: 3
            border.color: "#ffffff"
            scale: ringArea.pressed ? 1.18 : 1
            Behavior on scale { Spring {} }
        }

        MouseArea {
            id: ringArea
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            property bool onRing: false
            function at(m) {
                const dx = m.x - cw.r, dy = m.y - cw.r;
                let h = (Math.atan2(-dy, dx) - Math.PI / 2) / (2 * Math.PI);
                h = ((h % 1) + 1) % 1;
                cw.h = h;
                if (cw.s < 0.05)
                    cw.s = 1;
                if (cw.v < 0.05)
                    cw.v = 1;
                cw.emit();
            }
            onPressed: m => {
                const d = Math.hypot(m.x - cw.r, m.y - cw.r);
                onRing = d > cw.r - cw.ring - 4 && d <= cw.r + 2;
                if (!onRing) {
                    m.accepted = false;
                    return;
                }
                cw.dragging = true;
                at(m);
            }
            onPositionChanged: m => { if (pressed && onRing) at(m); }
            onReleased: { cw.dragging = false; Sfx.tap(); }
        }
    }
}
