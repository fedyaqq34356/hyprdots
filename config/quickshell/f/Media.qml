pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    property var player: null

    readonly property bool has: player !== null
    readonly property bool playing: has && player.isPlaying

    readonly property string title:  has && player.trackTitle  ? player.trackTitle  : ""
    readonly property string artist: has && player.trackArtist ? player.trackArtist : ""
    readonly property string art:    has && player.trackArtUrl ? player.trackArtUrl : ""
    readonly property string source: has && player.identity    ? player.identity    : ""

    readonly property bool canNext: has && player.canGoNext
    readonly property bool canPrev: has && player.canGoPrevious
    readonly property bool canToggle: has && player.canTogglePlaying

    readonly property bool hasPosition:
        has && player.positionSupported && player.lengthSupported && player.length > 0

    readonly property real progress:
        hasPosition ? Math.max(0, Math.min(1, player.position / player.length)) : 0

    readonly property string label: {
        if (!has) return "";
        if (artist === "" || title.indexOf(artist) !== -1) return title;
        return artist + " — " + title;
    }

    function pick() {
        const list = Mpris.players.values;
        if (!list || list.length === 0) {
            root.player = null;
            return;
        }

        for (const p of list) {
            if (p.isPlaying) {
                root.player = p;
                return;
            }
        }

        if (root.player && list.indexOf(root.player) !== -1)
            return;

        root.player = list[0];
    }

    function toggle()   { if (canToggle) player.togglePlaying(); }
    function next()     { if (canNext)   player.next(); }
    function previous() { if (canPrev)   player.previous(); }

    function seekTo(fraction) {
        if (!hasPosition || !player.canSeek) return;
        player.position = Math.max(0, Math.min(1, fraction)) * player.length;
    }

    function clock(seconds) {
        if (!isFinite(seconds) || seconds < 0) seconds = 0;
        const total = Math.floor(seconds);
        const m = Math.floor(total / 60);
        const s = total % 60;
        return m + ":" + (s < 10 ? "0" + s : s);
    }

    Connections {
        target: Mpris.players
        function onValuesChanged() { root.pick(); }
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            root.pick();
            if (root.has && root.player.positionSupported)
                root.player.positionChanged();
        }
    }

    Component.onCompleted: pick()
}
