import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: crab

    property bool running: false
    property color body: Colors.accent
    property color eye: Colors.bg
    property int p: 2

    width: 14 * crab.p
    height: 9 * crab.p

    property int lookX: 0
    property bool shut: false
    property int liftL: 0
    property int liftR: 0
    property int sway: 0
    property int hop: 0
    property int step: 0

    property var frames: []
    property int at: 0

    readonly property var acts: [
        { w: 5, f: [{ shut: true }, { shut: false }] },
        { w: 1, f: [{ shut: true }, { shut: false }, {}, { shut: true }, { shut: false }] },
        { w: 2, f: [{ lookX: -1 }, {}, {}, {}, {}, {}, {}, {}, {}, {}, { lookX: 0 }] },
        { w: 2, f: [{ lookX: 1 }, {}, {}, {}, {}, {}, {}, {}, {}, {}, { lookX: 0 }] },
        { w: 2, f: [{ sway: -1, step: 1 }, { sway: 0, step: 0 }, { sway: 1, step: 1 }, { sway: 0, step: 0 },
                    { sway: -1, step: 1 }, { sway: 0, step: 0 }, { sway: 1, step: 1 }, { sway: 0, step: 0 }] },
        { w: 2, f: [{ liftL: 1, liftR: 1 }, { liftL: 0, liftR: 0 }, { liftL: 1, liftR: 1 }, { liftL: 0, liftR: 0 }] },
        { w: 1, f: [{ liftL: 1 }, { liftL: 0, liftR: 1 }, { liftL: 1, liftR: 0 }, { liftL: 0, liftR: 1 }, { liftR: 0 }] },
        { w: 1, f: [{ hop: 1, liftL: 1, liftR: 1 }, { hop: 0, liftL: 0, liftR: 0 }] }
    ]

    function rest() {
        crab.lookX = 0; crab.shut = false; crab.liftL = 0; crab.liftR = 0;
        crab.sway = 0; crab.hop = 0; crab.step = 0;
    }

    function pick() {
        let total = 0;
        for (const a of crab.acts) total += a.w;
        let r = Math.random() * total;
        for (const a of crab.acts) {
            r -= a.w;
            if (r <= 0) return a.f;
        }
        return crab.acts[0].f;
    }

    function play() {
        crab.frames = crab.pick();
        crab.at = 0;
        frame.restart();
        crab.tick();
    }

    function tick() {
        if (crab.at >= crab.frames.length) {
            frame.stop();
            crab.rest();
            gap.interval = 2500 + Math.random() * 5500;
            gap.restart();
            return;
        }
        const f = crab.frames[crab.at++];
        for (const k in f) crab[k] = f[k];
    }

    property bool dancing: false
    property int move: 0
    property double lastBeat: 0
    property real punch: 0

    readonly property var moves: [
        { sway: -1, lookX: -1, liftL: 1, liftR: 0, step: 1 },
        { sway: 0, lookX: 0, liftL: 0, liftR: 0, step: 0 },
        { sway: 1, lookX: 1, liftL: 0, liftR: 1, step: 1 },
        { sway: 0, lookX: 0, liftL: 0, liftR: 0, step: 0 },
        { sway: -1, lookX: -1, liftL: 1, liftR: 1, step: 1 },
        { sway: 0, lookX: 0, liftL: 0, liftR: 0, step: 0 },
        { sway: 1, lookX: 1, liftL: 1, liftR: 1, step: 1 },
        { sway: 0, lookX: 0, liftL: 1, liftR: 1, step: 0, hop: 1 }
    ]

    function takeBeat() {
        const now = Date.now();
        if (now - crab.lastBeat < 230)
            return;
        crab.lastBeat = now;
        crab.dance();
    }

    function dance() {
        crab.move = (crab.move + 1) % crab.moves.length;
        const m = crab.moves[crab.move];
        crab.sway = m.sway;
        crab.lookX = m.lookX;
        crab.liftL = m.liftL;
        crab.liftR = m.liftR;
        crab.step = m.step;
        crab.hop = (m.hop || crab.punch > 0.75) ? 1 : 0;
        crab.shut = crab.move === 7 && Math.random() < 0.3;
        if (crab.hop || crab.shut)
            land.restart();
    }

    function wake() {
        gap.stop();
        frame.stop();
        metro.stop();
        land.stop();
        crab.rest();
        if (!crab.running)
            return;
        if (crab.dancing) {
            crab.move = 0;
            crab.lastBeat = 0;
            metro.start();
        } else {
            gap.interval = 900;
            gap.restart();
        }
    }

    onRunningChanged: crab.wake()
    onDancingChanged: crab.wake()

    Connections {
        target: Beat
        enabled: crab.running && crab.dancing
        function onHit() {
            crab.punch = Beat.pulse * Math.min(1, Beat.bass * 1.6);
            crab.takeBeat();
        }
    }

    Timer {
        id: metro
        interval: 545
        repeat: true
        onTriggered: if (Date.now() - crab.lastBeat > 900) crab.dance()
    }

    Timer {
        id: land
        interval: 130
        onTriggered: { crab.hop = 0; crab.shut = false; }
    }

    Timer { id: gap; onTriggered: if (!crab.dancing) crab.play() }
    Timer { id: frame; interval: 110; repeat: true; onTriggered: crab.tick() }

    Item {
        x: crab.sway * crab.p
        y: -crab.hop * crab.p
        width: crab.width
        height: crab.height

        Rectangle { x: 3 * crab.p; y: crab.p; width: 8 * crab.p; height: crab.p; color: crab.body }
        Rectangle { x: 2 * crab.p; y: 2 * crab.p; width: 10 * crab.p; height: 4 * crab.p; color: crab.body }

        Rectangle { x: 0; y: (2 - crab.liftL) * crab.p; width: crab.p; height: 2 * crab.p; color: crab.body }
        Rectangle { x: crab.p; y: (3 - crab.liftL) * crab.p; width: crab.p; height: crab.p; color: crab.body }
        Rectangle { x: 13 * crab.p; y: (2 - crab.liftR) * crab.p; width: crab.p; height: 2 * crab.p; color: crab.body }
        Rectangle { x: 12 * crab.p; y: (3 - crab.liftR) * crab.p; width: crab.p; height: crab.p; color: crab.body }

        Rectangle {
            x: (4 + crab.lookX) * crab.p
            y: crab.shut ? 3 * crab.p : 2 * crab.p
            width: crab.p
            height: crab.shut ? Math.max(1, crab.p / 2) : 2 * crab.p
            color: crab.eye
        }
        Rectangle {
            x: (9 + crab.lookX) * crab.p
            y: crab.shut ? 3 * crab.p : 2 * crab.p
            width: crab.p
            height: crab.shut ? Math.max(1, crab.p / 2) : 2 * crab.p
            color: crab.eye
        }

        Repeater {
            model: [3, 5, 8, 10]
            Rectangle {
                required property int modelData
                required property int index
                x: modelData * crab.p
                y: 6 * crab.p
                width: crab.p
                height: ((index + crab.step) % 2 ? 1 : 2) * crab.p
                color: crab.body
            }
        }
    }
}
