pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    property bool shown: false
    property string icon: ""
    property string label: ""
    property real value: 0
    property bool showBar: true
    property bool flat: false

    property int pulse: 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource

    property bool ready: false
    Component.onCompleted: settle.start()
    Timer { id: settle; interval: 1500; onTriggered: root.ready = true }

    Timer {
        id: life
        interval: 1600
        onTriggered: root.shown = false
    }

    function flash(icon, value, withBar, label, isFlat) {
        root.icon = icon;
        root.value = value;
        root.showBar = withBar;
        root.flat = isFlat === true;
        root.label = label;
        root.shown = true;
        root.pulse++;
        life.restart();
    }

    function percent(v) {
        return Math.round(v * 100) + "%";
    }

    Connections {
        target: root.sink && root.sink.audio ? root.sink.audio : null
        enabled: root.ready

        function onVolumeChanged() {
            if (root.sink.audio.muted)
                return;
            root.flash("󰕾", root.sink.audio.volume, true,
                       root.percent(root.sink.audio.volume));
        }

        function onMutedChanged() {
            const m = root.sink.audio.muted;
            root.flash(m ? "󰝟" : "󰕾", root.sink.audio.volume, true,
                       m ? I18n.t("audio.mutedShort") : root.percent(root.sink.audio.volume),
                       m);
        }
    }

    Connections {
        target: root.source && root.source.audio ? root.source.audio : null
        enabled: root.ready

        function onMutedChanged() {
            const m = root.source.audio.muted;
            root.flash(m ? "󰍭" : "󰍬", root.source.audio.volume, true,
                       m ? I18n.t("audio.micOff") : root.percent(root.source.audio.volume),
                       m);
        }

        function onVolumeChanged() {
            if (root.source.audio.muted)
                return;
            root.flash("󰍬", root.source.audio.volume, true,
                       root.percent(root.source.audio.volume));
        }
    }

    Connections {
        target: Brightness
        enabled: root.ready

        function onValueChanged() {
            root.flash("󰃞", Brightness.value, true,
                       root.percent(Brightness.value));
        }
    }
}
