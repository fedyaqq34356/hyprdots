import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool locked: false

    readonly property int idleSec: 180

    property string phase: "off"
    readonly property bool showing: root.phase !== "off"

    property real life: 0

    readonly property bool blocked: {
        const mon = Hyprland.focusedMonitor;
        const ws = mon ? mon.activeWorkspace : null;
        return !!(ws && ws.hasFullscreen);
    }

    function begin() {
        if (root.locked || root.blocked)
            return;
        if (root.phase === "in" || root.phase === "live")
            return;
        root.phase = "in";
        outRun.stop();
        inRun.restart();
    }

    function end() {
        if (root.phase === "off" || root.phase === "out")
            return;
        root.phase = "out";
        inRun.stop();
        demoTimer.stop();
        outRun.restart();
    }

    onLockedChanged: if (root.locked) { inRun.stop(); outRun.stop(); root.life = 0; root.phase = "off"; }

    IdleMonitor {
        enabled: !root.locked
        timeout: root.idleSec
        respectInhibitors: true
        onIsIdleChanged: isIdle ? root.begin() : root.end()
    }

    Timer {
        id: demoTimer
        interval: 15000
        onTriggered: root.end()
    }

    IpcHandler {
        target: "ferro"
        function demo(): string { root.begin(); demoTimer.restart(); return root.phase; }
        function stop(): string { root.end(); return root.phase; }
    }

    NumberAnimation {
        id: inRun
        target: root; property: "life"
        to: 1; duration: 2600
        easing.type: Easing.InOutCubic
        onFinished: if (root.phase === "in") root.phase = "live"
    }

    NumberAnimation {
        id: outRun
        target: root; property: "life"
        to: 0; duration: 1300
        easing.type: Easing.InOutCubic
        onFinished: if (root.phase === "out") root.phase = "off"
    }

    property bool holdingCava: false
    onShowingChanged: {
        if (root.showing && !root.holdingCava) { Cava.hold(); root.holdingCava = true; }
        else if (!root.showing && root.holdingCava) { Cava.release(); root.holdingCava = false; }
    }
    Component.onDestruction: if (root.holdingCava) Cava.release()

    LazyLoader {
        active: root.showing

        PanelWindow {
            id: win

            WlrLayershell.namespace: "qs-ferro"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
            exclusionMode: ExclusionMode.Ignore
            screen: Focus.screen
            anchors { top: true; bottom: true; left: true; right: true }
            color: "transparent"
            mask: Region {}

            PhaseHold { active: true }

            Component.onCompleted: IslandBus.watch += 1
            Component.onDestruction: IslandBus.watch -= 1

            readonly property bool isleLive: IslandBus.isleW > 0 && win.screen
                                             && IslandBus.isleScreen === win.screen.name
            readonly property real tw: win.isleLive ? IslandBus.isleW : IslandConfig.s("pillMin")
            readonly property real th: win.isleLive ? IslandBus.isleH : IslandConfig.s("pillHeight")
            readonly property real tcx: win.isleLive ? IslandBus.isleX + IslandBus.isleW / 2
                                                     : win.width / 2 + IslandConfig.s("offsetX")
            readonly property real tcy: win.isleLive ? IslandBus.isleY + IslandBus.isleH / 2
                                                     : (IslandConfig.s("inBar")
                                                        ? BarConfig.s("barHeight", win.screen ? win.screen.name : "") / 2
                                                        : IslandConfig.s("offsetY") + win.th / 2)

            readonly property real t: Phase.t
            readonly property real e: root.life
            readonly property real grow: Math.min(1, root.life / 0.45)
            readonly property real travel: Math.max(0, Math.min(1, (root.life - 0.25) / 0.75))
            readonly property real ease: win.travel * win.travel * (3 - 2 * win.travel)

            readonly property real rMax: Math.min(win.width, win.height) * 0.105
            readonly property real radius: Motion.mix(win.th * 0.35, win.rMax, win.grow)

            readonly property real fx: win.width * (0.5 + 0.34 * Math.sin(win.t * 0.071 + 0.6)
                                                    + 0.06 * Math.sin(win.t * 0.23))
            readonly property real fy: win.height * (0.6 + 0.2 * Math.sin(win.t * 0.053 + 1.9)
                                                     + 0.04 * Math.cos(win.t * 0.19))
            readonly property real sx: win.tcx
            readonly property real sy: win.tcy + win.th / 2 + win.radius * 0.9

            readonly property real px: Motion.mix(win.sx, win.fx, win.ease)
            readonly property real py: Motion.mix(win.sy, win.fy, win.ease)

            readonly property bool hearing: Cava.active
            readonly property real music: win.hearing
                ? Math.min(1.2, Beat.level * 1.1 + Beat.bass * 0.5 + Beat.pulse * 0.6) : 0
            readonly property real amp: (0.20 + 0.10 * Math.sin(win.t * 0.9) * (1 - Math.min(1, win.music))
                                         + win.music * 0.9)
                                        * Math.max(0, (win.grow - 0.6) / 0.4)

            ArtTint {
                id: art
                x: 4
                y: 4
                fallback: Colors.accent
            }
            readonly property color tone: win.hearing && art.found ? art.color : Colors.accent
            readonly property real glow: win.hearing
                ? Math.min(1, Beat.pulse * 0.8 + Beat.bass * 0.5) : 0.15

            Rectangle {
                anchors.fill: parent
                color: "black"
                opacity: 0.5 * win.e
            }

            readonly property real reach: win.radius * 3.6 + 60
            readonly property bool nearIsle: Math.hypot(win.px - win.tcx, win.py - win.tcy)
                                             < win.reach + win.tw / 2 + 80
            readonly property real bx0: Math.max(0, Math.min(win.px - win.reach,
                                                             win.nearIsle ? win.tcx - win.tw / 2 - 50 : 1e9))
            readonly property real by0: Math.max(0, Math.min(win.py - win.reach,
                                                             win.nearIsle ? win.tcy - win.th / 2 - 50 : 1e9))
            readonly property real bx1: Math.min(win.width, Math.max(win.px + win.reach,
                                                                     win.nearIsle ? win.tcx + win.tw / 2 + 50 : -1e9))
            readonly property real by1: Math.min(win.height, Math.max(win.py + win.reach,
                                                                      win.nearIsle ? win.tcy + win.th / 2 + 50 : -1e9))

            ShaderEffect {
                x: win.bx0
                y: win.by0
                width: Math.max(1, win.bx1 - win.bx0)
                height: Math.max(1, win.by1 - win.by0)
                fragmentShader: "root:/design/shaders/ferro3.frag.qsb"
                blending: true

                property vector2d size: Qt.vector2d(width, height)
                property vector2d center: Qt.vector2d(win.px - x, win.py - y)
                property real radius: win.radius
                property vector2d isle: Qt.vector2d(win.tcx - x, win.tcy - y)
                property vector2d isleSize: Qt.vector2d(win.tw, win.th)
                property real neck: win.nearIsle ? 1 : 0
                property real amp: win.amp
                property real bass: win.hearing ? Math.min(1, Beat.bass + Beat.pulse * 0.5) : 0
                property real time: win.t
                property color tone: win.tone
                property real glow: win.glow
                property real shadowAlpha: 0.5 * win.grow
                property real isleHide: win.isleLive ? 1 : 0
            }
        }
    }
}
