import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import Quickshell.Io
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: kit

    property var tipHost: null

    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property int fontSize: BarConfig.s("fontSize")
    readonly property int glyphSize: BarConfig.s("glyphSize")

    property var panels: ({})

    function peek(name) {
        const loader = kit.panels ? kit.panels[name] : null;
        return loader && loader.item ? loader.item : null;
    }

    function panel(name) {
        const loader = kit.panels ? kit.panels[name] : null;
        if (!loader)
            return null;
        if (!loader.item)
            loader.active = true;
        return loader.item;
    }

    function component(type) {
        switch (type) {
        case "workspaces":  return workspaces;
        case "media":       return media;
        case "clock":       return clock;
        case "tray":        return tray;
        case "network":     return network;
        case "bluetooth":   return bluetooth;
        case "vpn":         return vpn;
        case "netspeed":    return netspeed;
        case "volume":      return volume;
        case "mic":         return mic;
        case "battery":     return battery;
        case "keyboard":    return keyboard;
        case "brightness":  return brightness;
        case "peripherals": return peripherals;
        case "recorder":    return recorder;
        case "outbound":    return outbound;
        case "updates":     return updates;
        case "notifs":      return notifs;
        case "dnd":         return dnd;
        case "cpu":         return meterCpu;
        case "ram":         return meterRam;
        case "gpu":         return meterGpu;
        case "vram":        return meterVram;
        case "temp":        return meterTemp;
        case "gputemp":     return meterGputemp;
        case "disk":        return diskMeter;
        case "weather":     return weather;
        case "uptime":      return uptime;
        case "date":        return dateText;
        case "timer":       return timerMod;
        case "sep":         return separator;
        case "spacer":      return spacer;
        case "text":        return freeText;
        case "command":     return command;
        }
        return null;
    }

    SystemClock { id: clockMinutes; precision: SystemClock.Minutes }

    component Glyph: Text {
        color: Colors.fgDim
        opacity: 0.75
        font.family: kit.mono
        font.pixelSize: kit.glyphSize
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }

    component Label: Text {
        color: Colors.fgDim
        font.family: kit.mono
        font.pixelSize: kit.fontSize
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
    }

    component Tip: HoverHandler {
        property string text: ""
        onHoveredChanged: {
            if (!kit.tipHost || !BarConfig.s("tooltips"))
                return;
            if (hovered) kit.tipHost.show(parent, text);
            else kit.tipHost.hide(parent);
        }
    }

    component Meter: Item {
        property real value: 0
        property color tint: Colors.accent
        width: 22
        height: 3
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.25)
        }

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, parent.value))
            height: parent.height
            radius: height / 2
            color: parent.tint
            Behavior on width { NumberAnimation { duration: Motion.slow } }
            Behavior on color { ColorAnimation { duration: Motion.base } }
        }
    }

    function tone(v) {
        return v > 85 ? Colors.bad : v > 60 ? Colors.warn : Colors.fgDim;
    }

    Component {
        id: workspaces

        Item {
            id: ws
            property var item: null
            property bool shown: true

            implicitWidth: wsRow.implicitWidth
            implicitHeight: wsRow.implicitHeight
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            readonly property bool pill: BarConfig.opt(item, "pill")

            Tip { text: I18n.t("bar.workspaces") }

            property real trailFrom: 0
            property real trailTo: 0
            property real lastActiveX: -1

            function markActive(centerX) {
                if (ws.lastActiveX >= 0
                    && Math.abs(centerX - ws.lastActiveX) > 1) {
                    ws.trailFrom = ws.lastActiveX;
                    ws.trailTo = centerX;
                    trailAnim.restart();
                }
                ws.lastActiveX = centerX;
            }

            Rectangle {
                id: trail
                z: -1
                height: 3
                radius: 1.5
                anchors.verticalCenter: parent.verticalCenter
                opacity: 0
                color: Colors.accent

                property real head: ws.trailTo
                property real tail: ws.trailFrom

                x: Math.min(head, tail)
                width: Math.abs(head - tail)

                SequentialAnimation {
                    id: trailAnim

                    ScriptAction {
                        script: {
                            trail.tail = ws.trailFrom;
                            trail.head = ws.trailTo;
                            trail.opacity = 0.75;
                        }
                    }

                    ParallelAnimation {
                        NumberAnimation {
                            target: trail; property: "tail"
                            to: ws.trailTo
                            duration: 380
                            easing.type: Easing.OutCubic
                        }
                        SequentialAnimation {
                            PauseAnimation { duration: 140 }
                            NumberAnimation {
                                target: trail; property: "opacity"; to: 0
                                duration: 240
                                easing.type: Easing.InCubic
                            }
                        }
                    }
                }
            }

            Row {
                id: wsRow
                anchors.centerIn: parent
                spacing: 7

                Repeater {
                    model: Hyprland.workspaces

                    Rectangle {
                        id: wsDot
                        required property var modelData
                        readonly property bool isActive:
                            Hyprland.focusedWorkspace
                            && Hyprland.focusedWorkspace.id === modelData.id

                        readonly property bool hasApp:
                            Running.onWorkspace(modelData.id)

                        width: ws.pill && (isActive || hasApp) ? 20 : 7
                        height: 7
                        radius: 4
                        color: hasApp ? Colors.accentAlt
                             : isActive ? Colors.accent
                             : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                       Colors.fgDim.b, 0.30)
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on width {
                            NumberAnimation { duration: 280; easing.type: Easing.OutBack }
                        }
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            id: pulse
                            anchors.centerIn: parent
                            width: parent.width
                            height: parent.height
                            radius: height / 2
                            color: "transparent"
                            border.width: 2
                            border.color: wsDot.hasApp ? Colors.accentAlt : Colors.accent
                            opacity: 0
                            z: -1
                        }

                        ParallelAnimation {
                            id: pulseAnim
                            NumberAnimation {
                                target: pulse; property: "scale"
                                from: 1; to: 3.4
                                duration: 520; easing.type: Easing.OutCubic
                            }
                            NumberAnimation {
                                target: pulse; property: "opacity"
                                from: 0.85; to: 0
                                duration: 520; easing.type: Easing.OutCubic
                            }
                        }

                        onIsActiveChanged: {
                            if (!isActive) return;
                            pulseAnim.restart();

                            Qt.callLater(function () {
                                if (!wsDot.isActive) return;
                                const c = wsDot.mapToItem(ws, wsDot.width / 2, 0);
                                ws.markActive(c.x);
                            });
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -5
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Sfx.pick();
                                Hyprland.dispatch("workspace " + modelData.id);
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: media

        Item {
            id: mediaMod
            property var item: null

            readonly property bool showCover: BarConfig.opt(item, "cover")
            readonly property bool showSpectrum: BarConfig.opt(item, "spectrum")

            property bool shown: Media.has && Media.label !== ""
            visible: shown
            implicitWidth: shown ? (BarConfig.opt(item, "width") || 152) : 0
            implicitHeight: 22
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip {
                text: Media.has
                    ? Media.label + I18n.t("bar.clickMedia") + I18n.t("bar.wheelTrack")
                    : ""
            }

            Row {
                anchors.fill: parent
                anchors.verticalCenter: parent.verticalCenter
                spacing: 7

                Item {
                    width: mediaMod.showCover ? 22 : 0
                    height: 22
                    visible: mediaMod.showCover
                    anchors.verticalCenter: parent.verticalCenter

                    ProgressRing {
                        anchors.fill: parent
                        visible: Media.hasPosition
                        value: Media.progress
                        color: Colors.accent
                        trackColor: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                            Colors.outline.b, 0.30)
                    }

                    Rectangle {
                        width: 16
                        height: 16
                        radius: 5
                        clip: true
                        anchors.centerIn: parent
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.7)

                        Image {
                            id: barCover
                            anchors.fill: parent
                            source: Media.art
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 96
                            visible: Media.art !== "" && status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !barCover.visible
                            text: Media.playing ? "󰝚" : "󰎈"
                            color: Colors.accent
                            font.family: kit.mono
                            font.pixelSize: 10
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Media.toggle()
                    }
                }

                Row {
                    id: spectrum
                    visible: mediaMod.showSpectrum
                    width: parent.width - (mediaMod.showCover ? 29 : 0)
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    readonly property real barWidth:
                        (width - spacing * (Cava.bars - 1)) / Cava.bars

                    property bool holding: false

                    function sync() {
                        const want = spectrum.visible;
                        if (want === spectrum.holding) return;
                        spectrum.holding = want;
                        if (want) Cava.hold();
                        else Cava.release();
                    }

                    Component.onCompleted: spectrum.sync()
                    Component.onDestruction: if (spectrum.holding) Cava.release()
                    onVisibleChanged: spectrum.sync()

                    Repeater {
                        model: Cava.bars

                        Rectangle {
                            required property int index

                            readonly property real level: {
                                const v = Cava.smooth[index];
                                if (v === undefined) return 0;
                                return Math.min(1, v * 1.7);
                            }

                            width: spectrum.barWidth
                            radius: width / 2
                            anchors.verticalCenter: parent.verticalCenter

                            height: Math.max(width, level * spectrum.height)

                            color: Media.playing ? Colors.accent : Colors.fgDim
                            opacity: Media.playing ? 0.55 + level * 0.45 : 0.35

                            Behavior on color { ColorAnimation { duration: 250 } }
                        }
                    }
                }

                Marquee {
                    visible: !mediaMod.showSpectrum
                    width: parent.width - (mediaMod.showCover ? 29 : 0)
                    height: 18
                    anchors.verticalCenter: parent.verticalCenter
                    text: Media.label
                    color: Colors.fgDim
                    family: kit.mono
                    pixelSize: kit.fontSize
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                z: -1
                onClicked: function (mouse) {
                    if (mouse.button === Qt.RightButton) Media.next();
                    else kit.panel("media")?.toggle();
                }
            }

            WheelHandler {
                onWheel: wheel => {
                    if (wheel.angleDelta.y > 0) Media.previous();
                    else Media.next();
                }
            }
        }
    }

    Component {
        id: clock

        Item {
            id: clockMod
            property var item: null
            property bool shown: true

            readonly property bool wantFeedback:
                BarConfig.opt(item, "feedback")
                && Prefs.osdStyle === "island" && Feedback.shown

            readonly property bool wantSeconds: BarConfig.opt(item, "seconds")

            implicitWidth: wantFeedback
                ? readout.implicitWidth + 6
                : clockText.implicitWidth
            implicitHeight: 22
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Behavior on implicitWidth {
                NumberAnimation {
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.expo
                }
            }

            Tip {
                text: clockMod.wantFeedback
                    ? Feedback.label
                    : Qt.formatDateTime(clockMinutes.date, "dddd, d MMMM yyyy")
                      + I18n.t("bar.clickCal")
            }

            readonly property bool ringWanted: wantSeconds

            RollText {
                id: clockText

                anchors.centerIn: parent
                text: Qt.formatDateTime(clockMinutes.date,
                                        BarConfig.opt(clockMod.item, "format"))
                color: Colors.fg
                pixelSize: kit.fontSize + 1

                opacity: clockMod.wantFeedback ? 0 : 1
                transform: Translate { y: clockMod.wantFeedback ? -13 : 0 }

                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
            }

            Row {
                id: readout

                anchors.centerIn: parent
                spacing: 8

                opacity: clockMod.wantFeedback ? 1 : 0
                transform: Translate { y: clockMod.wantFeedback ? 0 : 13 }

                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: clockMod.wantFeedback ? Motion.instant : 0
                        }
                        NumberAnimation { duration: Motion.fast }
                    }
                }

                Text {
                    id: feedbackGlyph

                    anchors.verticalCenter: parent.verticalCenter
                    text: Feedback.icon
                    color: Colors.accent
                    font.family: Fonts.glyph
                    font.pixelSize: kit.glyphSize + 1

                    SequentialAnimation {
                        id: glyphPop
                        NumberAnimation {
                            target: feedbackGlyph; property: "scale"
                            to: 1.22; duration: Motion.instant
                        }
                        NumberAnimation {
                            target: feedbackGlyph; property: "scale"
                            to: 1.0; duration: Motion.base
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.snap
                        }
                    }
                }

                RollText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Feedback.label
                    color: Colors.fg
                    family: kit.mono
                    pixelSize: kit.fontSize + 1
                }
            }

            Connections {
                target: Feedback
                function onPulseChanged() {
                    if (!clockMod.wantFeedback)
                        return;
                    glyphPop.restart();
                }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: kit.panel("calendar")?.toggle()
            }
        }
    }

    Component {
        id: tray

        Row {
            property var item: null
            spacing: 9
            property bool shown: SystemTray.items.values.length > 0
            visible: shown
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Repeater {
                model: SystemTray.items

                IconImage {
                    required property var modelData
                    source: {
                        const i = modelData.icon;
                        if (!i) return "";
                        if (i.startsWith("/") || i.includes("://") || i.includes("?"))
                            return i;
                        return Quickshell.iconPath(i, "application-x-executable");
                    }
                    implicitSize: BarConfig.opt(item, "size") || 15
                    anchors.verticalCenter: parent.verticalCenter

                    Tip {
                        text: modelData.tooltipTitle && modelData.tooltipTitle !== ""
                            ? modelData.tooltipTitle
                            : (modelData.title ? modelData.title : "")
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        onClicked: function (mouse) {
                            if (mouse.button === Qt.LeftButton) modelData.activate();
                            else modelData.secondaryActivate();
                        }
                    }
                }
            }
        }
    }

    Component {
        id: network

        Row {
            property var item: null
            property bool shown: true
                        spacing: 5
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip {
                text: Network.connected
                    ? Network.ssid + I18n.t("net.signalDot") + Network.strength + "%"
                      + I18n.t("bar.clickNet")
                    : I18n.t("bar.noConnection")
            }

            Text {
                text: Network.glyph
                color: Network.connected ? Colors.fgDim : Colors.bad
                opacity: Network.connected ? 0.75 : 1.0
                font.family: kit.mono
                font.pixelSize: kit.glyphSize
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 250 } }
            }

            Label {
                visible: BarConfig.opt(item, "label") && Network.ssid !== ""
                text: Network.ssid
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 120)
            }

            TapHandler {
                cursorShape: Qt.PointingHandCursor
                onTapped: kit.panel("net")?.toggle("wifi")
            }
        }
    }

    Component {
        id: bluetooth

        Text {
            property var item: null
            property bool shown: Bt.present && (Bt.powered || Bt.connectedCount > 0)
            visible: shown
            text: Bt.glyph
            color: Bt.connectedCount > 0 ? Colors.accentAlt : Colors.fgDim
            opacity: Bt.connectedCount > 0 ? 0.95 : 0.6
            font.family: kit.mono
            font.pixelSize: kit.glyphSize
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip {
                text: Bt.connectedCount > 0
                    ? Bt.label(Bt.primary)
                      + (Bt.primary && Bt.primary.batteryAvailable
                         ? "  ·  " + Math.round(Bt.primary.battery * 100) + "%" : "")
                      + I18n.t("bar.clickBt")
                    : I18n.t("bar.bluetooth")
            }

            Behavior on color { ColorAnimation { duration: 250 } }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: kit.panel("net")?.toggle("bt")
            }
        }
    }

    Component {
        id: vpn

        Item {
            property var item: null
                        width: Vpn.up ? 12 : 0
            height: 12
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            property bool shown: width > 0
            visible: shown
            opacity: Vpn.up ? 1 : 0

            Behavior on width {
                NumberAnimation { duration: 260; easing.type: Easing.OutBack }
            }
            Behavior on opacity { NumberAnimation { duration: 200 } }

            Tip { text: "VPN  ·  " + Vpn.label + I18n.t("bar.clickAddr") }

            Rectangle {
                anchors.centerIn: parent
                width: 12
                height: 12
                radius: 6
                color: "transparent"
                border.width: 1.5
                border.color: Colors.good
                opacity: 0

                SequentialAnimation on opacity {
                    running: Vpn.up && Vpn.checking
                    loops: Animation.Infinite
                    NumberAnimation { to: 0.55; duration: 700; easing.type: Easing.OutCubic }
                    NumberAnimation { to: 0.05; duration: 700; easing.type: Easing.InCubic }
                }
            }

            Rectangle {
                anchors.centerIn: parent
                width: 7
                height: 7
                radius: 3.5
                color: Vpn.exitIp === "" ? Colors.warn : Colors.good
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -4
                cursorShape: Qt.PointingHandCursor
                onClicked: Vpn.refresh()
            }
        }
    }

    Component {
        id: netspeed

        Row {
            property var item: null
            property bool shown: true
                        spacing: 6
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Component.onCompleted: Network.hold()
            Component.onDestruction: Network.release()

            Tip { text: I18n.t("barc.netspeed") }

            Row {
                spacing: 3
                visible: BarConfig.opt(item, "down")
                anchors.verticalCenter: parent.verticalCenter

                Glyph { text: "󰇚"; color: Colors.accent; opacity: 0.85 }
                Label { text: Network.human(Network.rxRate) }
            }

            Row {
                spacing: 3
                visible: BarConfig.opt(item, "up")
                anchors.verticalCenter: parent.verticalCenter

                Glyph { text: "󰕒"; color: Colors.accentAlt; opacity: 0.85 }
                Label { text: Network.human(Network.txRate) }
            }
        }
    }

    Component {
        id: volume

        Row {
            id: volRow
            property var item: null
            property bool shown: true
            spacing: 4
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            readonly property var sink: Pipewire.defaultAudioSink
            readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
            readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

            Tip {
                text: (volRow.muted ? I18n.t("audio.soundOff")
                                    : I18n.t("audio.volume") + Math.round(volRow.vol * 100) + "%")
                      + I18n.t("bar.clickVol")
            }

            Text {
                text: volRow.muted ? "󰝟" : "󰕾"
                color: volRow.muted ? Colors.bad : Colors.fgDim
                opacity: volRow.muted ? 1.0 : 0.75
                font.family: kit.mono
                font.pixelSize: kit.glyphSize
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                visible: !volRow.muted && BarConfig.opt(volRow.item, "percent")
                text: Math.round(volRow.vol * 100) + "%"
            }

            TapHandler {
                cursorShape: Qt.PointingHandCursor
                onTapped: {
                    const a = volRow.sink && volRow.sink.audio;
                    if (a) a.muted = !a.muted;
                }
            }

            WheelHandler {
                onWheel: wheel => {
                    const a = volRow.sink && volRow.sink.audio;
                    if (!a) return;
                    const step = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
                    a.volume = Math.max(0, Math.min(1, a.volume + step));
                }
            }
        }
    }

    Component {
        id: mic

        Text {
            property var item: null
                        readonly property var src: Pipewire.defaultAudioSource
            property bool shown: src && src.audio && src.audio.muted
            visible: shown
            text: "󰍭"
            color: Colors.bad
            font.family: kit.mono
            font.pixelSize: kit.glyphSize
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip { text: I18n.t("audio.micOff") }
        }
    }

    Component {
        id: battery

        Text {
            id: battText
            property var item: null

            readonly property var dev: UPower.displayDevice
            readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
            readonly property bool charging:
                dev && dev.state === UPowerDeviceState.Charging

            property bool shown: dev && dev.isLaptopBattery
            visible: shown
            text: (charging ? "󰂄 " : "")
                  + (BarConfig.opt(item, "percent") ? pct + "%" : "")
            color: charging ? Colors.good
                 : pct <= 12 ? Colors.bad
                 : pct <= 25 ? Colors.warn
                 : Colors.fg
            font.family: kit.mono
            font.pixelSize: kit.fontSize
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip {
                text: {
                    if (!battText.dev) return "";
                    if (battText.charging) return I18n.t("bar.charging") + battText.pct + "%";
                    const t = battText.dev.timeToEmpty;
                    if (!t || t <= 0) return I18n.t("bar.battery") + battText.pct + "%";
                    const h = Math.floor(t / 3600);
                    const m = Math.floor((t % 3600) / 60);
                    return I18n.t("bar.battery") + battText.pct + I18n.t("bar.remaining")
                           + (h > 0 ? h + I18n.t("unit.hourSpace") : "") + m + I18n.t("unit.min");
                }
            }

            Behavior on color { ColorAnimation { duration: 300 } }
        }
    }

    Component {
        id: keyboard

        Text {
            property var item: null
            property bool shown: true
            text: Keyboard.code
            color: Colors.fgDim
            font.family: kit.mono
            font.pixelSize: kit.fontSize - 1
            font.letterSpacing: 0.8
            font.weight: Font.DemiBold
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip { text: I18n.t("bar.layout") }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                cursorShape: Qt.PointingHandCursor
                onClicked: Keyboard.next()
            }
        }
    }

    Component {
        id: brightness

        Row {
            property var item: null
                        spacing: 4
            property bool shown: Brightness.available
            visible: shown
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip { text: I18n.t("barc.brightness") }

            Glyph { text: "󰃞" }
            Label {
                visible: BarConfig.opt(item, "percent")
                text: Math.round(Brightness.value * 100) + "%"
            }

            WheelHandler {
                onWheel: wheel => Brightness.change(wheel.angleDelta.y > 0 ? 0.05 : -0.05)
            }
        }
    }

    Component {
        id: peripherals

        Row {
            property var item: null
                        spacing: 4
            property bool shown: Peripherals.low
            visible: shown
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip { text: Peripherals.model + "  ·  " + Peripherals.percent + "%" }

            Text {
                text: Peripherals.glyph
                color: Peripherals.critical ? Colors.bad : Colors.warn
                font.family: kit.mono
                font.pixelSize: kit.glyphSize
                anchors.verticalCenter: parent.verticalCenter
                Behavior on color { ColorAnimation { duration: 300 } }
            }

            Text {
                text: Peripherals.percent + "%"
                color: Peripherals.critical ? Colors.bad : Colors.warn
                font.family: kit.mono
                font.pixelSize: kit.fontSize - 1
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Component {
        id: recorder

        Rectangle {
            property var item: null
            property bool shown: Recorder.active
            visible: shown
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            width: recInner.implicitWidth + 16
            height: 20
            radius: Shape.detail + 4
            color: Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.14)

            Tip { text: I18n.t("bar.recording") }

            Row {
                id: recInner
                anchors.centerIn: parent
                spacing: 6

                Rectangle {
                    width: 8
                    height: 8
                    radius: 4
                    color: Colors.bad
                    anchors.verticalCenter: parent.verticalCenter
                    opacity: 0.25 + Phase.wave(1.4) * 0.75

                    PhaseHold { active: Recorder.active }
                }

                Text {
                    text: Recorder.clock
                    color: Colors.bad
                    font.family: Fonts.mono
                    font.pixelSize: kit.fontSize
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            TapHandler {
                cursorShape: Qt.PointingHandCursor
                onTapped: Recorder.stop()
            }
        }
    }

    Component {
        id: outbound

        Row {
            property var item: null
            spacing: 6
            property bool shown: Outbound.active
            visible: shown
            opacity: Outbound.active ? 1 : 0
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Behavior on opacity {
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }

            Tip { text: Outbound.tooltip }

            Text {
                text: "󰤨"
                color: Colors.warn
                font.family: kit.mono
                font.pixelSize: kit.glyphSize
                anchors.verticalCenter: parent.verticalCenter

                SequentialAnimation on opacity {
                    running: Outbound.active
                    loops: 3
                    NumberAnimation { to: 0.35; duration: 320 }
                    NumberAnimation { to: 1.0;  duration: 320 }
                }
            }

            Text {
                text: Outbound.label
                color: Colors.warn
                font.family: kit.mono
                font.pixelSize: kit.fontSize - 1
                elide: Text.ElideRight
                width: Math.min(implicitWidth, 200)
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    Component {
        id: updates

        Row {
            property var item: null
                        spacing: 4
            property bool shown: Updates.ready && Updates.count > 0
            visible: shown
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip { text: Updates.count + "  " + I18n.t("desk.updates") }

            Glyph { text: "󰏗"; color: Colors.accentAlt; opacity: 0.9 }
            Label {
                visible: BarConfig.opt(item, "count")
                text: Updates.count
                color: Colors.accentAlt
            }
        }
    }

    Component {
        id: notifs

        Row {
            property var item: null
            property bool shown: true
                        spacing: 4
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip { text: I18n.t("desk.notifs") }

            Glyph {
                text: NotifHistory.unseen > 0 ? "󰂚" : "󰂜"
                color: NotifHistory.unseen > 0 ? Colors.accent : Colors.fgDim
            }
            Label {
                visible: BarConfig.opt(item, "count") && NotifHistory.unseen > 0
                text: NotifHistory.unseen
                color: Colors.accent
            }

            TapHandler {
                cursorShape: Qt.PointingHandCursor
                onTapped: kit.panel("notifCenter")?.toggle()
            }
        }
    }

    Component {
        id: dnd

        Text {
            property var item: null
            property bool shown: true
            text: Dnd.active ? "󰂛" : "󰂚"
            color: Dnd.active ? Colors.warn : Colors.fgDim
            opacity: Dnd.active ? 1 : 0.7
            font.family: kit.mono
            font.pixelSize: kit.glyphSize
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip { text: Dnd.active ? I18n.t("notif.dnd") : I18n.t("notif.dndOff") }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                cursorShape: Qt.PointingHandCursor
                onClicked: Dnd.toggle()
            }
        }
    }

    component SysMeter: Row {
        property var item
        property string glyph: ""
        property real value: -1
        property string label: ""
        property string tip: ""

        spacing: 4
        property bool shown: value >= 0
        visible: shown
        anchors.verticalCenter: parent ? parent.verticalCenter : undefined

        Component.onCompleted: Sys.acquire()
        Component.onDestruction: Sys.release()

        Tip { text: parent.tip }

        Text {
            text: parent.glyph
            color: kit.tone(parent.value)
            opacity: 0.9
            font.family: kit.mono
            font.pixelSize: kit.glyphSize
            anchors.verticalCenter: parent.verticalCenter
            Behavior on color { ColorAnimation { duration: Motion.base } }
        }

        Label {
            visible: BarConfig.opt(parent.item, "label")
            text: parent.label
            color: kit.tone(parent.value)
            Behavior on color { ColorAnimation { duration: Motion.base } }
        }

        Meter {
            visible: BarConfig.opt(parent.item, "bar")
            value: parent.value / 100
            tint: kit.tone(parent.value)
        }
    }

    Component {
        id: meterCpu
        SysMeter {
            glyph: "󱠓"; value: Sys.cpu; label: Sys.cpuLabel; tip: "CPU"
        }
    }

    Component {
        id: meterRam
        SysMeter {
            glyph: "󰍛"; value: Sys.mem; label: Sys.memLabel; tip: "RAM"
        }
    }

    Component {
        id: meterGpu
        SysMeter {
            glyph: "󰢮"; value: Sys.gpu; label: Sys.gpuLabel; tip: "GPU"
        }
    }

    Component {
        id: meterVram
        SysMeter {
            glyph: "󰍹"; value: Sys.vram; label: Sys.vramLabel; tip: "VRAM"
        }
    }

    Component {
        id: meterTemp
        SysMeter {
            glyph: "󰔏"; value: Sys.temp; label: Sys.tempLabel
            tip: I18n.t("barc.cputemp")
        }
    }

    Component {
        id: meterGputemp
        SysMeter {
            glyph: "󰔏"; value: Sys.gputemp; label: Sys.gputempLabel
            tip: I18n.t("barc.gputemp")
        }
    }

    Component {
        id: diskMeter

        Row {
            id: diskRow
            property var item: null
                        spacing: 4
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Component.onCompleted: Disk.acquire()
            Component.onDestruction: Disk.release()

            readonly property var mount: {
                const want = BarConfig.opt(item, "mount");
                const list = Disk.mounts;
                for (let i = 0; i < list.length; i++)
                    if (list[i].path === want) return list[i];
                return list.length > 0 ? list[0] : null;
            }

            property bool shown: mount !== null
            visible: shown

            Tip {
                text: diskRow.mount
                    ? diskRow.mount.path + "  ·  " + Disk.human(diskRow.mount.free)
                    : ""
            }

            Glyph { text: "󰋊" }
            Label {
                text: diskRow.mount ? Disk.human(diskRow.mount.free) : ""
            }
        }
    }

    Component {
        id: weather

        Row {
            property var item: null
            spacing: 5
            property bool shown: Weather.ready
            visible: shown
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip { text: Weather.text + "  ·  " + Weather.city }

            Glyph {
                visible: BarConfig.opt(item, "icon")
                text: Weather.glyph
                color: Colors.accent
                opacity: 0.9
            }

            Label { text: Math.round(Weather.temp) + "\u00b0" }
        }
    }

    Component {
        id: uptime

        Row {
            id: upRow
            property var item: null
            property bool shown: true
                        spacing: 5
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            property string value: ""

            Tip { text: I18n.t("barc.uptime") }

            Process {
                id: upProc
                command: ["cat", "/proc/uptime"]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const s = parseFloat(this.text.trim().split(" ")[0]);
                        if (!isFinite(s)) return;
                        const h = Math.floor(s / 3600);
                        const m = Math.floor((s % 3600) / 60);
                        upRow.value = h > 0 ? h + "ч " + m + "м" : m + "м";
                    }
                }
            }

            Timer {
                running: true
                repeat: true
                interval: 60000
                triggeredOnStart: true
                onTriggered: upProc.running = true
            }

            Glyph { text: "󰅐" }
            Label { text: upRow.value }
        }
    }

    Component {
        id: dateText

        Text {
            property var item: null
            property bool shown: true
            text: Qt.formatDateTime(clockMinutes.date, BarConfig.opt(item, "format"))
            color: Colors.fgDim
            font.family: kit.mono
            font.pixelSize: kit.fontSize
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip { text: I18n.t("bar.clickCal") }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -3
                cursorShape: Qt.PointingHandCursor
                onClicked: kit.panel("calendar")?.toggle()
            }
        }
    }

    Component {
        id: timerMod

        Row {
            property var item: null
                        spacing: 4
            property bool shown: Timers.soonest !== null
            visible: shown
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Tip { text: I18n.t("timer.title") }

            Glyph {
                text: "󰔛"
                color: Timers.anyRinging ? Colors.bad : Colors.accent
            }
            Label {
                text: Timers.soonest ? Timers.human(Timers.left(Timers.soonest)) : ""
                color: Timers.anyRinging ? Colors.bad : Colors.fgDim
            }

            TapHandler {
                cursorShape: Qt.PointingHandCursor
                onTapped: kit.panel("timer")?.toggle()
            }
        }
    }

    Component {
        id: separator

        Rectangle {
            property var item: null
            property bool shown: true
                        anchors.verticalCenter: parent ? parent.verticalCenter : undefined
            width: 1
            height: 12
            radius: 1
            color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.18)
        }
    }

    Component {
        id: spacer

        Item {
            property var item: null
            property bool shown: true
            width: BarConfig.opt(item, "size") || 16
            height: 1
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined
        }
    }

    Component {
        id: freeText

        Row {
            property var item: null
            property bool shown: true
                        spacing: 5
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            Glyph {
                visible: text !== ""
                text: BarConfig.opt(item, "glyph")
            }
            Label { text: BarConfig.opt(item, "content") }
        }
    }

    Component {
        id: command

        Row {
            id: cmdRow
            property var item: null
            property bool shown: true
            spacing: 5
            anchors.verticalCenter: parent ? parent.verticalCenter : undefined

            property string value: ""

            Process {
                id: cmdProc
                command: ["sh", "-c", BarConfig.opt(cmdRow.item, "run")]
                stdout: StdioCollector {
                    onStreamFinished: cmdRow.value = this.text.trim().split("\n")[0]
                }
            }

            Timer {
                running: true
                repeat: true
                interval: Math.max(1, BarConfig.opt(cmdRow.item, "every") || 10) * 1000
                triggeredOnStart: true
                onTriggered: cmdProc.running = true
            }

            Glyph {
                visible: text !== ""
                text: BarConfig.opt(cmdRow.item, "glyph")
            }
            Label { text: cmdRow.value }

            TapHandler {
                enabled: BarConfig.opt(cmdRow.item, "click") !== ""
                cursorShape: Qt.PointingHandCursor
                onTapped: Quickshell.execDetached(
                    ["sh", "-c", BarConfig.opt(cmdRow.item, "click")])
            }
        }
    }
}
