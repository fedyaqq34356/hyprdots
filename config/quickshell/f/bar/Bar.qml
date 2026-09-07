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

            anchors {
                top: Prefs.barAtTop
                bottom: !Prefs.barAtTop
                left: true
                right: true
            }

            implicitHeight: 96
            exclusiveZone: BarConfig.s("barHeight")
            color: "transparent"
            mask: Region { item: strip }

            component Island: Item {
                id: island

                property bool hovered: false
                property int introDelay: 0

                property real radius: BarConfig.s("radius")
                property color color: Qt.rgba(
                    Colors.bg.r, Colors.bg.g, Colors.bg.b,
                    (hovered ? BarConfig.s("fillHover") : BarConfig.s("fill")) / 100)
                property color borderColor: hovered
                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.55)
                    : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b,
                              BarConfig.s("borderAlpha") / 100)

                default property alias content: body.data

                scale: hovered && BarConfig.s("hoverGrow") ? 1.04 : 1.0

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
                    radius: island.radius
                    color: island.color
                    antialiasing: true
                    border.width: BarConfig.s("border") ? 1 : 0
                    border.color: island.borderColor

                    layer.enabled: BarConfig.s("shadow")
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, island.hovered ? 0.45 : 0.30)
                        shadowBlur: 0.55
                        shadowVerticalOffset: 3
                    }
                }

                Item {
                    id: body
                    anchors.fill: parent
                    readonly property real radius: island.radius
                }

                HoverHandler {
                    onHoveredChanged: island.hovered = hovered
                }

                opacity: BarConfig.s("intro") ? 0 : 1
                transform: Translate { id: intro; y: BarConfig.s("intro") ? -42 : 0 }

                Component.onCompleted: if (BarConfig.s("intro")) introAnim.start()

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
                height: BarConfig.s("islandHeight")
                width: modRow.implicitWidth + BarConfig.s("islandPadding") * 2

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
                    visible: tile.wantsRing
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
                    spacing: BarConfig.s("itemSpacing")

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

            Modules {
                id: modules
                tipHost: tips
                panels: root.panels
            }

            Item {
                id: strip
                anchors.top: Prefs.barAtTop ? parent.top : undefined
                anchors.bottom: Prefs.barAtTop ? undefined : parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: BarConfig.s("barHeight")

                Row {
                    id: leftZone
                    anchors.left: parent.left
                    anchors.leftMargin: BarConfig.s("edgeMargin")
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: BarConfig.s("islandGap")

                    Repeater {
                        model: BarConfig.zones.left

                        ConfiguredIsland {
                            required property var modelData
                            required property int index
                            isle: modelData
                            position: index
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Row {
                    id: centerZone
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: BarConfig.s("islandGap")

                    Repeater {
                        model: BarConfig.zones.center

                        ConfiguredIsland {
                            required property var modelData
                            required property int index
                            isle: modelData
                            position: index + 2
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                Row {
                    id: rightZone
                    anchors.right: parent.right
                    anchors.rightMargin: BarConfig.s("edgeMargin")
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: BarConfig.s("islandGap")

                    Repeater {
                        model: BarConfig.zones.right

                        ConfiguredIsland {
                            required property var modelData
                            required property int index
                            isle: modelData
                            position: index + 3
                            anchors.verticalCenter: parent.verticalCenter
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
