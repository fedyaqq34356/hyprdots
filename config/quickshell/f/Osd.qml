import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import QtQuick
import Quickshell.Wayland

Scope {
    id: root

    property bool shown: false
    property string icon: ""
    property real value: 0
    property bool showBar: true
    property bool flat: false
    property string label: ""

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    property bool ready: false
    Component.onCompleted: readyTimer.start()
    Timer { id: readyTimer; interval: 1500; onTriggered: root.ready = true }

    Timer {
        id: hideTimer
        interval: 1600
        onTriggered: root.shown = false
    }

    function flash(ic, val, withBar, lbl, isFlat) {
        root.icon = ic;
        root.value = val;
        root.showBar = withBar;
        root.flat = isFlat === true;
        root.label = lbl;
        root.shown = true;
        hideTimer.restart();
    }

    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null
        enabled: root.ready

        function onVolumeChanged() {
            if (root.sink.audio.muted) return;
            root.flash("󰕾", root.sink.audio.volume, true,
                       Math.round(root.sink.audio.volume * 100) + "%");
        }
        function onMutedChanged() {
            const m = root.sink.audio.muted;
            root.flash(m ? "󰝟" : "󰕾", root.sink.audio.volume, true,
                       m ? "muted" : Math.round(root.sink.audio.volume * 100) + "%", m);
        }
    }

    Connections {
        target: root.source && root.source.audio ? root.source.audio : null
        enabled: root.ready

        function onMutedChanged() {
            const m = root.source.audio.muted;
            root.flash(m ? "󰍭" : "󰍬", root.source.audio.volume, true,
                       m ? "mic off" : Math.round(root.source.audio.volume * 100) + "%", m);
        }
        function onVolumeChanged() {
            if (root.source.audio.muted) return;
            root.flash("󰍬", root.source.audio.volume, true,
                       Math.round(root.source.audio.volume * 100) + "%");
        }
    }

    Connections {
        target: Brightness
        enabled: root.ready

        function onValueChanged() {
            root.flash("󰃞", Brightness.value, true,
                       Math.round(Brightness.value * 100) + "%");
        }
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-osd"
        id: win
        screen: Focus.screen
        visible: root.shown

        anchors.bottom: true
        exclusiveZone: 0
        implicitWidth: 260
        implicitHeight: 130
        color: "transparent"

        mask: Region {}

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: 220
            height: root.showBar ? 108 : 76
            radius: 20
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.92)
            border.width: 1
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                  Colors.accent.b, 0.35)

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.88
            y: root.shown ? (parent.height - height) / 2
                          : (parent.height - height) / 2 + 16

            Behavior on opacity { NumberAnimation { duration: 180 } }
            Behavior on scale {
                NumberAnimation { duration: 260; easing.type: Easing.OutBack }
            }
            Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            Behavior on height { NumberAnimation { duration: 200 } }

            Column {
                anchors.centerIn: parent
                spacing: 12
                width: parent.width - 40

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Text {
                        text: root.icon
                        color: Colors.accent
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 22
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Text {
                        text: root.label
                        color: Colors.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 15
                        font.weight: Font.DemiBold
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                WaveMeter {
                    visible: root.showBar
                    width: parent.width
                    height: 26

                    value: root.value
                    flat: root.flat
                    // While something is playing, the wave takes its shape from
                    // the actual spectrum instead of a decorative sine. Cava is
                    // already running for the bar, so this costs nothing extra.
                    spectrum: Cava.active ? Cava.levels : []
                    // Only run the animation while the OSD is actually on screen.
                    animating: root.shown

                    fillColor: Colors.accent
                    trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                        Colors.fgDim.b, 0.22)
                }
            }
        }
    }
}
