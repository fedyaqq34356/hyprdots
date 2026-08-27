import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import QtQuick
import Quickshell.Wayland

Scope {
    id: root

    property bool shown: false

    function toggle() { root.shown = !root.shown; }
    function close()   { root.shown = false; }

    readonly property var sink:   Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    readonly property var sources: Pipewire.nodes.values.filter(
        n => n && !n.isSink && !n.isStream && n.audio)

    PwObjectTracker {
        objects: root.sources
    }

    Process {
        id: micTarget
        command: ["sh", "-c", ""]
    }

    function setMicTarget(vol) {
        const pct = Math.round(Math.max(0, Math.min(1, vol)) * 100);
        micTarget.command = [
            Quickshell.env("HOME") + "/.config/hypr/scripts/mic-target.sh",
            String(pct)
        ];
        micTarget.running = true;
    }

    component Slider: Rectangle {
        id: bar

        property real value: 0
        property color fill: Colors.accent
        signal moved(real v)

        height: 8
        radius: 4
        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.20)

        Rectangle {
            width: Math.max(bar.height, bar.width * Math.max(0, Math.min(1, bar.value)))
            height: parent.height
            radius: parent.radius
            color: bar.fill
            Behavior on width {
                enabled: !drag.pressed
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            color: bar.fill
            border.width: 2
            border.color: Colors.bg
            anchors.verticalCenter: parent.verticalCenter
            x: (bar.width - width) * Math.max(0, Math.min(1, bar.value))
            scale: drag.pressed ? 1.25 : 1
            Behavior on scale { NumberAnimation { duration: 140 } }
            Behavior on x {
                enabled: !drag.pressed
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }
        }

        MouseArea {
            id: drag
            anchors.fill: parent
            anchors.margins: -8
            cursorShape: Qt.PointingHandCursor
            preventStealing: true

            function apply(x) {
                bar.moved(Math.max(0, Math.min(1, (x - 8) / bar.width)));
            }

            onPressed: mouse => apply(mouse.x)
            onPositionChanged: mouse => { if (pressed) apply(mouse.x); }
            onWheel: wheel => bar.moved(Math.max(0, Math.min(1,
                bar.value + (wheel.angleDelta.y > 0 ? 0.02 : -0.02))))
        }
    }

    component Channel: Column {
        id: ch

        property var node: null
        property bool isSource: false
        property string title: ""
        property string iconOn: ""
        property string iconOff: ""
        property color tint: Colors.accent

        readonly property var au: node && node.audio ? node.audio : null
        readonly property bool muted: au ? au.muted : true
        readonly property real vol: au ? au.volume : 0

        spacing: 10
        width: parent.width

        Row {
            width: parent.width
            spacing: 12

            Text {
                width: 24
                text: ch.muted ? ch.iconOff : ch.iconOn
                color: ch.muted ? Colors.bad : ch.tint
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 18
                anchors.verticalCenter: parent.verticalCenter

                MouseArea {
                    anchors.fill: parent
                    anchors.margins: -6
                    cursorShape: Qt.PointingHandCursor
                    onClicked: if (ch.au) ch.au.muted = !ch.au.muted
                }
            }

            Column {
                width: parent.width - 90
                spacing: 3
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    text: ch.title
                    color: Colors.fg
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: ch.node ? (ch.node.nickname || ch.node.description || ch.node.name) : "—"
                    color: Colors.fgDim
                    opacity: 0.65
                    elide: Text.ElideRight
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }

            Text {
                width: 42
                horizontalAlignment: Text.AlignRight
                text: ch.muted ? "off" : Math.round(ch.vol * 100) + "%"
                color: ch.muted ? Colors.bad : Colors.fg
                font.family: "JetBrainsMono Nerd Font"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Slider {
            width: parent.width
            value: ch.muted ? 0 : ch.vol
            fill: ch.muted ? Colors.bgAlt : ch.tint
            onMoved: v => {
                if (!ch.au) return;
                ch.au.muted = false;
                ch.au.volume = v;
                if (ch.isSource) root.setMicTarget(v);
            }
        }
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-audio"
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
            opacity: root.shown ? 0.30 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.20
            width: 440
            height: body.implicitHeight + 40
            radius: 22
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
            border.width: 1
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30)

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 190 } }
            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            focus: true
            Keys.onEscapePressed: root.close()
            Keys.onUpPressed: root.bump(0.05)
            Keys.onDownPressed: root.bump(-0.05)
            Keys.onPressed: event => {
                if (event.key === Qt.Key_M) {
                    const a = root.source && root.source.audio;
                    if (a) a.muted = !a.muted;
                    event.accepted = true;
                }
            }

            Column {
                id: body
                anchors.fill: parent
                anchors.margins: 20
                spacing: 18

                Channel {
                    node: root.source
                    isSource: true
                    title: "Микрофон"
                    iconOn: "󰍬"
                    iconOff: "󰍭"
                    tint: Colors.accentAlt
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.20)
                }

                Channel {
                    node: root.sink
                    title: "Звук"
                    iconOn: "󰕾"
                    iconOff: "󰝟"
                    tint: Colors.accent
                }

                Column {
                    width: parent.width
                    spacing: 6
                    visible: root.sources.length > 1

                    Text {
                        text: "Устройства ввода"
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }

                    Repeater {
                        model: root.sources

                        Rectangle {
                            required property var modelData
                            readonly property bool current: root.source === modelData

                            width: parent.width
                            height: 28
                            radius: 9
                            color: current
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)
                                : hover.hovered
                                    ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.45)
                                    : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                elide: Text.ElideRight
                                text: (current ? "󰄬  " : "    ")
                                      + (modelData.nickname || modelData.description || modelData.name)
                                color: current ? Colors.accent : Colors.fgDim
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }

                            HoverHandler { id: hover }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Pipewire.preferredDefaultAudioSource = modelData
                            }
                        }
                    }
                }
            }
        }
    }

    function bump(delta) {
        const a = root.source && root.source.audio;
        if (!a) return;
        a.muted = false;
        a.volume = Math.max(0, Math.min(1, a.volume + delta));
        root.setMicTarget(a.volume);
    }
}
