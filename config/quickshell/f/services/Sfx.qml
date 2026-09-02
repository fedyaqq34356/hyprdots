pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property string dir:
        Quickshell.env("HOME") + "/.local/share/sounds/f/"
    readonly property string serp: root.dir + "serp/"

    readonly property real tapLevel:   0.35
    readonly property real uiLevel:    0.45
    readonly property real alertLevel: 0.6

    property var lastPlayed: ({})
    property var handles: ({})
    property int nextHandle: 1

    function play(path, volume, minGapMs) {
        if (!Prefs.sfxEnabled)
            return;

        const now = Date.now();
        const gap = minGapMs === undefined ? 60 : minGapMs;
        if (now - (root.lastPlayed[path] || 0) < gap)
            return;

        const stamps = root.lastPlayed;
        stamps[path] = now;
        root.lastPlayed = stamps;

        const level = (volume === undefined ? root.uiLevel : volume) * Prefs.sfxVolume;
        if (level <= 0)
            return;

        Quickshell.execDetached(["pw-play", "--volume=" + level.toFixed(3), path]);
    }

    function loop(path, volume) {
        if (!Prefs.sfxEnabled)
            return -1;

        const level = (volume === undefined ? root.uiLevel : volume) * Prefs.sfxVolume;
        if (level <= 0)
            return -1;

        const id = root.nextHandle++;
        const proc = looper.createObject(root, {
            command: ["sh", "-c",
                      "trap 'kill $CPID 2>/dev/null; exit' TERM; " +
                      "while :; do pw-play --volume=" + level.toFixed(3) +
                      " '" + path.replace(/'/g, "'\\''") + "' & CPID=$!; wait $CPID; done"],
            running: true
        });
        root.handles[id] = proc;
        return id;
    }

    function stop(id) {
        const proc = root.handles[id];
        if (!proc)
            return;
        proc.running = false;
        proc.destroy();
        delete root.handles[id];
    }

    Component {
        id: looper
        Process { stdinEnabled: false }
    }

    function tap()      { root.play(root.serp + "reusables/clickbutton/click.wav",  root.tapLevel, 40); }
    function tapAlt()   { root.play(root.serp + "reusables/clickbutton/click2.wav", root.tapLevel, 40); }
    function icon()     { root.play(root.serp + "reusables/iconbutton/click.wav",   root.tapLevel, 40); }
    function press()    { root.play(root.serp + "system/quick_click.wav",           root.tapLevel, 40); }

    function toggleOn()  { root.play(root.serp + "reusables/toggle/sfx.wav", root.uiLevel, 60); }
    function toggleOff() { root.play(root.serp + "reusables/switch/sfx.wav", root.uiLevel, 60); }
    function flip(on)    { on ? root.toggleOn() : root.toggleOff(); }

    function tick()     { root.play(root.serp + "reusables/draggable/tick.wav", 0.22, 28); }
    function type()     { root.play(root.serp + "reusables/input/type.wav", 0.3, 20); }
    function fill()     { root.play(root.serp + "reusables/fillbutton/button.wav", root.uiLevel, 40); }

    function open()     { root.play(root.serp + "reusables/dropdown/list.wav",  root.uiLevel, 80); }
    function pick()     { root.play(root.serp + "reusables/dropdown/click.wav", root.tapLevel, 40); }

    function panelIn()  { root.play(root.serp + "guide/barconfig/in.wav",  root.uiLevel, 90); }
    function panelOut() { root.play(root.serp + "guide/barconfig/out.wav", root.uiLevel, 90); }
    function panel(on)  { on ? root.panelIn() : root.panelOut(); }
    function swoosh()   { root.play(root.serp + "musicpopup/swoosh.wav",   root.uiLevel, 120); }

    function netConnect()    { root.play(root.serp + "network/connect.wav",    root.alertLevel, 200); }
    function netDisconnect() { root.play(root.serp + "network/disconnect.wav", root.alertLevel, 200); }
    function radioOn()       { root.play(root.serp + "network/power_on.wav",   root.alertLevel, 200); }
    function radioOff()      { root.play(root.serp + "network/power_off.wav",  root.alertLevel, 200); }
    function netSwitch()     { root.play(root.serp + "network/switch.wav",     root.uiLevel, 120); }

    function sessionStart() { root.play(root.serp + "start/start.wav", root.alertLevel, 1000); }
    function sessionExit()  { root.play(root.serp + "start/exit.wav",  root.alertLevel, 1000); }
    function wave()         { root.play(root.serp + "start/wave.wav",  root.uiLevel, 400); }
    function usage()        { root.play(root.serp + "quickactions/usage.wav", root.uiLevel, 200); }
    function tip()          { root.play(root.serp + "tutorial/tip.wav", root.uiLevel, 300); }

    function notify() {
        root.play(root.serp + "notifications/" + Prefs.notifySound + ".wav",
                  root.alertLevel, 350);
    }

    function critical() { root.play(root.dir + "critical.wav", 0.5, 350); }
    function limit()    { root.play(root.dir + "limit.wav", 0.45, 220); }
}
