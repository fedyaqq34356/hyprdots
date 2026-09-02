import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Wayland
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    SystemClock {
        id: secondsClock
        precision: SystemClock.Seconds
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            WlrLayershell.namespace: "qs-bar"
            id: win
            required property var modelData
            screen: modelData

            anchors {
                top: Prefs.barAtTop
                bottom: !Prefs.barAtTop
                left: true
                right: true
            }

            implicitHeight: 96
            exclusiveZone: 34
            color: "transparent"
            mask: Region { item: strip }

            component Tip: HoverHandler {
                property string text: ""
                onHoveredChanged: hovered ? tips.show(parent, text) : tips.hide(parent)
            }

            component Sep: Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 12
                radius: 1
                color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.18)
            }

            component Island: Rectangle {
                id: island
                property bool hovered: false

                property int introDelay: 0

                radius: Shape.chip
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b,
                               hovered ? 0.92 : 0.80)
                border.width: 1
                border.color: hovered
                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.55)
                    : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.32)

                scale: hovered ? 1.04 : 1.0

                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, island.hovered ? 0.45 : 0.30)
                    shadowBlur: 0.55
                    shadowVerticalOffset: 3
                }

                Behavior on color { ColorAnimation { duration: 220 } }
                Behavior on border.color { ColorAnimation { duration: 220 } }
                Behavior on scale {
                    NumberAnimation { duration: 240; easing.type: Easing.OutBack }
                }

                HoverHandler {
                    onHoveredChanged: island.hovered = hovered
                }

                opacity: 0
                transform: Translate { id: intro; y: -42 }

                Component.onCompleted: introAnim.start()

                SequentialAnimation {
                    id: introAnim

                    PauseAnimation { duration: island.introDelay }

                    ParallelAnimation {
                        NumberAnimation {
                            target: intro; property: "y"; to: 0
                            duration: 620
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.05
                        }
                        NumberAnimation {
                            target: island; property: "opacity"; to: 1
                            duration: 380
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            Item {
                id: strip
                anchors.top: Prefs.barAtTop ? parent.top : undefined
                anchors.bottom: Prefs.barAtTop ? undefined : parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 34

                Island {
                    id: wsIsland
                    introDelay: 0
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    height: 26
                    width: wsRow.implicitWidth + 16

                    Tip { text: I18n.t("bar.workspaces") }

                    property real trailFrom: 0
                    property real trailTo: 0
                    property real lastActiveX: -1

                    function markActive(centerX) {
                        if (wsIsland.lastActiveX >= 0
                            && Math.abs(centerX - wsIsland.lastActiveX) > 1) {
                            wsIsland.trailFrom = wsIsland.lastActiveX;
                            wsIsland.trailTo = centerX;
                            trailAnim.restart();
                        }
                        wsIsland.lastActiveX = centerX;
                    }

                    Rectangle {
                        id: trail
                        z: -1
                        height: 3
                        radius: 1.5
                        anchors.verticalCenter: parent.verticalCenter
                        opacity: 0
                        color: Colors.accent

                        property real head: wsIsland.trailTo
                        property real tail: wsIsland.trailFrom

                        x: Math.min(head, tail)
                        width: Math.abs(head - tail)

                        SequentialAnimation {
                            id: trailAnim

                            ScriptAction {
                                script: {
                                    trail.tail = wsIsland.trailFrom;
                                    trail.head = wsIsland.trailTo;
                                    trail.opacity = 0.75;
                                }
                            }

                            ParallelAnimation {
                                NumberAnimation {
                                    target: trail; property: "tail"
                                    to: wsIsland.trailTo
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

                                width: isActive || hasApp ? 20 : 7
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
                                        const c = wsDot.mapToItem(
                                            wsIsland, wsDot.width / 2, 0);
                                        wsIsland.markActive(c.x);
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

                Island {
                    id: mediaIsland
                    introDelay: 110
                    visible: Media.has && Media.label !== ""

                    anchors.left: wsIsland.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    height: 26
                    width: 152

                    Tip {
                        text: Media.has
                        ? Media.label + I18n.t("bar.clickMedia")
                          + I18n.t("bar.wheelTrack")
                        : ""
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        Item {
                            width: 22
                            height: 22
                            anchors.verticalCenter: parent.verticalCenter

                            ProgressRing {
                                anchors.fill: parent
                                visible: Media.hasPosition
                                value: Media.progress
                                color: Colors.accent
                                trackColor: Qt.rgba(Colors.outline.r,
                                                    Colors.outline.g,
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
                                    visible: Media.art !== "" && status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !barCover.visible
                                    text: Media.playing ? "󰝚" : "󰎈"
                                    color: Colors.accent
                                    font.family: "JetBrainsMono Nerd Font"
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
                            width: parent.width - 36
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            readonly property real barWidth:
                                (width - spacing * (Cava.bars - 1)) / Cava.bars

                            Repeater {
                                model: Cava.bars

                                Rectangle {
                                    required property int index

                                    readonly property real level: {
                                        const v = Cava.levels[index];
                                        if (v === undefined) return 0;
                                        return Math.min(1, v * 1.7);
                                    }

                                    width: spectrum.barWidth
                                    radius: width / 2
                                    anchors.verticalCenter: parent.verticalCenter

                                    height: Math.max(width, level * spectrum.height)

                                    color: Media.playing ? Colors.accent : Colors.fgDim
                                    opacity: Media.playing ? 0.55 + level * 0.45 : 0.35

                                    Behavior on height {
                                        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                                    }
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        z: -1
                        onClicked: function (mouse) {
                            if (mouse.button === Qt.RightButton) Media.next();
                            else media.toggle();
                        }
                    }

                    WheelHandler {
                        onWheel: wheel => {
                            if (wheel.angleDelta.y > 0) Media.previous();
                            else Media.next();
                        }
                    }
                }

                Island {
                    id: clockIsland

                    readonly property bool feedback:
                        Prefs.osdStyle === "island" && Feedback.shown

                    introDelay: 220
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    height: 26
                    width: clockIsland.feedback
                        ? readout.implicitWidth + 30
                        : clockText.implicitWidth + 24

                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.slow
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.expo
                        }
                    }

                    Tip {
                        text: clockIsland.feedback
                            ? Feedback.label
                            : calendar.longDate + I18n.t("bar.clickCal")
                    }

                    RectRing {
                        id: secondsArc
                        anchors.fill: parent
                        radius: parent.radius
                        thickness: clockIsland.feedback ? 2.5 : 2
                        inset: 1
                        color: clockIsland.feedback
                            ? Colors.accent
                            : Qt.rgba(Colors.accent.r, Colors.accent.g,
                                      Colors.accent.b, 0.85)

                        readonly property int seconds:
                            secondsClock.date.getSeconds()

                        value: clockIsland.feedback
                            ? Math.max(0, Math.min(1, Feedback.value))
                            : seconds / 60

                        wave: clockIsland.feedback
                        amplitude: clockIsland.feedback
                            ? 0.4 + Math.max(0, Math.min(1, Feedback.value)) * 1.9
                            : 0
                        wavelength: 34

                        Behavior on amplitude {
                            NumberAnimation {
                                duration: Motion.base
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.decel
                            }
                        }

                        NumberAnimation on phase {
                            running: clockIsland.feedback
                            loops: Animation.Infinite
                            from: 0
                            to: Math.PI * 2
                            duration: 1400
                        }

                        Behavior on thickness { NumberAnimation { duration: Motion.base } }
                        Behavior on value {
                            enabled: clockIsland.feedback || secondsArc.seconds !== 0
                            NumberAnimation {
                                duration: clockIsland.feedback ? Motion.slow : 1000
                                easing.type: clockIsland.feedback
                                    ? Easing.Bezier : Easing.Linear
                                easing.bezierCurve: Motion.expo
                            }
                        }
                    }

                    RollText {
                        id: clockText

                        anchors.centerIn: parent
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Colors.fg
                        pixelSize: 12

                        opacity: clockIsland.feedback ? 0 : 1
                        transform: Translate { y: clockIsland.feedback ? -13 : 0 }

                        Behavior on opacity {
                            NumberAnimation { duration: Motion.fast }
                        }
                    }

                    Row {
                        id: readout

                        anchors.centerIn: parent
                        spacing: 8

                        opacity: clockIsland.feedback ? 1 : 0
                        transform: Translate { y: clockIsland.feedback ? 0 : 13 }

                        Behavior on opacity {
                            SequentialAnimation {
                                PauseAnimation {
                                    duration: clockIsland.feedback ? Motion.instant : 0
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
                            font.pixelSize: 13

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
                            family: "JetBrainsMono Nerd Font"
                            pixelSize: 12
                        }
                    }

                    SequentialAnimation {
                        id: islandNudge
                        NumberAnimation {
                            target: clockIsland; property: "scale"
                            to: 1.06; duration: Motion.instant
                        }
                        NumberAnimation {
                            target: clockIsland; property: "scale"
                            to: 1.0; duration: Motion.slow
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.snap
                        }
                    }

                    Connections {
                        target: Feedback
                        function onPulseChanged() {
                            if (!clockIsland.feedback)
                                return;
                            islandNudge.restart();
                            glyphPop.restart();
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calendar.toggle()
                    }
                }

                Island {
                    introDelay: 330
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 8
                    height: 26
                    width: rightRow.implicitWidth + 20

                    RowLayout {
                        id: rightRow
                        anchors.centerIn: parent
                        spacing: 8

                        Row {
                            id: outRow
                            spacing: 6
                            visible: Outbound.active
                            opacity: Outbound.active ? 1 : 0

                            Behavior on opacity {
                                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
                            }

                            Tip { text: Outbound.tooltip }

                            Text {
                                text: "󰤨"
                                color: Colors.warn
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
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
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                width: Math.min(implicitWidth, 200)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Sep { visible: Outbound.active }

                        Row {
                            id: recRow
                            spacing: 6
                            visible: Recorder.active

                            Tip { text: I18n.t("bar.recording") }

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: Colors.bad
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on opacity {
                                    running: Recorder.active
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutQuad }
                                }
                            }

                            Text {
                                text: Recorder.clock
                                color: Colors.bad
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            TapHandler {
                                cursorShape: Qt.PointingHandCursor
                                onTapped: Recorder.stop()
                            }
                        }

                        Sep { visible: Recorder.active && SystemTray.items.values.length > 0 }

                        Row {
                            spacing: 9
                            visible: SystemTray.items.values.length > 0

                            Repeater {
                                model: SystemTray.items

                                IconImage {
                                    id: trayIcon
                                    required property var modelData
                                    source: {
                                        const i = modelData.icon;
                                        if (!i) return "";
                                        if (i.startsWith("/") || i.includes("://")
                                            || i.includes("?")) return i;
                                        return Quickshell.iconPath(i, "application-x-executable");
                                    }
                                    implicitSize: 15
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
                                            if (mouse.button === Qt.LeftButton)
                                                modelData.activate();
                                            else
                                                modelData.secondaryActivate();
                                        }
                                    }
                                }
                            }
                        }

                        Sep { visible: SystemTray.items.values.length > 0 }

                        Row {
                            spacing: 8

                            Item {
                                id: vpnDot
                                width: Vpn.up ? 12 : 0
                                height: 12
                                anchors.verticalCenter: parent.verticalCenter
                                visible: width > 0
                                opacity: Vpn.up ? 1 : 0

                                Behavior on width {
                                    NumberAnimation { duration: 260; easing.type: Easing.OutBack }
                                }
                                Behavior on opacity { NumberAnimation { duration: 200 } }

                                Tip { text: "VPN  ·  " + Vpn.label + I18n.t("bar.clickAddr") }

                                Rectangle {
                                    id: halo
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

                            Text {
                                id: netGlyph
                                text: Network.glyph
                                color: Network.connected ? Colors.fgDim : Colors.bad
                                opacity: Network.connected ? 0.75 : 1.0
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter

                                Tip {
                                    text: Network.connected
                                    ? Network.ssid + I18n.t("net.signalDot") + Network.strength + "%"
                                      + I18n.t("bar.clickNet")
                                    : I18n.t("bar.noConnection")
                                }

                                Behavior on color { ColorAnimation { duration: 250 } }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: net.toggle("wifi")
                                }
                            }

                            Text {
                                id: btGlyph
                                visible: Bt.present && (Bt.powered || Bt.connectedCount > 0)
                                text: Bt.glyph
                                color: Bt.connectedCount > 0 ? Colors.accentAlt : Colors.fgDim
                                opacity: Bt.connectedCount > 0 ? 0.95 : 0.6
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter

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
                                    onClicked: net.toggle("bt")
                                }
                            }

                            Text {
                                id: micGlyph
                                readonly property var src: Pipewire.defaultAudioSource
                                visible: src && src.audio && src.audio.muted
                                text: "󰍭"
                                color: Colors.bad
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter

                                Tip { text: I18n.t("audio.micOff") }
                            }

                            Row {
                                id: volRow
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter

                                readonly property var sink: Pipewire.defaultAudioSink
                                readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
                                readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

                                Tip {
                                    text: (volRow.muted ? I18n.t("audio.soundOff") : I18n.t("audio.volume")
                                          + Math.round(volRow.vol * 100) + "%")
                                          + I18n.t("bar.clickVol")
                                }

                                Text {
                                    text: parent.muted ? "󰝟" : "󰕾"
                                    color: parent.muted ? Colors.bad : Colors.fgDim
                                    opacity: parent.muted ? 1.0 : 0.75
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    visible: !parent.muted
                                    text: Math.round(parent.vol * 100) + "%"
                                    color: Colors.fgDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                TapHandler {
                                    cursorShape: Qt.PointingHandCursor
                                    onTapped: {
                                        const a = parent.sink && parent.sink.audio;
                                        if (a) a.muted = !a.muted;
                                    }
                                }

                                WheelHandler {
                                    onWheel: wheel => {
                                        const a = parent.sink && parent.sink.audio;
                                        if (!a) return;
                                        const step = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
                                        a.volume = Math.max(0, Math.min(1, a.volume + step));
                                    }
                                }
                            }
                        }

                        Sep {}

                        Row {
                            spacing: 9

                            Row {
                                id: periphRow
                                spacing: 4
                                visible: Peripherals.low
                                anchors.verticalCenter: parent.verticalCenter

                                Tip {
                                    text: Peripherals.model + "  ·  " + Peripherals.percent + "%"
                                }

                                Text {
                                    text: Peripherals.glyph
                                    color: Peripherals.critical ? Colors.bad : Colors.warn
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }

                                Text {
                                    text: Peripherals.percent + "%"
                                    color: Peripherals.critical ? Colors.bad : Colors.warn
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                id: kbText
                                text: Keyboard.code
                                color: Colors.fgDim
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.letterSpacing: 0.8
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter

                                Tip { text: I18n.t("bar.layout") }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Keyboard.next()
                                }
                            }

                            Text {
                                id: battText
                                readonly property var dev: UPower.displayDevice
                                readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
                                readonly property bool charging:
                                    dev && dev.state === UPowerDeviceState.Charging

                                visible: dev && dev.isLaptopBattery
                                text: (charging ? "󰂄 " : "") + pct + "%"
                                color: charging ? Colors.good
                                     : pct <= 12 ? Colors.bad
                                     : pct <= 25 ? Colors.warn
                                     : Colors.fg
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter

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
                    }
                }
            }

            IdleInhibitor {
                window: win
                enabled: {
                    const list = ToplevelManager.toplevels
                        ? ToplevelManager.toplevels.values : [];
                    for (const t of list) {
                        if (t && t.fullscreen) return true;
                    }
                    return false;
                }
            }

            Item {
                id: tips
                anchors.fill: parent
                z: 200

                property Item current: null
                property string text: ""

                function show(item, str) {
                    if (!str || str === "") return;
                    tips.current = item;
                    tips.text = str;
                }

                function hide(item) {
                    if (tips.current === item) {
                        tips.current = null;
                        tips.text = "";
                    }
                }

                readonly property point at: current
                    ? current.mapToItem(tips, current.width / 2,
                                        Prefs.barAtTop ? current.height : 0)
                    : Qt.point(0, 0)

                Rectangle {
                    id: bubble
                    visible: opacity > 0.01
                    opacity: tips.current ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 140 } }

                    x: Math.max(6, Math.min(tips.width - width - 6,
                                            tips.at.x - width / 2))
                    y: Prefs.barAtTop ? 42 : tips.height - height - 42
                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    width: tipText.implicitWidth + 20
                    height: tipText.implicitHeight + 14
                    radius: Shape.chip
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96)
                    border.width: 1
                    border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                          Colors.outline.b, 0.35)

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.40)
                        shadowBlur: 0.6
                        shadowVerticalOffset: 3
                    }

                    Text {
                        id: tipText
                        anchors.centerIn: parent
                        text: tips.text
                        color: Colors.fgDim
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        lineHeight: 1.25
                    }
                }
            }
        }
    }
}
