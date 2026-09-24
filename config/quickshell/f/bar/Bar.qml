import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property var panels: ({})

    Variants {
        model: Quickshell.screens

        PanelWindow {
            WlrLayershell.namespace: "qs-bar"
            id: win
            required property var modelData
            screen: modelData

            readonly property string screenName: modelData.name

            anchors {
                top: Prefs.barAtTop
                bottom: !Prefs.barAtTop
                left: true
                right: true
            }

            implicitHeight: 96
            exclusiveZone: win.autohide ? 0 : BarConfig.s("barHeight", win.screenName)
            color: "transparent"

            mask: Region { item: hitbox }

            readonly property bool autohide: BarConfig.s("autohide", win.screenName)

            property bool peeking: false
            property bool held: true
            readonly property bool revealed: !win.autohide || win.held

            function settle() {
                hideTimer.stop();
                if (win.autohide && !win.peeking)
                    hideTimer.restart();
                else
                    win.held = true;
            }

            onAutohideChanged: win.settle()
            Component.onCompleted: win.settle()

            onPeekingChanged: {
                if (win.peeking) {
                    hideTimer.stop();
                    win.held = true;
                } else if (win.autohide) {
                    hideTimer.restart();
                }
            }

            Timer {
                id: hideTimer
                interval: BarConfig.s("autohideDelay", win.screenName)
                onTriggered: if (win.autohide && !win.peeking) win.held = false;
            }

            Item {
                id: hitbox
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: Prefs.barAtTop ? parent.top : undefined
                anchors.bottom: Prefs.barAtTop ? undefined : parent.bottom
                height: win.revealed ? BarConfig.s("barHeight", win.screenName)
                                     : BarConfig.s("autohidePeek", win.screenName)
                z: 300

                HoverHandler {
                    onHoveredChanged: win.peeking = hovered
                }
            }

            readonly property bool yielded:
                IslandConfig.s("enabled") && IslandConfig.s("inBar")
                && IslandConfig.s("barTakeover")

            readonly property string barStyle: BarConfig.s("barStyle", win.screenName)
            readonly property bool solidZones: barStyle === "solid"
            readonly property bool monoline: barStyle === "bar"
            readonly property bool pills: BarConfig.s("distinctPills", win.screenName)

            component Island: Item {
                id: island

                property bool hovered: false
                property int introDelay: 0

                property Blobs blobField: null
                readonly property bool blobbed:
                    island.blobField !== null && BarConfig.s("blob", win.screenName)
                    && !win.monoline

                readonly property bool isBlob: true
                readonly property real blobOffsetY: intro.y

                function blobSync() {
                    if (island.blobField)
                        island.blobField.requestSync();
                }

                onXChanged: island.blobSync()
                onYChanged: island.blobSync()
                onWidthChanged: island.blobSync()
                onHeightChanged: island.blobSync()
                onScaleChanged: island.blobSync()
                onVisibleChanged: island.blobSync()
                onBlobOffsetYChanged: island.blobSync()
                Component.onDestruction: island.blobSync()

                property real radius: BarConfig.s("radius", win.screenName)
                property color color: Colors.alpha(
                    Colors.bg,
                    (hovered ? BarConfig.s("fillHover", win.screenName) : BarConfig.s("fill", win.screenName)) / 100)
                property color borderColor: hovered
                    ? Colors.alpha(Colors.accent, 0.55)
                    : Colors.alpha(Colors.outline, BarConfig.s("borderAlpha", win.screenName) / 100)

                default property alias content: body.data

                scale: hovered && BarConfig.s("hoverGrow", win.screenName)
                    ? (island.blobbed ? 1.07 : 1.04) : 1.0

                Behavior on color { ColorAnimation { duration: Motion.base } }
                Behavior on borderColor { ColorAnimation { duration: Motion.base } }
                Behavior on scale {
                    SpringAnimation {
                        spring: Motion.tapSpring
                        damping: Motion.tapDamping
                        mass: Motion.tapMass
                        epsilon: 0.001
                    }
                }

                Rectangle {
                    id: plate
                    anchors.fill: parent
                    visible: win.monoline ? win.pills
                                          : (!island.blobbed || win.pills)
                    radius: island.radius
                    color: island.color
                    antialiasing: true
                    border.width: BarConfig.s("border", win.screenName) ? 1 : 0
                    border.color: island.borderColor

                    layer.enabled: BarConfig.s("shadow", win.screenName)
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Colors.shadow(island.hovered ? 0.45 : 0.30)
                        shadowBlur: 0.60
                        shadowVerticalOffset: 3
                    }

                    Sheen {
                        anchors.fill: parent
                        radius: island.radius
                        border: false
                        grain: false
                        strength: 0.65
                    }
                }

                Item {
                    id: body
                    anchors.fill: parent
                    readonly property real radius: island.radius
                }

                HoverHandler {
                    onHoveredChanged: {
                        island.hovered = hovered;
                        if (!island.blobField)
                            return;
                        if (hovered)
                            island.blobField.hoverItem = island;
                        else if (island.blobField.hoverItem === island)
                            island.blobField.hoverItem = null;
                    }
                }

                readonly property bool intros:
                    BarConfig.s("intro", win.screenName) && !BarConfig.introPlayed

                opacity: island.intros ? 0 : 1
                transform: Translate { id: intro; y: island.intros ? -42 : 0 }

                Component.onCompleted: {
                    island.blobSync();
                    if (island.intros)
                        introAnim.start();
                }

                SequentialAnimation {
                    id: introAnim

                    PauseAnimation { duration: island.introDelay }

                    ParallelAnimation {
                        NumberAnimation {
                            target: intro; property: "y"; to: 0
                            duration: 620
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.snap
                        }
                        NumberAnimation {
                            target: island; property: "opacity"; to: 1
                            duration: 380
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            component ConfiguredIsland: Island {
                id: tile

                required property var isle
                required property int position

                property bool wantsRing: false

                introDelay: position * 110
                height: BarConfig.s("islandHeight", win.screenName)
                width: modRow.implicitWidth + BarConfig.s("islandPadding", win.screenName) * 2

                property int shownCount: 0
                visible: shownCount > 0

                function recount() {
                    let n = 0;
                    for (let i = 0; i < modRow.children.length; i++) {
                        const slot = modRow.children[i];
                        if (slot && slot.item && slot.item.shown)
                            n++;
                    }
                    tile.shownCount = n;
                }

                RectRing {
                    id: secondsArc
                    anchors.fill: parent
                    radius: parent.radius
                    visible: tile.wantsRing && (!win.monoline || win.pills)
                    thickness: clockFeedback ? 2.5 : 2
                    inset: 1

                    readonly property bool clockFeedback:
                        Prefs.osdStyle === "island" && Feedback.shown

                    color: clockFeedback
                        ? Colors.accent
                        : Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.85)

                    property real sweep: 0

                    Timer {
                        interval: 160
                        running: secondsArc.visible && !secondsArc.clockFeedback
                        repeat: true
                        triggeredOnStart: true
                        onTriggered: {
                            const d = new Date();
                            secondsArc.sweep =
                                (d.getSeconds() + d.getMilliseconds() / 1000) / 60;
                        }
                    }

                    value: clockFeedback
                        ? Math.max(0, Math.min(1, Feedback.value))
                        : sweep

                    wave: clockFeedback
                    amplitude: clockFeedback
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
                        running: secondsArc.visible && secondsArc.clockFeedback
                        loops: Animation.Infinite
                        from: 0
                        to: Math.PI * 2
                        duration: 1400
                    }

                    Behavior on thickness { NumberAnimation { duration: Motion.base } }
                    Behavior on value {
                        enabled: secondsArc.clockFeedback
                        NumberAnimation {
                            duration: Motion.slow
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.expo
                        }
                    }
                }

                SequentialAnimation {
                    id: nudge
                    NumberAnimation {
                        target: tile; property: "scale"
                        to: 1.06; duration: Motion.instant
                    }
                    NumberAnimation {
                        target: tile; property: "scale"
                        to: 1.0; duration: Motion.slow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.snap
                    }
                }

                Connections {
                    target: Feedback
                    enabled: tile.wantsRing
                    function onPulseChanged() {
                        if (Prefs.osdStyle === "island" && Feedback.shown)
                            nudge.restart();
                    }
                }

                Row {
                    id: modRow
                    anchors.centerIn: parent
                    height: parent.height
                    spacing: BarConfig.s("itemSpacing", win.screenName)

                    Repeater {
                        model: tile.isle.items

                        Loader {
                            id: slot
                            required property var modelData
                            anchors.verticalCenter: parent.verticalCenter
                            sourceComponent: modules.component(modelData.type)

                            visible: item ? item.shown : false

                            Connections {
                                target: slot.item
                                function onShownChanged() { tile.recount(); }
                            }

                            onLoaded: {
                                item.item = modelData;
                                if (modelData.type === "clock"
                                    && BarConfig.opt(modelData, "seconds"))
                                    tile.wantsRing = true;
                                tile.recount();
                            }
                        }
                    }
                }
            }

            Timer {
                interval: 1200
                running: !BarConfig.introPlayed
                onTriggered: BarConfig.introPlayed = true
            }

            Modules {
                id: modules
                screenName: win.screenName
                tipHost: tips
                panels: root.panels
            }

            component ZoneBlobs: Blobs {
                z: -1
                visible: BarConfig.s("blob", win.screenName) && count > 0 && !win.monoline

                fuse: win.solidZones
                    ? BarConfig.s("islandGap", win.screenName) * 0.9 + 4
                    : BarConfig.s("blobFuse", win.screenName)
                corner: BarConfig.s("radius", win.screenName)

                fillColor: Colors.bg
                fillAlpha: BarConfig.s("fill", win.screenName) / 100
                hoverColor: Colors.bg
                hoverAlpha: BarConfig.s("fillHover", win.screenName) / 100
                strokeColor: Colors.outline
                strokeAlpha: BarConfig.s("border", win.screenName)
                    ? BarConfig.s("borderAlpha", win.screenName) / 100 : 0
                stroke: BarConfig.s("border", win.screenName) ? 1.5 : 0

                shadow: BarConfig.s("shadow", win.screenName)
            }

            component GlideTransition: Transition {
                enabled: BarConfig.s("blob", win.screenName) && BarConfig.s("blobGlide", win.screenName)
                NumberAnimation {
                    properties: "x"
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.glide
                }
            }

            Item {
                id: strip
                anchors.top: Prefs.barAtTop ? parent.top : undefined
                anchors.bottom: Prefs.barAtTop ? undefined : parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: BarConfig.s("barHeight", win.screenName)

                transform: Translate {
                    y: win.revealed
                        ? 0
                        : (Prefs.barAtTop ? -strip.height - 6
                                          : strip.height + 6)

                    Behavior on y {
                        NumberAnimation {
                            duration: Motion.slow
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.expo
                        }
                    }
                }

                Rectangle {
                    id: mono
                    z: -2
                    visible: win.monoline && !win.yielded

                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width * BarConfig.s("monoWidth", win.screenName) / 100
                    height: Math.max(1, parent.height
                                        - BarConfig.s("monoInset", win.screenName) * 2)

                    radius: BarConfig.s("monoRadius", win.screenName)
                    antialiasing: radius > 0
                    color: Colors.alpha(Colors.bg, BarConfig.s("monoFill", win.screenName) / 100)
                    border.width: BarConfig.s("monoBorder", win.screenName) ? 1 : 0
                    border.color: Colors.alpha(Colors.outline,
                                               BarConfig.s("borderAlpha", win.screenName) / 100)

                    Behavior on color { ColorAnimation { duration: Motion.base } }
                    Behavior on width {
                        NumberAnimation {
                            duration: Motion.slow
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.glide
                        }
                    }

                    Sheen {
                        anchors.fill: parent
                        radius: mono.radius
                        border: false
                        grain: false
                        strength: 0.65
                    }

                    Rectangle {
                        visible: BarConfig.s("monoRule", win.screenName)
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: Prefs.barAtTop ? undefined : parent.top
                        anchors.bottom: Prefs.barAtTop ? parent.bottom : undefined
                        height: 1
                        color: Colors.alpha(Colors.outline,
                                            BarConfig.s("borderAlpha", win.screenName) / 100)
                    }
                }

                Rectangle {
                    z: -3
                    visible: win.monoline && !win.yielded
                             && BarConfig.s("shadow", win.screenName)
                    anchors.left: mono.left
                    anchors.right: mono.right
                    anchors.top: Prefs.barAtTop ? mono.bottom : undefined
                    anchors.bottom: Prefs.barAtTop ? undefined : mono.top
                    height: 10
                    radius: mono.radius > 0 ? mono.radius : 0

                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop {
                            position: 0
                            color: Prefs.barAtTop ? Colors.shadow(0.28)
                                                  : "transparent"
                        }
                        GradientStop {
                            position: 1
                            color: Prefs.barAtTop ? "transparent"
                                                  : Colors.shadow(0.28)
                        }
                    }
                }

                Item {
                    id: field
                    visible: !win.yielded
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: win.monoline ? mono.width : parent.width
                    height: parent.height

                    Row {
                        id: leftZone
                        anchors.left: parent.left
                        anchors.leftMargin: BarConfig.s("edgeMargin", win.screenName)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: BarConfig.s("islandGap", win.screenName)

                        move: GlideTransition {}
                        add: GlideTransition {}

                        Repeater {
                            model: BarConfig.islands("left", win.screenName)

                            ConfiguredIsland {
                                required property var modelData
                                required property int index
                                isle: modelData
                                position: index
                                blobField: leftBlob
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    ZoneBlobs {
                        id: leftBlob
                        host: leftZone
                    }

                    Row {
                        id: centerZone
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: BarConfig.s("islandGap", win.screenName)

                        move: GlideTransition {}
                        add: GlideTransition {}

                        Repeater {
                            model: BarConfig.islands("center", win.screenName)

                            ConfiguredIsland {
                                required property var modelData
                                required property int index
                                isle: modelData
                                position: index + 2
                                blobField: centerBlob
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    ZoneBlobs {
                        id: centerBlob
                        host: centerZone
                    }

                    Row {
                        id: rightZone
                        anchors.right: parent.right
                        anchors.rightMargin: BarConfig.s("edgeMargin", win.screenName)
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: BarConfig.s("islandGap", win.screenName)

                        move: GlideTransition {}
                        add: GlideTransition {}

                        Repeater {
                            model: BarConfig.islands("right", win.screenName)

                            ConfiguredIsland {
                                required property var modelData
                                required property int index
                                isle: modelData
                                position: index + 3
                                blobField: rightBlob
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }
                    }

                    ZoneBlobs {
                        id: rightBlob
                        host: rightZone
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
                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }

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
                        font.family: Fonts.mono
                        font.pixelSize: 10
                        lineHeight: 1.25
                    }
                }
            }
        }
    }
}
