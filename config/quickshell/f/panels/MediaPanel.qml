import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    onShownChanged: Sfx.panel(shown)

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    readonly property int rays: 44
    readonly property real ringRadius: 124

    function rayLevel(i) {
        const src = Cava.levels;
        if (!src || src.length === 0) return 0;

        const half = root.rays / 2;
        const pos = i < half ? i / half : (root.rays - i) / half;
        const f = pos * (src.length - 1);
        const a = Math.floor(f);
        const b = Math.min(src.length - 1, a + 1);
        return src[a] + (src[b] - src[a]) * (f - a);
    }

    readonly property real remaining:
        Media.hasPosition
            ? Math.max(0, Media.player.length - Media.player.position)
            : 0

    Connections {
        target: Media
        function onHasChanged() { if (!Media.has) root.close(); }
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-media"
        id: win
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.42 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.10
            width: 380
            height: body.implicitHeight + 44
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96)
            border.width: 0
            clip: true

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            transform: Translate { y: root.shown ? 0 : 22
                Behavior on y {
                    NumberAnimation {
                        duration: Motion.slow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.expo
                    }
                }
            }

            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                SpringAnimation {
                    spring: Motion.panelSpring
                    damping: Motion.panelDamping
                    mass: Motion.panelMass
                    epsilon: 0.001
                }
            }

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edge: Colors.accent
                edgeOpacity: 0.30
            }

            focus: true
            Keys.onEscapePressed: root.close()
            Keys.onSpacePressed: Media.toggle()
            Keys.onLeftPressed: Media.seekTo(Media.progress - 0.02)
            Keys.onRightPressed: Media.seekTo(Media.progress + 0.02)

            Item {
                anchors.fill: parent
                visible: Media.art !== ""
                opacity: 0.34

                Image {
                    id: backdrop
                    anchors.fill: parent
                    source: Media.art
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                }

                MultiEffect {
                    anchors.fill: parent
                    source: backdrop
                    blurEnabled: true
                    blur: 1.0
                    blurMax: 64
                    saturation: 0.35
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.15)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.92)
                    }
                }
            }

            Column {
                id: body
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 8

                    Text {
                        text: Media.playing ? "󰋋" : "󰝛"
                        color: Colors.accent
                        opacity: 0.8
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        width: parent.width - 30
                        text: Media.source !== "" ? Media.source.toUpperCase() : "NO PLAYER"
                        color: Colors.fgDim
                        opacity: 0.5
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 9
                        font.letterSpacing: 1.2
                        elide: Text.ElideRight
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                Item {
                    id: deck
                    width: parent.width
                    height: 288

                    property real spin: 0

                    NumberAnimation on spin {
                        id: spinAnim
                        from: 0
                        to: 360
                        duration: 9000
                        loops: Animation.Infinite
                        running: root.shown
                        paused: spinAnim.running && !Media.playing
                    }

                    Item {
                        id: stage
                        anchors.centerIn: parent
                        width: 288
                        height: 288

                        Repeater {
                            model: root.rays

                            Item {
                                required property int index
                                anchors.fill: parent
                                rotation: index * (360 / root.rays)

                                Rectangle {
                                    readonly property real level: root.rayLevel(parent.index)

                                    width: 3
                                    height: 3 + level * 26
                                    radius: 1.5
                                    x: parent.width / 2 - width / 2
                                    y: parent.height / 2 - root.ringRadius - height
                                    color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                   Colors.accent.b, 0.35 + level * 0.55)

                                    Behavior on height {
                                        NumberAnimation { duration: 110; easing.type: Easing.OutQuad }
                                    }
                                }
                            }
                        }

                        ProgressRing {
                            anchors.centerIn: parent
                            width: 236
                            height: 236
                            visible: Media.hasPosition
                            value: Media.progress
                            thickness: 2.5
                            color: Colors.accent
                            trackColor: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                Colors.outline.b, 0.22)
                            animationDuration: 900
                        }

                        Item {
                            id: vinyl
                            anchors.centerIn: parent
                            width: 218
                            height: 218
                            rotation: deck.spin

                            scale: Media.playing ? 1.0 : 0.965
                            Behavior on scale {
                                NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: "#0b0b0d"
                                border.width: 1
                                border.color: Qt.rgba(1, 1, 1, 0.07)
                            }

                            Repeater {
                                model: 11

                                Rectangle {
                                    required property int index
                                    anchors.centerIn: parent
                                    width: 210 - index * 12
                                    height: width
                                    radius: width / 2
                                    color: "transparent"
                                    border.width: 1
                                    border.color: Qt.rgba(1, 1, 1, index % 2 === 0 ? 0.06 : 0.03)
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.00) }
                                    GradientStop { position: 0.42; color: Qt.rgba(1, 1, 1, 0.05) }
                                    GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.09) }
                                    GradientStop { position: 0.58; color: Qt.rgba(1, 1, 1, 0.05) }
                                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.00) }
                                }
                            }

                            ClippingRectangle {
                                anchors.centerIn: parent
                                width: 108
                                height: 108
                                radius: width / 2
                                color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.9)
                                border.width: 1
                                border.color: Qt.rgba(0, 0, 0, 0.55)

                                Image {
                                    id: cover
                                    anchors.fill: parent
                                    source: Media.art
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: Media.art !== "" && status === Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !cover.visible
                                    text: "󰎈"
                                    color: Colors.fgDim
                                    opacity: 0.4
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 34
                                }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: 13
                                height: 13
                                radius: width / 2
                                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 1.0)
                                border.width: 1
                                border.color: Qt.rgba(0, 0, 0, 0.6)
                            }
                        }

                        MouseArea {
                            anchors.centerIn: parent
                            width: 218
                            height: 218
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Media.toggle()
                        }
                    }

                    Item {
                        width: 104
                        height: 10
                        anchors.right: parent.right
                        anchors.rightMargin: 10
                        anchors.top: parent.top
                        anchors.topMargin: 34

                        transformOrigin: Item.Right
                        rotation: Media.playing ? 26 : 6
                        Behavior on rotation {
                            NumberAnimation { duration: 520; easing.type: Easing.InOutCubic }
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            anchors.leftMargin: 6
                            width: parent.width - 18
                            height: 3
                            radius: 1.5
                            color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                           Colors.outline.b, 0.55)
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: parent.left
                            width: 10
                            height: 6
                            radius: 2
                            color: Colors.accent
                            opacity: 0.75
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.right: parent.right
                            width: 16
                            height: 16
                            radius: 8
                            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.95)
                            border.width: 1
                            border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                  Colors.outline.b, 0.45)
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 3

                    Marquee {
                        width: parent.width
                        text: Media.title !== "" ? Media.title : I18n.t("bar.nothingPlaying")
                        color: Colors.fg
                        family: Fonts.display
                        pixelSize: 15
                        weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        visible: Media.artist !== ""
                        text: Media.artist
                        color: Colors.fgDim
                        font.family: Fonts.display
                        font.pixelSize: 12
                        elide: Text.ElideRight
                    }
                }

                Column {
                    width: parent.width
                    spacing: 7
                    visible: Media.hasPosition

                    Rectangle {
                        id: track
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.25)

                        Rectangle {
                            id: fill
                            width: parent.width * Media.progress
                            height: parent.height
                            radius: parent.radius
                            color: Colors.accent
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }

                        Rectangle {
                            width: 9
                            height: 9
                            radius: 4.5
                            color: Colors.accent
                            y: (parent.height - height) / 2
                            x: Math.max(0, Math.min(parent.width - width, fill.width - width / 2))
                            opacity: seekArea.containsMouse ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: 140 } }
                        }

                        MouseArea {
                            id: seekArea
                            anchors.fill: parent
                            anchors.margins: -8
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => Media.seekTo(mouse.x / width)
                        }
                    }

                    Item {
                        width: parent.width
                        height: 12

                        Text {
                            anchors.left: parent.left
                            text: Media.has ? Media.clock(Media.player.position) : "0:00"
                            color: Colors.fgDim
                            opacity: 0.65
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }

                        Text {
                            anchors.right: parent.right
                            text: "-" + Media.clock(root.remaining)
                            color: Colors.accent
                            opacity: 0.85
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    component Ctl: Rectangle {
                        property string glyph: ""
                        property bool enabled: true
                        property bool primary: false
                        signal activated

                        width: primary ? 46 : 34
                        height: width
                        radius: width / 2
                        color: primary
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b,
                                      hover.hovered ? 0.34 : 0.20)
                            : hover.hovered
                                ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
                                : "transparent"
                        opacity: enabled ? 1 : 0.30

                        Behavior on color { ColorAnimation { duration: 150 } }

                        HoverHandler { id: hover; enabled: parent.enabled }

                        Text {
                            anchors.centerIn: parent
                            text: parent.glyph
                            color: parent.primary ? Colors.accent : Colors.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: parent.primary ? 17 : 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: parent.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.activated()
                        }
                    }

                    Ctl {
                        glyph: "󰒮"
                        enabled: Media.canPrev
                        anchors.verticalCenter: parent.verticalCenter
                        onActivated: Media.previous()
                    }

                    Ctl {
                        glyph: Media.playing ? "󰏤" : "󰐊"
                        primary: true
                        enabled: Media.canToggle
                        anchors.verticalCenter: parent.verticalCenter
                        onActivated: Media.toggle()
                    }

                    Ctl {
                        glyph: "󰒭"
                        enabled: Media.canNext
                        anchors.verticalCenter: parent.verticalCenter
                        onActivated: Media.next()
                    }
                }
            }
        }
    }
}
