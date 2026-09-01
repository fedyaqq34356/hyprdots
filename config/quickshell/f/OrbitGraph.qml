import QtQuick

Item {
    id: graph

    property var model: []

    property color tint: "#ffffff"
    property string mono: "JetBrainsMono Nerd Font"

    property string hubGlyph: ""
    property bool hubLive: false
    property bool busy: false

    property real hubLevel: -1
    property bool hubMuted: false

    signal picked(var item)
    signal hubActivated()
    signal hubScrolled(real delta)
    signal itemScrolled(var item, real delta)

    readonly property real cx: width / 2
    readonly property real cy: height / 2
    readonly property real hubRadius: 46

    readonly property real tiltY: 0.80
    readonly property var ringRadii: [120, 250]
    readonly property var ringCaps: [3, 5]
    readonly property int capacity: 8

    property var hoveredItem: null
    property int hoverCount: 0
    readonly property bool paused: graph.hoverCount > 0

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    function weight(item) {
        if (!item || item.weight === undefined) return 0.5;
        return Math.max(0, Math.min(1, item.weight));
    }

    function ringSpeed(ring) { return ring === 0 ? 1.0 : 0.58; }

    readonly property var layout: {
        const out = [];
        const counts = [];
        for (let r = 0; r < graph.ringRadii.length; r++) counts.push(0);

        for (let i = 0; i < graph.model.length && out.length < graph.capacity; i++) {
            let ring = 0;
            while (ring < counts.length - 1 && counts[ring] >= graph.ringCaps[ring])
                ring++;
            if (counts[ring] >= graph.ringCaps[ring]) break;
            out.push({ ring: ring, slot: counts[ring] });
            counts[ring]++;
        }

        for (let i = 0; i < out.length; i++)
            out[i].total = counts[out[i].ring];
        return out;
    }

    property real spin: 0
    NumberAnimation on spin {
        running: graph.visible && !graph.paused
        loops: Animation.Infinite
        from: 0; to: 360; duration: 52000
    }

    readonly property var positions: {
        const out = [];
        const l = graph.layout;
        for (let i = 0; i < l.length; i++) {
            const a = ((360 / l[i].total) * l[i].slot + l[i].ring * 41
                       + graph.spin * graph.ringSpeed(l[i].ring)) * Math.PI / 180;
            const r = graph.ringRadii[l[i].ring];
            const sin = Math.sin(a);
            out.push({
                x: graph.cx + Math.cos(a) * r,
                y: graph.cy + sin * r * graph.tiltY,
                depth: (sin + 1) / 2
            });
        }
        return out;
    }

    onTintChanged: { sky.requestPaint(); arc.requestPaint(); }

    Canvas {
        id: sky
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        property var dust: {
            const out = [];
            let seed = 20260901;
            const rnd = () => {
                seed = (seed * 1103515245 + 12345) & 0x7fffffff;
                return seed / 0x7fffffff;
            };
            for (let i = 0; i < 90; i++)
                out.push({ a: rnd() * Math.PI * 2,
                           r: 0.25 + rnd() * 0.95,
                           s: 0.4 + rnd() * 1.1,
                           o: 0.05 + rnd() * 0.16 });
            return out;
        }

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const outer = graph.ringRadii[graph.ringRadii.length - 1];

            for (const d of sky.dust) {
                const x = graph.cx + Math.cos(d.a) * outer * d.r;
                const y = graph.cy + Math.sin(d.a) * outer * d.r * graph.tiltY;
                ctx.beginPath();
                ctx.arc(x, y, d.s, 0, Math.PI * 2);
                ctx.fillStyle = Qt.rgba(graph.tint.r, graph.tint.g, graph.tint.b, d.o);
                ctx.fill();
            }

            for (let ring = 0; ring < graph.ringRadii.length; ring++) {
                const r = graph.ringRadii[ring];
                ctx.save();
                ctx.translate(graph.cx, graph.cy);
                ctx.scale(1, graph.tiltY);
                ctx.beginPath();
                ctx.arc(0, 0, r, 0, Math.PI * 2);
                ctx.restore();
                ctx.strokeStyle = Qt.rgba(graph.tint.r, graph.tint.g, graph.tint.b,
                                          0.14 - ring * 0.045);
                ctx.lineWidth = 1;
                ctx.setLineDash([2, 8]);
                ctx.stroke();
            }
        }
    }

    Repeater {
        model: graph.model

        Item {
            id: spoke
            required property var modelData
            required property int index

            anchors.fill: parent

            readonly property var pos: graph.positions[index]
                                    || ({ x: graph.cx, y: graph.cy, depth: 1 })
            readonly property bool active: !!(modelData && modelData.active)
            readonly property real near: 0.45 + pos.depth * 0.55
            readonly property real w: graph.weight(modelData)

            readonly property real dx: pos.x - graph.cx
            readonly property real dy: pos.y - graph.cy
            readonly property real len: Math.max(1, Math.sqrt(dx * dx + dy * dy))
            readonly property real ux: dx / len
            readonly property real uy: dy / len

            readonly property real sx: graph.cx + ux * (graph.hubRadius + 5)
            readonly property real sy: graph.cy + uy * (graph.hubRadius + 5)

            readonly property real cut: Math.min(
                Math.abs(ux) > 0.0001 ? 52 / Math.abs(ux) : 1e9,
                Math.abs(uy) > 0.0001 ? 26 / Math.abs(uy) : 1e9)
            readonly property real ex: pos.x - ux * cut
            readonly property real ey: pos.y - uy * cut

            readonly property real span: Math.max(0,
                Math.sqrt((ex - sx) * (ex - sx) + (ey - sy) * (ey - sy)))
            readonly property real angle: Math.atan2(dy, dx) * 180 / Math.PI

            visible: index < graph.positions.length

            Rectangle {
                x: spoke.sx
                y: spoke.sy - height / 2
                width: spoke.span
                height: spoke.active ? 1.9 : 1.1
                radius: height / 2
                antialiasing: true
                transformOrigin: Item.Left
                rotation: spoke.angle
                color: graph.alpha(graph.tint,
                    (spoke.active ? 0.72 : 0.20 + spoke.w * 0.26) * spoke.near)
            }

            Repeater {
                model: spoke.active ? 2 : 1

                Item {
                    required property int index
                    readonly property real phase:
                        (graph.spin * 0.05 + spoke.index * 0.31 + index * 0.5) % 1.0
                    readonly property real px: spoke.sx + (spoke.ex - spoke.sx) * phase
                    readonly property real py: spoke.sy + (spoke.ey - spoke.sy) * phase
                    readonly property real fade: Math.sin(phase * Math.PI)
                    readonly property real a1:
                        (spoke.active ? 0.85 : 0.3 + spoke.w * 0.3) * fade * spoke.near

                    Rectangle {
                        x: parent.px - 4.5
                        y: parent.py - 4.5
                        width: 9
                        height: 9
                        radius: 4.5
                        antialiasing: true
                        color: graph.alpha(graph.tint, parent.a1 * 0.28)
                    }

                    Rectangle {
                        x: parent.px - 1.8
                        y: parent.py - 1.8
                        width: 3.6
                        height: 3.6
                        radius: 1.8
                        antialiasing: true
                        color: graph.alpha(graph.tint, parent.a1)
                    }
                }
            }

            Rectangle {
                readonly property real r: spoke.active ? 2.6 : 1.9
                x: spoke.ex - r
                y: spoke.ey - r
                width: r * 2
                height: r * 2
                radius: r
                antialiasing: true
                color: graph.alpha(graph.tint,
                    (spoke.active ? 0.95 : 0.45) * spoke.near)
            }
        }
    }

    Canvas {
        id: arc
        width: (graph.hubRadius + 16) * 2
        height: width
        x: graph.cx - width / 2
        y: graph.cy - height / 2
        visible: graph.hubLevel >= 0
        renderStrategy: Canvas.Cooperative

        property real level: Math.max(0, Math.min(1, graph.hubLevel))
        Behavior on level { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        onLevelChanged: requestPaint()
        onVisibleChanged: requestPaint()
        Connections {
            target: graph
            function onHubMutedChanged() { arc.requestPaint(); }
        }

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            if (graph.hubLevel < 0) return;

            const c = width / 2;
            const r = graph.hubRadius + 11;
            ctx.lineWidth = 3;
            ctx.lineCap = "round";

            ctx.beginPath();
            ctx.arc(c, c, r, -Math.PI * 0.75, Math.PI * 0.75);
            ctx.strokeStyle = Qt.rgba(Colors.outline.r, Colors.outline.g,
                                      Colors.outline.b, 0.25);
            ctx.stroke();

            const span = Math.PI * 1.5 * arc.level;
            if (span > 0.001) {
                ctx.beginPath();
                ctx.arc(c, c, r, -Math.PI * 0.75, -Math.PI * 0.75 + span);
                ctx.strokeStyle = graph.hubMuted
                    ? Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.5)
                    : Qt.rgba(graph.tint.r, graph.tint.g, graph.tint.b, 0.9);
                ctx.stroke();
            }
        }
    }

    Item {
        id: hub
        width: graph.hubRadius * 2
        height: width
        x: graph.cx - width / 2
        y: graph.cy - height / 2

        Repeater {
            model: 3
            Rectangle {
                required property int index
                anchors.centerIn: parent
                width: hub.width
                height: hub.height
                radius: width / 2
                color: "transparent"
                border.width: 1.4
                border.color: graph.alpha(graph.tint, 0.45)
                visible: graph.hubLive || graph.busy

                SequentialAnimation on scale {
                    running: graph.visible && (graph.hubLive || graph.busy)
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 700 }
                    NumberAnimation { from: 0.94; to: 1.6; duration: 2100; easing.type: Easing.OutCubic }
                }
                SequentialAnimation on opacity {
                    running: graph.visible && (graph.hubLive || graph.busy)
                    loops: Animation.Infinite
                    PauseAnimation { duration: index * 700 }
                    NumberAnimation { from: 0.5; to: 0.0; duration: 2100; easing.type: Easing.OutCubic }
                }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            antialiasing: true
            gradient: Gradient {
                GradientStop { position: 0.0
                    color: graph.alpha(graph.tint, graph.hubLive ? 0.58 : 0.20) }
                GradientStop { position: 1.0
                    color: graph.alpha(graph.tint, graph.hubLive ? 0.26 : 0.08) }
            }
            border.width: 1.5
            border.color: graph.alpha(graph.tint, graph.hubLive ? 0.8 : 0.30)

            scale: hubTap.pressed ? 0.94 : (hubHover.hovered ? 1.05 : 1.0)
            Behavior on scale { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

            Text {
                anchors.centerIn: parent
                text: graph.hubGlyph
                color: graph.hubLive ? Colors.fg : Colors.fgDim
                opacity: graph.hubLive ? 1 : 0.55
                font.family: graph.mono
                font.pixelSize: 30
            }

            HoverHandler { id: hubHover }
            TapHandler { id: hubTap; onTapped: graph.hubActivated() }
            WheelHandler {
                onWheel: event => {
                    graph.hubScrolled(event.angleDelta.y > 0 ? 1 : -1);
                    event.accepted = true;
                }
            }
        }
    }

    Repeater {
        model: graph.model

        OrbitNode {
            required property var modelData
            required property int index

            readonly property var pos: graph.positions[index]
                                    || ({ x: graph.cx, y: graph.cy, depth: 1 })

            visible: index < graph.positions.length
            item: modelData
            tint: graph.tint
            mono: graph.mono
            depth: pos.depth

            x: pos.x - width / 2
            y: pos.y - height / 2

            z: hovered ? 500 : (pos.depth > 0.5 ? 20 : 10)

            appearDelay: 60 + index * 55
            onActivated: graph.picked(modelData)
            onScrolled: d => graph.itemScrolled(modelData, d)
            onHoverToggled: on => {
                graph.hoverCount = Math.max(0, graph.hoverCount + (on ? 1 : -1));
                graph.hoveredItem = on ? modelData
                                       : (graph.hoverCount > 0 ? graph.hoveredItem : null);
            }
        }
    }
}
