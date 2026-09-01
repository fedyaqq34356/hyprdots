import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

Scope {
    id: root

    property bool shown: false
    property string tab: "out"

    readonly property string mono: "JetBrainsMono Nerd Font"

    function toggle() { root.shown = !root.shown; }
    function close()   { root.shown = false; }

    readonly property bool outTab: root.tab === "out"

    readonly property var sink:   Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var current: root.outTab ? root.sink : root.source

    readonly property var sinks: Pipewire.nodes.values.filter(
        n => n && n.isSink && !n.isStream && n.audio)
    readonly property var sources: Pipewire.nodes.values.filter(
        n => n && !n.isSink && !n.isStream && n.audio)

    readonly property var devices: root.outTab ? root.sinks : root.sources

    PwObjectTracker {
        objects: {
            const list = root.sinks.concat(root.sources);
            if (root.sink) list.push(root.sink);
            if (root.source) list.push(root.source);
            return list;
        }
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

    function label(node) {
        if (!node) return "";
        return node.description || node.nickname || node.name || "устройство";
    }

    function shortLabel(node) {
        let s = root.label(node);
        s = s.replace(/\s*\(.*\)\s*$/, "");
        const cut = s.indexOf(" - ");
        if (cut > 3) s = s.substring(0, cut);
        return s;
    }

    function glyphFor(node) {
        const n = (root.label(node) + " " + (node && node.name ? node.name : ""))
            .toLowerCase();
        if (n.indexOf("bluez") >= 0 || n.indexOf("bluetooth") >= 0) return "󰂱";
        if (n.indexOf("hdmi") >= 0 || n.indexOf("displayport") >= 0) return "󰡁";
        if (n.indexOf("headset") >= 0 || n.indexOf("headphone") >= 0) return "󰋋";
        if (n.indexOf("usb") >= 0) return "󰋎";
        if (n.indexOf("webcam") >= 0 || n.indexOf("camera") >= 0) return "󰍬";
        if (node && !node.isSink) return "󰍬";
        return "󰓃";
    }

    function volumeOf(node) {
        return node && node.audio ? node.audio.volume : 0;
    }

    function mutedOf(node) {
        return !!(node && node.audio && node.audio.muted);
    }

    readonly property real level: root.volumeOf(root.current)
    readonly property bool muted: root.mutedOf(root.current)

    readonly property string hubGlyph: {
        if (!root.current) return root.outTab ? "󰝟" : "󰍭";
        if (root.muted) return root.outTab ? "󰝟" : "󰍭";
        if (!root.outTab) return "󰍬";
        if (root.level >= 0.66) return "󰕾";
        if (root.level >= 0.33) return "󰖀";
        if (root.level > 0.001) return "󰕿";
        return "󰝟";
    }

    readonly property string hubTitle:
        root.current ? root.label(root.current)
                     : (root.outTab ? "нет вывода" : "нет микрофона")

    readonly property string hubSub: {
        if (!root.current) return "";
        const bits = [Math.round(root.level * 100) + "%"];
        if (root.muted) bits.push("без звука");
        bits.push("колесо — громкость · клик — " + (root.muted ? "включить" : "заглушить"));
        return bits.join("  ·  ");
    }

    function isDefault(node) {
        return !!node && !!root.current && node === root.current;
    }

    readonly property var orbitModel: {
        const out = [];
        for (const d of root.devices) {
            if (root.isDefault(d)) continue;
            out.push({
                title: root.shortLabel(d),
                detail: Math.round(root.volumeOf(d) * 100) + "%",
                glyph: root.glyphFor(d),
                bars: -1,
                level: root.volumeOf(d),
                weight: root.mutedOf(d) ? 0.35 : 0.75,
                active: false,
                working: false,
                locked: root.mutedOf(d),
                ref: d
            });
        }
        return out;
    }

    property var hoveredNode: null
    readonly property var focus: root.hoveredNode

    readonly property string focusTitle:
        root.focus ? root.label(root.focus) : root.hubTitle

    readonly property string focusSub: {
        const d = root.focus;
        if (!d) return root.hubSub;
        const bits = [Math.round(root.volumeOf(d) * 100) + "%"];
        if (root.mutedOf(d)) bits.push("заглушено");
        bits.push(root.outTab ? "выход" : "вход");
        bits.push("клик — сделать основным · колесо — громкость");
        return bits.join("  ·  ");
    }

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    function plural(n) {
        const tail = n % 100;
        if (tail > 10 && tail < 20) return n + " устройств";
        const last = n % 10;
        if (last === 1) return n + " устройство";
        if (last >= 2 && last <= 4) return n + " устройства";
        return n + " устройств";
    }

    function nudge(node, dir) {
        if (!node || !node.audio) return;
        const v = Math.max(0, Math.min(1, node.audio.volume + dir * 0.05));
        node.audio.muted = false;
        node.audio.volume = v;
        if (!node.isSink) root.setMicTarget(v);
    }

    function toggleMute(node) {
        if (!node || !node.audio) return;
        node.audio.muted = !node.audio.muted;
    }

    function makeDefault(node) {
        if (!node) return;
        if (node.isSink) Pipewire.preferredDefaultAudioSink = node;
        else Pipewire.preferredDefaultAudioSource = node;
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win
        WlrLayershell.namespace: "qs-audio"
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.38 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Item {
            id: cardHost
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.10
            width: card.width
            height: card.height

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale {
                NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
            }

            Item {
                anchors.fill: parent
                z: -1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowVerticalOffset: 12
                    shadowOpacity: 0.5
                    shadowColor: "#000000"
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 28
                    color: Colors.bg
                }
            }

            Rectangle {
                id: card
                width: 640
                height: header.height + stage.height + caption.height + footer.height + 56
                radius: 28

                gradient: Gradient {
                    GradientStop { position: 0.0
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.96) }
                    GradientStop { position: 0.5
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.985) }
                    GradientStop { position: 1.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.99) }
                }

                border.width: 1
                border.color: root.alpha(Colors.accent, 0.26)

                Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                focus: true
                Keys.onEscapePressed: root.close()
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Tab) {
                        root.tab = root.outTab ? "in" : "out";
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Plus || event.key === Qt.Key_Equal) {
                        root.nudge(root.current, 1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_Minus) {
                        root.nudge(root.current, -1);
                        event.accepted = true;
                    } else if (event.key === Qt.Key_M) {
                        root.toggleMute(root.current);
                        event.accepted = true;
                    }
                }

                Item {
                    id: header
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    anchors.margins: 20
                    height: 40

                    Rectangle {
                        width: muteRow.implicitWidth + 26
                        height: 36
                        radius: 13
                        color: root.muted ? root.alpha(Colors.bgAlt, 0.7)
                                          : root.alpha(Colors.accent, 0.18)
                        border.width: 1
                        border.color: root.muted ? root.alpha(Colors.outline, 0.18)
                                                 : root.alpha(Colors.accent, 0.42)
                        Behavior on color { ColorAnimation { duration: 220 } }

                        Row {
                            id: muteRow
                            anchors.centerIn: parent
                            spacing: 9

                            Text {
                                text: root.hubGlyph
                                color: root.muted ? Colors.fgDim : Colors.accent
                                opacity: root.muted ? 0.55 : 1
                                font.family: root.mono
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.muted ? "без звука" : "звук вкл"
                                color: root.muted ? Colors.fgDim : Colors.fg
                                opacity: root.muted ? 0.55 : 0.9
                                font.family: root.mono
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 34
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.muted ? root.alpha(Colors.outline, 0.25)
                                                  : root.alpha(Colors.accent, 0.45)
                                Behavior on color { ColorAnimation { duration: 200 } }

                                Rectangle {
                                    width: 13
                                    height: 13
                                    radius: 7
                                    y: 2.5
                                    x: root.muted ? 3 : parent.width - width - 3
                                    color: root.muted ? Colors.fgDim : Colors.fg
                                    Behavior on x {
                                        NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.toggleMute(root.current)
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 2
                            text: Math.round(root.level * 100)
                            color: root.muted ? Colors.fgDim : Colors.fg
                            opacity: root.muted ? 0.4 : 0.95
                            font.family: root.mono
                            font.pixelSize: 24
                            font.weight: Font.DemiBold
                        }
                        Text {
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 5
                            text: "%"
                            color: Colors.fgDim
                            opacity: 0.4
                            font.family: root.mono
                            font.pixelSize: 12
                        }
                    }
                }

                Item {
                    id: stage
                    anchors { top: header.bottom; left: parent.left; right: parent.right }
                    anchors.topMargin: 6
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    height: 456
                    clip: true

                    OrbitGraph {
                        id: constellation
                        anchors.fill: parent
                        anchors.margins: 6

                        model: root.orbitModel
                        tint: Colors.accent
                        mono: root.mono

                        hubGlyph: root.hubGlyph
                        hubLive: !!root.current && !root.muted
                        hubLevel: root.current ? root.level : -1
                        hubMuted: root.muted

                        onPicked: item => root.makeDefault(item.ref)
                        onItemScrolled: (item, d) => root.nudge(item.ref, d)
                        onHubActivated: root.toggleMute(root.current)
                        onHubScrolled: d => root.nudge(root.current, d)
                        onHoveredItemChanged: root.hoveredNode = hoveredItem ? hoveredItem.ref : null
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 12
                        visible: !root.current

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.outTab ? "󰝟" : "󰍭"
                            color: Colors.fgDim
                            opacity: 0.22
                            font.family: root.mono
                            font.pixelSize: 54
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.outTab ? "устройств вывода нет"
                                              : "микрофонов нет"
                            color: Colors.fgDim
                            opacity: 0.5
                            font.family: root.mono
                            font.pixelSize: 12
                        }
                    }
                }

                Column {
                    id: caption
                    anchors { top: stage.bottom; left: parent.left; right: parent.right }
                    anchors.topMargin: 4
                    anchors.leftMargin: 40
                    anchors.rightMargin: 40
                    height: 42
                    spacing: 3

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: root.focusTitle
                        color: Colors.fg
                        elide: Text.ElideRight
                        font.family: root.mono
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                        text: root.focusSub
                        color: root.hoveredNode ? Colors.accent : Colors.fgDim
                        opacity: root.hoveredNode ? 0.85 : 0.5
                        elide: Text.ElideRight
                        font.family: root.mono
                        font.pixelSize: 11
                    }
                }

                Item {
                    id: footer
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    anchors.margins: 20
                    height: 42

                    Rectangle {
                        id: tabs
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 260
                        height: 40
                        radius: 14
                        color: root.alpha(Colors.bgAlt, 0.55)
                        border.width: 1
                        border.color: root.alpha(Colors.outline, 0.14)

                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: parent.height - 8
                            y: 4
                            x: root.outTab ? 4 : parent.width - width - 4
                            radius: 11
                            color: root.alpha(Colors.accent, 0.24)
                            border.width: 1
                            border.color: root.alpha(Colors.accent, 0.42)
                            Behavior on x {
                                NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.7 }
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4

                            Repeater {
                                model: [
                                    { key: "out", icon: "󰕾", label: "Выход" },
                                    { key: "in",  icon: "󰍬", label: "Вход" }
                                ]

                                Item {
                                    required property var modelData
                                    width: (tabs.width - 8) / 2
                                    height: parent.height

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 7

                                        Text {
                                            text: modelData.icon
                                            color: root.tab === modelData.key ? Colors.accent : Colors.fgDim
                                            opacity: root.tab === modelData.key ? 1 : 0.55
                                            font.family: root.mono
                                            font.pixelSize: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: modelData.label
                                            color: root.tab === modelData.key ? Colors.fg : Colors.fgDim
                                            opacity: root.tab === modelData.key ? 1 : 0.55
                                            font.family: root.mono
                                            font.pixelSize: 12
                                            font.weight: root.tab === modelData.key
                                                ? Font.DemiBold : Font.Normal
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tab = modelData.key
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: (parent.width - tabs.width) / 2 - 14
                        text: root.plural(root.devices.length)
                        color: Colors.fgDim
                        opacity: 0.4
                        elide: Text.ElideRight
                        font.family: root.mono
                        font.pixelSize: 10
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: "tab · +/− · m · esc"
                        color: Colors.fgDim
                        opacity: 0.3
                        font.family: root.mono
                        font.pixelSize: 10
                    }
                }
            }
        }
    }

    onShownChanged: {
        if (root.shown) root.tab = "out";
    }
}
