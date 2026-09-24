import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: pill

    property color tint: Colors.accent
    property string kind: ""
    property string flashKind: ""
    property string flashGlyph: ""
    property string flashText: ""
    property real flashFraction: -1
    property string notifApp: ""
    property bool miniMedia: false
    property color mediaTint: Colors.accent
    property real beat: 0
    property int stacked: 0
    property real maxWidth: 0

    readonly property bool flashing: pill.flashKind !== ""
    readonly property bool deskFlash: pill.flashKind === "desk"
    readonly property bool osdFlash: pill.flashKind === "osd"
    readonly property bool notifFlash: pill.flashKind === "notif"

    readonly property int inner: Math.max(12, pill.height - 8)

    implicitHeight: height

    SystemClock { id: tick; precision: SystemClock.Minutes }

    TextMetrics {
        id: clockEm
        font.family: Fonts.mono
        font.pixelSize: 13
        font.weight: Font.DemiBold
        text: "00:00"
    }

    TextMetrics {
        id: textEm
        font.family: Fonts.display
        font.pixelSize: 13
        font.weight: Font.DemiBold
        text: pill.flashText
    }

    TextMetrics {
        id: pctEm
        font.family: Fonts.mono
        font.pixelSize: 12
        font.weight: Font.DemiBold
        text: "100%"
    }

    readonly property bool keysFlash: pill.flashKind === "keys"
    readonly property var langs: ({
        EN: { flag: "🇺🇸", name: "English" },
        US: { flag: "🇺🇸", name: "English" },
        RU: { flag: "🇷🇺", name: "Русский" },
        UA: { flag: "🇺🇦", name: "Українська" },
        DE: { flag: "🇩🇪", name: "Deutsch" },
        FR: { flag: "🇫🇷", name: "Français" },
        PL: { flag: "🇵🇱", name: "Polski" }
    })
    readonly property var lang: pill.langs[pill.flashText]
        || { flag: "", name: pill.flashText }

    TextMetrics {
        id: langEm
        font.family: Fonts.display
        font.pixelSize: 12
        font.weight: Font.Bold
        font.letterSpacing: 1.2
        text: "WW"
    }

    readonly property var keyCodes: Keyboard.codes.length > 0 ? Keyboard.codes
                                                              : [pill.flashText]
    readonly property int keyGap: 14
    readonly property real keysW:
        pill.keyCodes.length * langEm.width + (pill.keyCodes.length - 1) * pill.keyGap + 4

    readonly property int meterW: 58
    readonly property bool hasMeter: pill.osdFlash && pill.flashFraction >= 0

    readonly property real capText: 300
    readonly property real textW: Math.min(textEm.width + 2, pill.capText)

    readonly property var deskList:
        Hyprland.workspaces ? Hyprland.workspaces.values : []
    readonly property int deskCount: pill.deskList.length
    readonly property int dotW: 6
    readonly property int dotGap: 12
    readonly property real desksW: pill.deskCount > 0
        ? pill.deskCount * pill.dotW + (pill.deskCount - 1) * pill.dotGap
        : 0

    readonly property int deskIndex: {
        const f = Hyprland.focusedWorkspace;
        if (!f)
            return 0;
        for (let i = 0; i < pill.deskList.length; i++) {
            if (pill.deskList[i] && pill.deskList[i].id === f.id)
                return i;
        }
        return 0;
    }

    readonly property real markW: pill.inner

    readonly property int split: 22
    readonly property real pctW: pctEm.width * 1.06

    readonly property bool pctOnly:
        pill.osdFlash && pill.flashFraction >= 0
        && pill.flashText === Feedback.percent(pill.flashFraction)

    readonly property bool hasStack: pill.flashing && pill.stacked > 0
    readonly property real stackW:
        pill.hasStack ? Math.round(pill.inner * 0.86) : 0

    readonly property real eventW: {
        if (!pill.flashing)
            return 0;
        let w;
        if (pill.deskFlash) {
            w = pill.desksW + 20;
        } else {
            w = pill.keysFlash ? 0 : pill.markW + pill.split;
            if (pill.keysFlash)
                w += pill.keysW;
            else if (!pill.pctOnly)
                w += pill.textW;
            if (pill.hasMeter)
                w += (pill.pctOnly ? 0 : 10) + pill.meterW + 10 + pill.pctW;
        }
        if (pill.hasStack)
            w += 8 + pill.stackW;
        return w;
    }

    readonly property int sideRoom:
        pill.miniMedia ? Math.round(pill.inner + 14) : 0

    readonly property real coreW: Math.max(clockEm.width, pill.eventW)

    implicitWidth: pill.coreW + pill.sideRoom * 2 + 24

    readonly property real textRoom: {
        if (pill.maxWidth <= 0)
            return pill.textW;
        let room = pill.maxWidth - 24 - pill.sideRoom * 2 - pill.markW - pill.split;
        if (pill.hasMeter && !pill.pctOnly)
            room -= 10 + pill.meterW + 10 + pill.pctW;
        if (pill.hasStack)
            room -= 8 + pill.stackW;
        return Math.max(16, Math.min(pill.textW, room));
    }

    SequentialAnimation {
        id: pop
        NumberAnimation {
            target: mark; property: "scale"
            to: 1.2; duration: 110
            easing.type: Easing.OutBack; easing.overshoot: 2.4
        }
        NumberAnimation {
            target: mark; property: "scale"
            to: 1.0; duration: 240
            easing.type: Easing.OutCubic
        }
    }

    onFlashTextChanged: if (pill.flashing && !pill.osdFlash) pop.restart()
    onFlashKindChanged: {
        if (pill.notifFlash)
            sweep.restart();
    }

    Connections {
        target: Feedback
        function onPulseChanged() { waveMark.ripple(); }
    }

    Item {
        anchors.fill: parent

        Rectangle {
            id: fill

            readonly property real frac:
                Math.max(0, Math.min(1, pill.flashFraction))

            x: -(pill.maxWidth - pill.width) / 2
            width: Math.max(0, pill.maxWidth * fill.frac)
            height: pill.height
            anchors.verticalCenter: parent.verticalCenter
            radius: 0

            opacity: pill.osdFlash && pill.flashFraction >= 0
                     && !IslandConfig.s("rim") ? 1 : 0
            visible: opacity > 0.01

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Colors.alpha(pill.tint, 0.34) }
                GradientStop { position: 1.0; color: Colors.alpha(pill.tint, 0.15) }
            }

            Rectangle {
                anchors.right: parent.right
                width: 2
                height: parent.height
                color: Colors.alpha(pill.tint, 0.62)
            }

            Behavior on width {
                NumberAnimation {
                    duration: Motion.isleContentMs
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.isleContent
                }
            }
            Behavior on opacity {
                NumberAnimation { duration: Motion.isleRevealMs }
            }
        }

        Rectangle {
            id: sweep

            readonly property real span: Math.max(60, pill.maxWidth * 0.55)

            width: sweep.span
            height: pill.height
            anchors.verticalCenter: parent.verticalCenter
            opacity: 0
            visible: opacity > 0.01

            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Colors.alpha(pill.tint, 0.3) }
                GradientStop { position: 1.0; color: "transparent" }
            }

            function restart() { run.restart(); }

            SequentialAnimation {
                id: run
                ParallelAnimation {
                    NumberAnimation {
                        target: sweep; property: "x"
                        from: -(pill.maxWidth - pill.width) / 2 - sweep.span
                        to: (pill.maxWidth + pill.width) / 2
                        duration: 620
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.isleContent
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: sweep; property: "opacity"
                            to: 1; duration: 160
                        }
                        PauseAnimation { duration: 180 }
                        NumberAnimation {
                            target: sweep; property: "opacity"
                            to: 0; duration: 280
                        }
                    }
                }
            }
        }

        Item {
            id: middle
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            width: pill.coreW
            height: pill.height

            Behavior on width {
                NumberAnimation {
                    duration: Motion.isleContentMs
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.isleContent
                }
            }

            RollText {
                id: clockText
                anchors.horizontalCenter: parent.horizontalCenter
                y: pill.flashing ? -height : Math.round((parent.height - height) / 2)
                text: Qt.formatDateTime(tick.date, "HH:mm")
                color: Colors.fg
                family: Fonts.mono
                pixelSize: 13
                weight: Font.DemiBold
                opacity: pill.flashing ? 0 : 1
                scale: pill.flashing ? 0.86 : 1

                layer.enabled: IslandConfig.s("blurSwap") && opacity < 0.99
                layer.smooth: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 16
                    blur: Math.min(1, (1 - clockText.opacity) * 1.4)
                }

                Behavior on y {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: pill.flashing ? 0 : Motion.isleRevealDelay
                        }
                        NumberAnimation {
                            duration: pill.flashing ? Motion.isleHideMs
                                                    : Motion.isleRevealMs
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.isleContent
                        }
                    }
                }
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: pill.flashing ? 0 : Motion.isleRevealDelay
                        }
                        NumberAnimation {
                            duration: pill.flashing ? Motion.isleHideMs
                                                    : Motion.isleRevealMs
                        }
                    }
                }
                Behavior on scale {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: pill.flashing ? 0 : Motion.isleRevealDelay
                        }
                        NumberAnimation {
                            duration: pill.flashing ? Motion.isleHideMs
                                                    : Motion.isleRevealMs
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.isleContent
                        }
                    }
                }
            }

            Item {
                id: eventRow
                anchors.horizontalCenter: parent.horizontalCenter
                width: pill.maxWidth > 0
                    ? Math.min(pill.eventW,
                               Math.max(0, pill.maxWidth - 24 - pill.sideRoom * 2))
                    : pill.eventW
                height: pill.inner
                y: pill.flashing ? Math.round((parent.height - height) / 2)
                                 : parent.height
                opacity: pill.flashing ? 1 : 0
                scale: pill.flashing ? 1 : 0.86

                layer.enabled: IslandConfig.s("blurSwap") && opacity < 0.99
                layer.smooth: true
                layer.effect: MultiEffect {
                    blurEnabled: true
                    blurMax: 16
                    blur: Math.min(1, (1 - eventRow.opacity) * 1.4)
                }

                Behavior on y {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: pill.flashing ? Motion.isleRevealDelay : 0
                        }
                        NumberAnimation {
                            duration: pill.flashing ? Motion.isleRevealMs
                                                    : Motion.isleHideMs
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.isleContent
                        }
                    }
                }
                Behavior on opacity {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: pill.flashing ? Motion.isleRevealDelay : 0
                        }
                        NumberAnimation {
                            duration: pill.flashing ? Motion.isleRevealMs
                                                    : Motion.isleHideMs
                        }
                    }
                }
                Behavior on scale {
                    SequentialAnimation {
                        PauseAnimation {
                            duration: pill.flashing ? Motion.isleRevealDelay : 0
                        }
                        NumberAnimation {
                            duration: pill.flashing ? Motion.isleRevealMs
                                                    : Motion.isleHideMs
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.isleContent
                        }
                    }
                }

                Item {
                    id: mark
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !pill.deskFlash && !pill.keysFlash
                    width: visible ? pill.markW : 0
                    height: pill.inner

                    Rectangle {
                        anchors.fill: parent
                        visible: pill.notifFlash
                        radius: Math.round(height * 0.34)
                        antialiasing: true
                        color: Colors.alpha(pill.tint, 0.22)

                        Text {
                            anchors.centerIn: parent
                            text: NotifHistory.appLetter(pill.notifApp)
                            color: pill.tint
                            font.family: Fonts.mono
                            font.pixelSize: Math.max(9, Math.round(parent.height * 0.52))
                            font.weight: Font.Bold
                        }
                    }

                    IslandWave {
                        id: waveMark

                        anchors.centerIn: parent
                        visible: pill.osdFlash
                        size: pill.inner
                        tint: pill.tint
                        live: pill.osdFlash
                        channel: Feedback.channel
                        muted: Feedback.flat
                        way: Feedback.way
                        level: Feedback.value
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: pill.keysFlash
                        radius: Math.round(height * 0.3)
                        antialiasing: true
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Colors.alpha(pill.tint, 0.34) }
                            GradientStop { position: 1.0; color: Colors.alpha(pill.tint, 0.16) }
                        }
                        border.width: 1
                        border.color: Colors.alpha(pill.tint, 0.4)
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: !pill.notifFlash && !pill.osdFlash
                        text: pill.flashGlyph
                        color: pill.tint
                        font.family: Fonts.glyph
                        font.pixelSize: 14
                    }
                }

                Item {
                    id: desks

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pill.deskFlash
                    width: visible ? pill.desksW + 16 : 0
                    height: pill.inner

                    readonly property real slot: pill.dotW + pill.dotGap
                    readonly property real seat:
                        pill.deskIndex * desks.slot + pill.dotW / 2

                    MorphSpring {
                        id: lead
                        springBack: true
                        response: 0.28
                        damping: 0.82
                        epsilon: 0.05
                        target: desks.seat
                    }

                    MorphSpring {
                        id: trail
                        springBack: true
                        response: 0.46
                        damping: 0.84
                        epsilon: 0.05
                        target: desks.seat
                    }

                    readonly property real capH: 8
                    readonly property real capR: 9

                    readonly property real edgeL:
                        Math.min(lead.value, trail.value) - desks.capR
                    readonly property real edgeR:
                        Math.max(lead.value, trail.value) + desks.capR
                    readonly property real stretch:
                        Math.max(0, (desks.edgeR - desks.edgeL) - desks.capR * 2)

                    Row {
                        id: dots
                        x: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: pill.dotGap

                        Repeater {
                            model: Hyprland.workspaces

                            Rectangle {
                                required property var modelData

                                anchors.verticalCenter: parent.verticalCenter
                                width: pill.dotW
                                height: pill.dotW
                                radius: height / 2
                                antialiasing: true
                                color: Colors.alpha(Colors.fgDim, 0.3)
                            }
                        }
                    }

                    Rectangle {
                        x: marker.x - 3
                        y: marker.y - 3
                        width: marker.width + 6
                        height: marker.height + 6
                        radius: height / 2
                        antialiasing: true
                        color: Colors.alpha(pill.tint, 0.18)
                    }

                    Rectangle {
                        id: marker

                        x: 8 + desks.edgeL
                        width: desks.edgeR - desks.edgeL
                        height: desks.capH
                        radius: height / 2
                        antialiasing: true
                        anchors.verticalCenter: parent.verticalCenter

                        gradient: Gradient {
                            orientation: Gradient.Horizontal
                            GradientStop { position: 0.0; color: Colors.alpha(pill.tint, 0.82) }
                            GradientStop { position: 1.0; color: pill.tint }
                        }
                    }
                }

                Row {
                    id: tailRow
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8
                    visible: !pill.deskFlash

                    readonly property color ink: {
                        switch (pill.flashKind) {
                        case "power":
                        case "peri":
                        case "bt":
                        case "vpn":
                        case "keys":
                            return Qt.lighter(pill.tint, 1.08);
                        case "osd":
                            if (Feedback.flat)
                                return Colors.warn;
                        }
                        return Colors.fg;
                    }

                Item {
                    id: langCard
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pill.keysFlash
                    width: visible ? pill.keysW : 0
                    height: pill.inner

                    readonly property int at: Math.max(0, pill.keyCodes.indexOf(pill.flashText))
                    readonly property real slot: langEm.width + pill.keyGap

                    MorphSpring {
                        id: dotX
                        springBack: true
                        response: 0.34
                        damping: 0.62
                        epsilon: 0.05
                        target: langCard.at * langCard.slot + langEm.width / 2
                        Component.onCompleted: dotX.land()
                    }

                    Row {
                        id: codeRow
                        x: 2
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.verticalCenterOffset: -2
                        spacing: pill.keyGap

                        Repeater {
                            model: pill.keyCodes

                            Text {
                                id: code
                                required property string modelData
                                required property int index
                                readonly property bool on: index === langCard.at

                                width: langEm.width
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                                color: code.on ? "white" : Colors.alpha(Colors.fg, 0.32)
                                scale: code.on ? 1.08 : 0.94
                                font.family: Fonts.display
                                font.pixelSize: 12
                                font.weight: Font.Bold
                                font.letterSpacing: 1.2

                                Behavior on color { ColorAnimation { duration: 260 } }
                                Behavior on scale {
                                    SpringAnimation { spring: 4; damping: 0.32; mass: 0.7; epsilon: 0.002 }
                                }
                            }
                        }
                    }

                    Rectangle {
                        readonly property real stretch: Math.min(10, Math.abs(dotX.velocity) * 0.05)
                        width: 4 + stretch
                        height: 4
                        radius: 2
                        antialiasing: true
                        x: codeRow.x + dotX.value - width / 2
                        y: codeRow.y + codeRow.height + 1
                        color: Qt.lighter(pill.tint, 1.15)
                    }
                }

                Text {
                    id: label
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !pill.deskFlash && !pill.pctOnly
                             && pill.flashKind !== "keys" && text !== ""
                    width: visible ? pill.textRoom : 0
                    text: pill.flashText
                    color: tailRow.ink
                    horizontalAlignment: pill.notifFlash ? Text.AlignLeft
                                                         : Text.AlignRight
                    font.family: Fonts.display
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight

                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.isleContentMs
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.isleContent
                        }
                    }
                }

                IslandMeter {
                    id: miniMeter
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pill.hasMeter
                    width: visible ? pill.meterW : 0
                    height: 8
                    value: pill.flashFraction
                    tint: pill.tint
                    live: Feedback.channel === "source" && !Feedback.flat
                          ? MicLevel.level : -1

                    Connections {
                        target: Feedback
                        function onPulseChanged() { miniMeter.kick(); }
                    }
                }

                RollText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: pill.osdFlash && pill.flashFraction >= 0
                    text: visible ? Feedback.percent(pill.flashFraction) : ""
                    color: Colors.fg
                    family: Fonts.mono
                    pixelSize: 12
                    weight: Font.DemiBold
                    rollDuration: 260
                }

                Item {
                    id: stack

                    anchors.verticalCenter: parent.verticalCenter
                    visible: pill.hasStack
                    width: visible ? pill.stackW : 0
                    height: pill.stackW
                    opacity: pill.hasStack ? 1 : 0
                    scale: pill.hasStack ? 1 : 0.6

                    Behavior on opacity {
                        NumberAnimation { duration: Motion.isleRevealMs }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: Motion.isleRevealMs
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.8
                        }
                    }

                    Rectangle {
                        id: stackDisc
                        anchors.fill: parent
                        radius: height / 2
                        antialiasing: true
                        color: Colors.alpha(Colors.fgDim, 0.20)

                        Text {
                            anchors.centerIn: parent
                            text: "+" + pill.stacked
                            color: Colors.fgDim
                            font.family: Fonts.mono
                            font.pixelSize: Math.max(8, Math.round(parent.height * 0.5))
                            font.weight: Font.Bold
                        }
                    }

                    SequentialAnimation {
                        id: stackPop
                        NumberAnimation {
                            target: stackDisc; property: "scale"
                            to: 1.28; duration: 120
                            easing.type: Easing.OutBack; easing.overshoot: 2.6
                        }
                        NumberAnimation {
                            target: stackDisc; property: "scale"
                            to: 1.0; duration: 260
                            easing.type: Easing.OutCubic
                        }
                    }

                    Connections {
                        target: pill
                        function onStackedChanged() {
                            if (pill.stacked > 0)
                                stackPop.restart();
                        }
                    }
                }
                }
            }
        }

        Item {
            id: miniArt

            anchors.left: parent.left
            anchors.leftMargin: 6
            anchors.verticalCenter: parent.verticalCenter
            width: pill.inner
            height: pill.inner
            opacity: pill.miniMedia ? 1 : 0
            scale: (pill.miniMedia ? 1 : 0.5) * (1 + 0.06 * pill.beat)
            visible: opacity > 0.01

            layer.enabled: IslandConfig.s("blurSwap") && opacity < 0.99
                layer.smooth: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blurMax: 12
                blur: 1 - miniArt.opacity
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: pill.miniMedia ? Motion.isleRevealMs + 80 : Motion.isleHideMs
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.isleContent
                }
            }

            ClippingRectangle {
                anchors.fill: parent
                radius: Math.round(width * 0.3)
                color: Colors.alpha(pill.mediaTint, 0.28)

                Image {
                    anchors.fill: parent
                    visible: Media.art !== ""
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    sourceSize.width: 64
                }

                Text {
                    anchors.centerIn: parent
                    visible: Media.art === ""
                    text: "󰎈"
                    color: pill.mediaTint
                    font.family: Fonts.glyph
                    font.pixelSize: Math.max(8, parent.width * 0.6)
                }
            }
        }

        IslandBars {
            id: miniBars

            anchors.right: parent.right
            anchors.rightMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: Math.round(pill.inner * 1.1)
            height: Math.round(pill.inner * 0.8)
            tint: pill.mediaTint
            live: pill.miniMedia
            opacity: pill.miniMedia ? 1 : 0
            scale: pill.miniMedia ? 1 : 0.5
            visible: opacity > 0.01

            Behavior on opacity {
                NumberAnimation {
                    duration: pill.miniMedia ? Motion.isleRevealMs + 80 : Motion.isleHideMs
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.isleContent
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: pill.miniMedia ? Motion.isleRevealMs + 80 : Motion.isleHideMs
                    easing.type: Easing.OutBack
                    easing.overshoot: 1.6
                }
            }
        }
    }
}
