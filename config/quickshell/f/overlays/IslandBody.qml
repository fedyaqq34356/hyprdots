import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: body

    property string kind: ""
    property color tint: Colors.accent
    property bool wide: false
    property string notifSummary: ""
    property string notifBody: ""
    property string notifApp: ""
    property var demo: ({})

    readonly property string glyph: {
        switch (body.kind) {
        case "alarm":  return "󰀠";
        case "record": return "󰑊";
        case "osd":    return Feedback.icon !== "" ? Feedback.icon : "󰕾";
        case "notif":  return "󰂚";
        case "timer":  return "󰔛";
        case "media":  return "󰎈";
        case "clock":  return "󰥔";
        case "bt":     return Bt.connectedCount > 0 ? Bt.icon(Bt.primary) : "󰂲";
        case "peri":   return Peripherals.glyph !== "" ? Peripherals.glyph : "󰍽";
        case "power":  return Power.glyph;
        case "net":    return Network.glyph;
        case "vpn":    return Vpn.up ? "󰦝" : "󰦞";
        case "print":  return "󰐪";
        }
        return "";
    }

    readonly property string headline: {
        switch (body.kind) {
        case "alarm":  return I18n.t("isle.alarm");
        case "record": return Recorder.clock;
        case "osd":    return Feedback.label !== "" ? Feedback.label
                                                    : Feedback.percent(Feedback.value);
        case "notif":  return body.notifSummary;
        case "timer":  return Timers.soonest ? Timers.clock(Timers.left(Timers.soonest))
                                             : "";
        case "media":  return Media.title !== "" ? Media.title : Media.label;
        case "clock":  return Qt.formatDateTime(clockTick.date, "HH:mm");
        case "bt":     return Bt.connectedCount > 0 ? Bt.label(Bt.primary)
                                                    : I18n.t("isle.bt.gone");
        case "peri":   return Peripherals.model !== "" ? Peripherals.model
                                                       : I18n.t("isle.src.peri");
        case "power":  return Power.percent + "%";
        case "net":    return Network.connected ? Network.ssid
                                                : I18n.t("isle.net.gone");
        case "vpn":    return Vpn.up ? Vpn.iface : I18n.t("isle.vpn.off");
        case "print":  return I18n.t("isle.src.print");
        }
        return "";
    }

    readonly property real fraction: {
        switch (body.kind) {
        case "osd":    return Feedback.showBar ? Feedback.value : -1;
        case "timer":  return Timers.soonest ? Timers.progress(Timers.soonest) : -1;
        case "media":  return Media.hasPosition ? Media.progress : -1;
        case "power":  return Power.fraction;
        case "peri":   return Peripherals.percent / 100;
        }
        return -1;
    }

    SystemClock { id: clockTick; precision: SystemClock.Minutes }

    property bool alive: false

    onWideChanged: {
        if (body.wide) {
            unmount.stop();
            body.alive = true;
        } else {
            unmount.restart();
        }
    }

    Timer {
        id: unmount
        interval: 360
        onTriggered: body.alive = false
    }

    Loader {
        id: card

        anchors.fill: parent
        active: body.alive
        asynchronous: true

        opacity: body.wide ? 1 : 0
        scale: body.wide ? 1 : 0.94
        visible: opacity > 0.01

        readonly property real haze: (1 - card.opacity) * 0.5

        layer.enabled: card.haze > 0.004
        layer.smooth: true
        layer.effect: MultiEffect {
            blurEnabled: true
            blurMax: 24
            blur: card.haze
        }

        transform: Translate {
            y: body.wide ? 0 : 7
            Behavior on y {
                SequentialAnimation {
                    PauseAnimation {
                        duration: body.wide ? Motion.isleRevealDelay : 0
                    }
                    NumberAnimation {
                        duration: body.wide ? Motion.isleRevealMs : Motion.isleHideMs
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.isleContent
                    }
                }
            }
        }

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation {
                    duration: body.wide ? Motion.isleRevealDelay : 0
                }
                NumberAnimation {
                    duration: body.wide ? Motion.isleRevealMs : Motion.isleHideMs
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.isleContent
                }
            }
        }
        Behavior on scale {
            SequentialAnimation {
                PauseAnimation {
                    duration: body.wide ? Motion.isleRevealDelay : 0
                }
                NumberAnimation {
                    duration: body.wide ? Motion.isleRevealMs : Motion.isleHideMs
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.isleContent
                }
            }
        }

        sourceComponent: {
            switch (body.kind) {
            case "media":  return mediaCard;
            case "osd":    return osdCard;
            case "timer":  return timerCard;
            case "alarm":  return alarmCard;
            case "record": return recordCard;
            case "notif":  return notifCard;
            case "bt":     return btCard;
            case "peri":   return periCard;
            case "power":  return powerCard;
            case "net":    return netCard;
            case "vpn":    return vpnCard;
            case "print":  return printCard;
            }
            return null;
        }
    }

    component IslandKey: Item {
        id: key

        property string glyph: ""
        property int size: 22
        property color ink: Colors.fg
        signal activated()

        width: key.size + 18
        height: key.size + 18
        opacity: key.enabled ? 1 : 0.3

        Rectangle {
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: width / 2
            antialiasing: true
            color: Colors.alpha(key.ink, keyTap.pressed ? 0.16 : 0.08)
            opacity: keyHover.hovered ? 1 : 0
            scale: keyHover.hovered ? 1 : 0.6
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
            Behavior on scale { Spring {} }
        }

        Text {
            anchors.centerIn: parent
            text: key.glyph
            color: key.ink
            font.family: Fonts.glyph
            font.pixelSize: key.size
            scale: keyTap.pressed ? 0.8 : 1
            Behavior on scale { Spring {} }
        }

        HoverHandler { id: keyHover; cursorShape: Qt.PointingHandCursor }
        TapHandler {
            id: keyTap
            onTapped: key.activated()
        }
    }

    Component {
        id: mediaCard

        Item {
            id: mc

            Rectangle {
                anchors.fill: parent
                anchors.margins: -12
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: Colors.alpha(body.tint, 0.20) }
                    GradientStop { position: 0.55; color: Colors.alpha(body.tint, 0.04) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Item {
                id: head
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 56

                Image {
                    anchors.centerIn: art
                    width: art.width * 1.6
                    height: art.height * 1.6
                    visible: Media.art !== ""
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 48
                    opacity: 0.55 * art.opacity

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blurMax: 40
                        blur: 1.0
                        saturation: 0.5
                    }
                }

                ClippingRectangle {
                    id: art
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 56
                    height: 56
                    radius: 14
                    color: Colors.alpha(body.tint, 0.25)
                    scale: Media.playing ? 1 : 0.88
                    Behavior on scale { Spring {} }

                    Image {
                        id: artImg
                        anchors.fill: parent
                        visible: Media.art !== ""
                        source: Media.art
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        sourceSize.width: 160
                    }

                    Vinyl {
                        anchors.fill: parent
                        visible: Media.art === ""
                        spinning: Media.playing
                    }

                    Rectangle {
                        id: artFlash
                        anchors.fill: parent
                        color: Colors.fg
                        opacity: 0
                    }

                    Connections {
                        target: Media
                        function onArtChanged() { artFlashRun.restart(); }
                    }

                    NumberAnimation {
                        id: artFlashRun
                        target: artFlash; property: "opacity"
                        from: 0.35; to: 0; duration: 520
                        easing.type: Easing.OutCubic
                    }
                }

                Rectangle {
                    anchors.fill: art
                    scale: art.scale
                    radius: art.radius
                    color: "transparent"
                    border.width: 1
                    border.color: Colors.alpha(Colors.fg, 0.10)
                    antialiasing: true
                }

                Column {
                    anchors.left: art.right
                    anchors.leftMargin: 12
                    anchors.right: eq.left
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Marquee {
                        width: parent.width
                        text: Media.title !== "" ? Media.title : Media.label
                        color: Colors.fg
                        family: Fonts.display
                        pixelSize: 15
                        weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        text: Media.artist !== "" ? Media.artist : Media.source
                        color: Colors.alpha(Colors.fg, 0.55)
                        font.family: Fonts.display
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }

                IslandBars {
                    id: eq
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    width: 30
                    height: 24
                    count: 6
                    tint: body.tint
                    live: mc.visible
                }
            }

            Item {
                id: seek
                anchors.top: head.bottom
                anchors.topMargin: 12
                anchors.left: parent.left
                anchors.right: parent.right
                height: 16
                visible: Media.hasPosition

                property real drag: -1
                readonly property real at: seek.drag >= 0
                    ? seek.drag : Math.max(0, Math.min(1, Media.progress))
                readonly property real len: Media.player ? Media.player.length : 0

                Text {
                    id: atText
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    width: 34
                    text: Media.clock(seek.at * seek.len)
                    color: Colors.alpha(Colors.fg, 0.5)
                    font.family: Fonts.mono
                    font.pixelSize: 10
                }

                Text {
                    id: endText
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 38
                    horizontalAlignment: Text.AlignRight
                    text: "-" + Media.clock(Math.max(0, (1 - seek.at) * seek.len))
                    color: Colors.alpha(Colors.fg, 0.5)
                    font.family: Fonts.mono
                    font.pixelSize: 10
                }

                Item {
                    id: track
                    anchors.left: atText.right
                    anchors.right: endText.left
                    anchors.leftMargin: 6
                    anchors.rightMargin: 6
                    anchors.verticalCenter: parent.verticalCenter

                    readonly property bool hot: trackHover.hovered || seek.drag >= 0
                    height: track.hot ? 8 : 5
                    Behavior on height { Spring {} }

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Colors.alpha(Colors.fg, 0.16)
                    }

                    Rectangle {
                        width: Math.max(parent.height, parent.width * seek.at)
                        height: parent.height
                        radius: height / 2
                        antialiasing: true
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: body.tint }
                            GradientStop { position: 1.0; color: Qt.lighter(body.tint, 1.5) }
                        }
                        Behavior on width {
                            enabled: seek.drag < 0
                            NumberAnimation { duration: Motion.base }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: false

                        function frac(mx) {
                            return Math.max(0, Math.min(1, (mx - 8) / track.width));
                        }

                        onPressed: mouse => seek.drag = frac(mouse.x)
                        onPositionChanged: mouse => { if (pressed) seek.drag = frac(mouse.x); }
                        onReleased: mouse => {
                            Media.seekTo(frac(mouse.x));
                            seek.drag = -1;
                        }
                        onCanceled: seek.drag = -1
                    }

                    HoverHandler { id: trackHover }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: -6
                spacing: 26

                IslandKey {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "󰒮"
                    size: 22
                    enabled: Media.canPrev
                    onActivated: Media.previous()
                }

                Item {
                    width: 48
                    height: 48
                    anchors.verticalCenter: parent.verticalCenter

                    IslandKey {
                        anchors.centerIn: parent
                        glyph: "󰏤"
                        size: 30
                        enabled: Media.canToggle
                        opacity: Media.playing ? 1 : 0
                        scale: Media.playing ? 1 : 0.4
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                        Behavior on scale { Spring {} }
                        onActivated: Media.toggle()
                    }

                    IslandKey {
                        anchors.centerIn: parent
                        glyph: "󰐊"
                        size: 30
                        enabled: Media.canToggle
                        opacity: Media.playing ? 0 : 1
                        scale: Media.playing ? 0.4 : 1
                        visible: opacity > 0.01
                        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                        Behavior on scale { Spring {} }
                        onActivated: Media.toggle()
                    }
                }

                IslandKey {
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: "󰒭"
                    size: 22
                    enabled: Media.canNext
                    onActivated: Media.next()
                }
            }
        }
    }

    component RoundKey: Item {
        id: rk

        property string glyph: ""
        property color tint: Colors.accent
        property int size: 40
        signal activated()

        width: rk.size
        height: rk.size

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            antialiasing: true
            color: Colors.alpha(rk.tint, rkHover.hovered ? 0.36 : 0.24)
            scale: rkTap.pressed ? 0.86 : (rkHover.hovered ? 1.06 : 1)
            Behavior on color { ColorAnimation { duration: Motion.fast } }
            Behavior on scale { Spring {} }

            Text {
                anchors.centerIn: parent
                text: rk.glyph
                color: Qt.lighter(rk.tint, 1.15)
                font.family: Fonts.glyph
                font.pixelSize: Math.round(rk.size * 0.44)
            }
        }

        HoverHandler { id: rkHover; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: rkTap; onTapped: rk.activated() }
    }

    component StatusLine: Row {
        id: sl
        property string text: ""
        property color tint: Colors.accent
        property bool ok: true
        spacing: 5

        IslandCheck {
            anchors.verticalCenter: parent.verticalCenter
            visible: sl.ok
            width: 13
            height: 13
            tint: sl.tint
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: sl.text
            color: sl.tint
            font.family: Fonts.display
            font.pixelSize: 12
            font.weight: Font.DemiBold
        }
    }

    Component {
        id: osdCard

        Item {
            IslandTile {
                id: osdTile
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                size: 46
                glyph: body.glyph
                tint: body.tint
            }

            Column {
                anchors.left: osdTile.right
                anchors.leftMargin: 16
                anchors.right: osdValue.left
                anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                Text {
                    text: Feedback.label !== ""
                          && Feedback.label !== Feedback.percent(Feedback.value)
                          ? Feedback.label
                          : Feedback.channel === "source" ? I18n.t("isle.osd.mic")
                          : Feedback.channel === "light" ? I18n.t("isle.osd.light")
                          : I18n.t("audio.volume2")
                    color: Colors.alpha(Colors.fg, 0.6)
                    font.family: Fonts.display
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Item {
                    id: slide
                    width: parent.width
                    height: 10
                    visible: Feedback.showBar

                    property real v: Math.max(0, Math.min(1, Feedback.value))
                    property real shown: 0
                    Component.onCompleted: slide.shown = slide.v
                    onVChanged: slide.shown = slide.v
                    Behavior on shown {
                        SpringAnimation { spring: 3.2; damping: 0.32; mass: 0.8; epsilon: 0.001 }
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Colors.alpha(Colors.fg, 0.12)
                    }

                    RectangularShadow {
                        anchors.fill: fillBar
                        radius: fillBar.radius
                        blur: 12
                        color: Colors.alpha(body.tint, 0.6)
                    }

                    Rectangle {
                        id: fillBar
                        width: Math.max(height, parent.width * slide.shown)
                        height: parent.height
                        radius: height / 2
                        antialiasing: true
                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Qt.darker(body.tint, 1.2) }
                            GradientStop { position: 1.0; color: Qt.lighter(body.tint, 1.3) }
                        }

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 1
                            height: parent.height / 2
                            radius: height / 2
                            color: Qt.rgba(1, 1, 1, 0.28)
                        }
                    }
                }
            }

            Text {
                id: osdValue
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: osdEm.width + 2
                horizontalAlignment: Text.AlignRight
                text: Feedback.showBar ? Feedback.percent(Feedback.value) : ""
                color: Colors.fg
                font.family: Fonts.display
                font.pixelSize: 26
                font.weight: Font.DemiBold

                TextMetrics {
                    id: osdEm
                    font: osdValue.font
                    text: "100%"
                }
            }
        }
    }

    Component {
        id: timerCard

        Item {
            id: tc
            readonly property var t: Timers.soonest

            IslandGauge {
                id: dial
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 60
                height: 60
                value: tc.t ? Timers.progress(tc.t) : 0
                tint: body.tint
                showPct: false
                glyph: "󰔛"
                fillMs: 700
            }

            Column {
                anchors.left: dial.right
                anchors.leftMargin: 14
                anchors.right: timerActs.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    width: parent.width
                    text: tc.t && tc.t.label ? tc.t.label : I18n.t("isle.src.timer")
                    color: Colors.alpha(Colors.fg, 0.55)
                    font.family: Fonts.display
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }

                RollText {
                    text: tc.t ? Timers.clock(Timers.left(tc.t)) : ""
                    color: Qt.lighter(body.tint, 1.1)
                    family: Fonts.display
                    pixelSize: 28
                    weight: Font.DemiBold
                    rollDuration: 300
                }
            }

            Row {
                id: timerActs
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                RoundKey {
                    glyph: tc.t && tc.t.running ? "󰏤" : "󰐊"
                    tint: body.tint
                    onActivated: if (tc.t) Timers.toggle(tc.t.id)
                }

                RoundKey {
                    glyph: "󰅖"
                    tint: Colors.fgDim
                    onActivated: if (tc.t) Timers.cancel(tc.t.id)
                }
            }
        }
    }

    Component {
        id: alarmCard

        Item {
            SystemClock { id: alarmNow; precision: SystemClock.Minutes }

            IslandTile {
                id: bell
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                size: 50
                round: true
                glyph: "󰀠"
                tint: Colors.bad
                sonar: true

                transform: Rotation {
                    origin.x: bell.width / 2
                    origin.y: 6
                    angle: 0
                    SequentialAnimation on angle {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { to: 16;  duration: 140; easing.type: Easing.InOutSine }
                        NumberAnimation { to: -16; duration: 280; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 10;  duration: 220; easing.type: Easing.InOutSine }
                        NumberAnimation { to: -6;  duration: 180; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0;   duration: 140; easing.type: Easing.InOutSine }
                        PauseAnimation  { duration: 700 }
                    }
                }
            }

            Column {
                anchors.left: bell.right
                anchors.leftMargin: 16
                anchors.right: alarmActs.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    width: parent.width
                    text: I18n.t("isle.alarm")
                    color: Colors.bad
                    font.family: Fonts.display
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    text: Qt.formatDateTime(alarmNow.date, "HH:mm")
                    color: Colors.fg
                    font.family: Fonts.display
                    font.pixelSize: 28
                    font.weight: Font.DemiBold
                }
            }

            Row {
                id: alarmActs
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                RoundKey {
                    glyph: "󰒲"
                    tint: Colors.warn
                    onActivated: {
                        const t = Timers.items.find(x => x.ringing);
                        if (t) Timers.snooze(t.id, 300);
                    }
                }

                RoundKey {
                    glyph: "󰅖"
                    tint: Colors.bad
                    onActivated: Timers.dismissAll()
                }
            }
        }
    }

    Component {
        id: recordCard

        Item {
            Item {
                id: recDot
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                width: 40
                height: 40

                Repeater {
                    model: 2
                    Rectangle {
                        id: halo
                        required property int index
                        anchors.centerIn: parent
                        width: 18; height: 18
                        radius: 9
                        color: Colors.alpha(Colors.bad, 0.5)
                        opacity: 0
                        SequentialAnimation {
                            running: true
                            loops: Animation.Infinite
                            PauseAnimation { duration: halo.index * 700 }
                            ParallelAnimation {
                                NumberAnimation { target: halo; property: "scale"; from: 1; to: 2.4; duration: 1400; easing.type: Easing.OutCubic }
                                NumberAnimation { target: halo; property: "opacity"; from: 0.8; to: 0; duration: 1400 }
                            }
                            PauseAnimation { duration: (1 - halo.index) * 700 }
                        }
                    }
                }

                RectangularShadow {
                    anchors.fill: core
                    radius: core.radius
                    blur: 10
                    color: Colors.alpha(Colors.bad, 0.8)
                }

                Rectangle {
                    id: core
                    anchors.centerIn: parent
                    width: 18; height: 18
                    radius: 9
                    antialiasing: true
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.lighter(Colors.bad, 1.3) }
                        GradientStop { position: 1.0; color: Qt.darker(Colors.bad, 1.3) }
                    }
                    SequentialAnimation on scale {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.82; duration: 700; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutSine }
                    }
                }
            }

            Column {
                anchors.left: recDot.right
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    text: I18n.t("isle.src.record")
                    color: Colors.bad
                    font.family: Fonts.display
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                RollText {
                    text: Recorder.clock
                    color: Colors.fg
                    family: Fonts.display
                    pixelSize: 26
                    weight: Font.DemiBold
                }
            }

            RoundKey {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                glyph: "󰓛"
                tint: Colors.bad
                onActivated: Recorder.stop()
            }
        }
    }

    Component {
        id: notifCard

        Item {
            Rectangle {
                id: mark
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 42
                height: 42
                radius: 12
                antialiasing: true
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.lighter(body.tint, 1.15) }
                    GradientStop { position: 1.0; color: Qt.darker(body.tint, 1.45) }
                }

                scale: 0.5
                Component.onCompleted: mark.scale = 1
                Behavior on scale { Spring {} }

                Text {
                    anchors.centerIn: parent
                    text: NotifHistory.appLetter(body.notifApp)
                    color: "white"
                    font.family: Fonts.display
                    font.pixelSize: 19
                    font.weight: Font.Bold
                }
            }

            Column {
                anchors.left: mark.right
                anchors.leftMargin: 12
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Item {
                    width: parent.width
                    height: appName.implicitHeight

                    Text {
                        id: appName
                        anchors.left: parent.left
                        anchors.right: nowText.left
                        anchors.rightMargin: 8
                        text: body.notifApp
                        color: Colors.alpha(Colors.fg, 0.45)
                        font.family: Fonts.display
                        font.pixelSize: 11
                        font.capitalization: Font.AllUppercase
                        font.letterSpacing: 0.4
                        elide: Text.ElideRight
                    }

                    Text {
                        id: nowText
                        anchors.right: parent.right
                        text: I18n.t("isle.now") === "isle.now" ? "now" : I18n.t("isle.now")
                        color: Colors.alpha(Colors.fg, 0.4)
                        font.family: Fonts.display
                        font.pixelSize: 11
                    }
                }

                Text {
                    width: parent.width
                    text: body.notifSummary
                    color: Colors.fg
                    font.family: Fonts.display
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: body.notifBody !== ""
                    text: body.notifBody
                    color: Colors.alpha(Colors.fg, 0.68)
                    font.family: Fonts.display
                    font.pixelSize: 12
                    lineHeight: 1.15
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
            }
        }
    }

    Component {
        id: btCard

        Item {
            id: bc

            readonly property var d: body.demo && body.demo.bt ? body.demo.bt : null
            readonly property var dev: Bt.primary
            readonly property bool gone: bc.d ? !bc.d.on : Bt.connectedCount <= 0
            readonly property string name: bc.d ? bc.d.name : body.headline
            readonly property real charge: bc.d ? bc.d.battery
                : (bc.dev && bc.dev.batteryAvailable ? bc.dev.battery : -1)
            readonly property color hue: bc.gone ? Colors.fgDim : body.tint

            IslandTile {
                id: btTile
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                size: 52
                round: true
                glyph: bc.gone ? "󰂲" : (bc.d ? "󰋋" : body.glyph)
                tint: bc.hue
                sonar: !bc.gone
                implode: bc.gone
                sparks: !bc.gone

                transform: Translate {
                    id: shake
                    SequentialAnimation on x {
                        running: bc.gone
                        NumberAnimation { to: -4; duration: 50 }
                        NumberAnimation { to: 4;  duration: 70 }
                        NumberAnimation { to: -3; duration: 60 }
                        NumberAnimation { to: 2;  duration: 60 }
                        NumberAnimation { to: 0;  duration: 60 }
                    }
                }
            }

            Column {
                anchors.left: btTile.right
                anchors.leftMargin: 16
                anchors.right: btGauge.visible ? btGauge.left : parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StatusLine {
                    text: bc.gone ? I18n.t("isle.bt.gone") : I18n.t("isle.bt.on")
                    tint: bc.gone ? Colors.alpha(Colors.fg, 0.5) : bc.hue
                    ok: !bc.gone
                }

                Marquee {
                    width: parent.width
                    text: bc.name
                    color: Colors.fg
                    family: Fonts.display
                    pixelSize: 16
                    weight: Font.DemiBold
                }
            }

            IslandGauge {
                id: btGauge
                anchors.right: parent.right
                anchors.rightMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 56
                height: 56
                visible: bc.charge >= 0 && !bc.gone
                value: bc.charge
                tint: bc.charge <= 0.2 ? Colors.bad : Colors.good
                glyph: "󰋋"
            }
        }
    }

    Component {
        id: periCard

        Item {
            id: pc
            readonly property var d: body.demo && body.demo.peri ? body.demo.peri : null
            readonly property int charge: pc.d ? pc.d.pct : Peripherals.percent
            readonly property bool bad: pc.d ? pc.d.pct <= 10 : Peripherals.critical

            IslandBattery {
                id: cell
                anchors.left: parent.left
                anchors.leftMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                width: 66
                height: 32
                value: pc.charge / 100
                tint: pc.bad ? Colors.bad : Colors.warn
                lowAt: 0.3
                glyph: body.glyph
            }

            Column {
                anchors.left: cell.right
                anchors.leftMargin: 16
                anchors.right: pct.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: I18n.t(pc.bad ? "isle.peri.dying" : "isle.peri.low")
                    color: pc.bad ? Colors.bad : Colors.warn
                    font.family: Fonts.display
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    text: pc.d ? pc.d.model : body.headline
                    color: Colors.fg
                    font.family: Fonts.display
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            property real counted: 0
            Component.onCompleted: pc.counted = pc.charge
            onChargeChanged: pc.counted = pc.charge
            Behavior on counted { NumberAnimation { duration: 1000; easing.type: Easing.OutCubic } }

            Text {
                id: pct
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(pc.counted) + "%"
                color: pc.bad ? Colors.bad : Colors.warn
                font.family: Fonts.display
                font.pixelSize: 28
                font.weight: Font.DemiBold
            }
        }
    }

    Component {
        id: powerCard

        Item {
            id: pw
            readonly property var d: body.demo && body.demo.power ? body.demo.power : null
            readonly property int pct: pw.d ? pw.d.pct : Power.percent
            readonly property bool charging: pw.d ? pw.d.charging : Power.charging
            readonly property bool low: !pw.charging && pw.pct <= 15
            readonly property color hue: pw.charging ? Colors.good
                                       : pw.low ? Colors.bad : body.tint

            property real counted: 0
            Component.onCompleted: pw.counted = pw.pct
            onPctChanged: pw.counted = pw.pct
            Behavior on counted { NumberAnimation { duration: 1200; easing.type: Easing.OutCubic } }

            IslandBattery {
                id: cell
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                width: 74
                height: 36
                value: pw.pct / 100
                charging: pw.charging
                tint: pw.hue
                lowAt: 0.15
            }

            IslandBurst {
                x: cell.x + (cell.width - 4) / 2
                y: cell.y + cell.height / 2
                visible: pw.charging
                tint: Colors.good
                reach: 46
                delay: 380
            }

            Column {
                anchors.left: cell.right
                anchors.leftMargin: 16
                anchors.right: big.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Text {
                    width: parent.width
                    text: I18n.t(pw.charging ? "isle.power.on"
                               : pw.low ? "isle.power.low" : "isle.power.off")
                    color: pw.hue
                    font.family: Fonts.display
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Text {
                    width: parent.width
                    visible: Power.timeLabel !== "" && !pw.d
                    text: I18n.t(pw.charging ? "isle.power.till"
                                             : "isle.power.left")
                          + Power.timeLabel
                    color: Colors.alpha(Colors.fg, 0.55)
                    font.family: Fonts.display
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            Text {
                id: big
                anchors.right: parent.right
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(pw.counted) + "%"
                color: Colors.fg
                font.family: Fonts.display
                font.pixelSize: 28
                font.weight: Font.DemiBold
            }
        }
    }

    Component {
        id: netCard

        Item {
            Item {
                id: fanBox
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 52
                height: 52

                RectangularShadow {
                    anchors.centerIn: parent
                    width: 34; height: 34
                    radius: 17
                    blur: 22
                    color: Colors.alpha(body.tint, Network.connected ? 0.45 : 0)
                }

                IslandWifi {
                    anchors.centerIn: parent
                    width: 46
                    height: 38
                    on: Network.connected
                    strength: Network.strength / 100
                    tint: body.tint
                }
            }

            Column {
                anchors.left: fanBox.right
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StatusLine {
                    text: Network.connected
                          ? (Network.linkRate !== "" ? Network.linkRate
                                                     : Network.strength + "%")
                          : I18n.t("isle.net.searching")
                    tint: Network.connected ? body.tint : Colors.alpha(Colors.fg, 0.5)
                    ok: Network.connected
                }

                Text {
                    width: parent.width
                    text: body.headline
                    color: Colors.fg
                    font.family: Fonts.display
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }
        }
    }

    Component {
        id: vpnCard

        Item {
            IslandTile {
                id: shield
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                size: 50
                glyph: Vpn.up ? "󰦝" : "󰦞"
                tint: Vpn.up ? body.tint : Colors.fgDim
                sonar: Vpn.up
                implode: !Vpn.up
                sparks: Vpn.up
            }

            Column {
                anchors.left: shield.right
                anchors.leftMargin: 16
                anchors.right: country.visible ? country.left : parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StatusLine {
                    text: I18n.t(Vpn.up ? "isle.vpn.on" : "isle.vpn.off")
                    tint: Vpn.up ? body.tint : Colors.alpha(Colors.fg, 0.5)
                    ok: Vpn.up
                }

                Text {
                    width: parent.width
                    visible: Vpn.up
                    text: Vpn.iface + (Vpn.exitIp !== "" ? "  ·  " + Vpn.exitIp : "")
                    color: Colors.fg
                    font.family: Fonts.display
                    font.pixelSize: 15
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                id: country
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                visible: Vpn.up && Vpn.exitCountry !== ""
                width: cText.implicitWidth + 20
                height: 28
                radius: 14
                color: Colors.alpha(body.tint, 0.2)
                border.width: 1
                border.color: Colors.alpha(body.tint, 0.4)
                scale: 0.4
                Component.onCompleted: scale = 1
                Behavior on scale { Spring {} }

                Text {
                    id: cText
                    anchors.centerIn: parent
                    text: Vpn.exitCountry
                    color: Qt.lighter(body.tint, 1.2)
                    font.family: Fonts.display
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }
            }
        }
    }

    Component {
        id: printCard

        Item {
            id: prc
            readonly property int queue: Printing.jobs.length

            IslandTile {
                id: box
                anchors.left: parent.left
                anchors.leftMargin: 2
                anchors.verticalCenter: parent.verticalCenter
                size: 48
                glyph: "󰐪"
                tint: body.tint
            }

            Rectangle {
                id: sheet
                x: box.x + box.width / 2 - width / 2
                width: 22
                height: 4
                radius: 2
                antialiasing: true
                color: "white"
                y: box.y + box.height - 10
                opacity: 0

                SequentialAnimation {
                    running: prc.queue > 0
                    loops: Animation.Infinite
                    ParallelAnimation {
                        NumberAnimation {
                            target: sheet; property: "y"
                            from: box.y + box.height - 12; to: box.y + box.height + 4
                            duration: 900; easing.type: Easing.OutCubic
                        }
                        SequentialAnimation {
                            NumberAnimation { target: sheet; property: "opacity"; from: 0; to: 0.95; duration: 200 }
                            NumberAnimation { target: sheet; property: "opacity"; to: 0; duration: 620 }
                        }
                    }
                    PauseAnimation { duration: 320 }
                }
            }

            Column {
                anchors.left: box.right
                anchors.leftMargin: 16
                anchors.right: count.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                StatusLine {
                    text: prc.queue > 0 ? I18n.t("isle.print.queue")
                                        : I18n.t("isle.print.done")
                    tint: body.tint
                    ok: prc.queue === 0
                }

                Text {
                    width: parent.width
                    text: Printing.selected !== "" ? Printing.selected
                                                   : I18n.t("isle.src.print")
                    color: Colors.fg
                    font.family: Fonts.display
                    font.pixelSize: 16
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }
            }

            RollText {
                id: count
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                visible: prc.queue > 0
                text: visible ? String(prc.queue) : ""
                color: body.tint
                family: Fonts.display
                pixelSize: 26
                weight: Font.DemiBold
            }
        }
    }
}
