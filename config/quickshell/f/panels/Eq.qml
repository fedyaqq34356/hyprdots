import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (root.shown)
            Equalizer.rescan();
    }

    readonly property string mono: "JetBrainsMono Nerd Font"

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-eq"
        WlrLayershell.layer: WlrLayer.Overlay

        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Glass {
            id: card

            anchors.centerIn: parent
            width: 620
            height: 372
            radius: 34
            elevation: 3

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                NumberAnimation {
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.snap
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 30
                spacing: 16

                Row {
                    width: parent.width

                    Text {
                        text: I18n.t("eq.title")
                        color: Colors.fg
                        font.family: Fonts.display
                        font.pixelSize: Fonts.titleSize
                    }

                    Item { width: parent.width - 260; height: 1 }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Equalizer.available
                            ? I18n.t("eq." + Equalizer.preset) || Equalizer.preset
                            : I18n.t("eq.inactive")
                        color: Equalizer.available ? Colors.accent : Colors.warn
                        opacity: 0.85
                        font.family: root.mono
                        font.pixelSize: 11
                    }
                }

                Item {
                    id: graph

                    width: parent.width
                    height: 190

                    readonly property real bandStep: width / Equalizer.bands
                    readonly property real mid: height / 2

                    Rectangle {
                        anchors.fill: parent
                        radius: 18
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.35)
                    }

                    Repeater {
                        model: [-6, 0, 6]

                        Rectangle {
                            required property int modelData

                            width: graph.width - 24
                            height: 1
                            x: 12
                            y: graph.mid - modelData / Equalizer.range * (graph.height / 2 - 16)
                            color: Colors.outline
                            opacity: modelData === 0 ? 0.35 : 0.15
                        }
                    }

                    Canvas {
                        id: spectrum

                        anchors.fill: parent
                        anchors.margins: 12
                        renderStrategy: Canvas.Cooperative
                        opacity: 0.5
                        visible: Media.playing

                        Connections {
                            target: Cava
                            enabled: root.shown && Media.playing
                            function onLevelsChanged() { spectrum.requestPaint(); }
                        }

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            const n = Cava.bars;
                            if (n <= 0)
                                return;

                            const step = width / n;
                            ctx.beginPath();
                            ctx.moveTo(0, height);
                            for (let i = 0; i < n; i++) {
                                const v = Math.min(1, (Cava.levels[i] || 0) * 1.6);
                                const x = i * step + step / 2;
                                const y = height - v * height * 0.9;
                                if (i === 0)
                                    ctx.lineTo(x, y);
                                else {
                                    const px = (i - 1) * step + step / 2;
                                    const pv = Math.min(1, (Cava.levels[i - 1] || 0) * 1.6);
                                    const py = height - pv * height * 0.9;
                                    ctx.bezierCurveTo((px + x) / 2, py, (px + x) / 2, y, x, y);
                                }
                            }
                            ctx.lineTo(width, height);
                            ctx.closePath();

                            const grad = ctx.createLinearGradient(0, 0, 0, height);
                            grad.addColorStop(0, Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                                         Colors.accentAlt.b, 0.55));
                            grad.addColorStop(1, Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                                         Colors.accentAlt.b, 0.05));
                            ctx.fillStyle = grad;
                            ctx.fill();
                        }
                    }

                    Canvas {
                        id: curve

                        anchors.fill: parent
                        anchors.margins: 12
                        renderStrategy: Canvas.Cooperative
                        antialiasing: true

                        Connections {
                            target: Equalizer
                            function onGainsChanged() { curve.requestPaint(); }
                        }

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();

                            const lo = Math.log(20) / Math.LN10;
                            const hi = Math.log(20000) / Math.LN10;
                            const half = height / 2;

                            const points = [];
                            for (let px = 0; px <= width; px += 3) {
                                const hz = Math.pow(10, lo + (hi - lo) * (px / width));
                                const db = Equalizer.responseAt(hz);
                                points.push({
                                    x: px,
                                    y: half - db / Equalizer.range * (half - 6)
                                });
                            }

                            ctx.beginPath();
                            ctx.moveTo(points[0].x, points[0].y);
                            for (let i = 1; i < points.length; i++)
                                ctx.lineTo(points[i].x, points[i].y);

                            ctx.save();
                            ctx.lineTo(width, half);
                            ctx.lineTo(0, half);
                            ctx.closePath();
                            const grad = ctx.createLinearGradient(0, 0, 0, height);
                            grad.addColorStop(0, Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                         Colors.accent.b, 0.28));
                            grad.addColorStop(0.5, Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                           Colors.accent.b, 0.08));
                            grad.addColorStop(1, Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                         Colors.accent.b, 0.28));
                            ctx.fillStyle = grad;
                            ctx.fill();
                            ctx.restore();

                            ctx.beginPath();
                            ctx.moveTo(points[0].x, points[0].y);
                            for (let i = 1; i < points.length; i++)
                                ctx.lineTo(points[i].x, points[i].y);
                            ctx.strokeStyle = Colors.accent;
                            ctx.lineWidth = 2;
                            ctx.lineJoin = "round";
                            ctx.stroke();
                        }
                    }

                    Repeater {
                        model: Equalizer.bands

                        Item {
                            id: band

                            required property int index

                            readonly property real gain: Equalizer.gains[index]

                            x: 12 + (graph.width - 24) * (Math.log(Equalizer.freqs[index] / 20)
                                / Math.log(1000)) - width / 2
                            y: 0
                            width: 34
                            height: graph.height

                            readonly property real knobY:
                                graph.mid - band.gain / Equalizer.range * (graph.height / 2 - 18)

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: Math.min(graph.mid, band.knobY)
                                width: 2
                                height: Math.abs(band.knobY - graph.mid)
                                radius: 1
                                color: Colors.accent
                                opacity: 0.35
                            }

                            Rectangle {
                                id: knob

                                anchors.horizontalCenter: parent.horizontalCenter
                                y: band.knobY - height / 2
                                width: drag.active ? 18 : 14
                                height: width
                                radius: width / 2
                                color: drag.active || hover.hovered ? Colors.accent : Colors.bg
                                border.width: 2
                                border.color: Colors.accent

                                Behavior on width { Spring {} }
                                Behavior on color { ColorAnimation { duration: Motion.fast } }
                                Behavior on y {
                                    enabled: !drag.active
                                    NumberAnimation {
                                        duration: Motion.base
                                        easing.type: Easing.Bezier
                                        easing.bezierCurve: Motion.decel
                                    }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: band.knobY - 30
                                text: (band.gain > 0 ? "+" : "") + band.gain.toFixed(1)
                                color: Colors.accent
                                opacity: drag.active || hover.hovered ? 1 : 0
                                font.family: root.mono
                                font.pixelSize: 9
                                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                            }

                            HoverHandler { id: hover }

                            DragHandler {
                                id: drag

                                target: null
                                yAxis.enabled: true
                                xAxis.enabled: false

                                onCentroidChanged: {
                                    if (!drag.active)
                                        return;
                                    const y = drag.centroid.position.y;
                                    const db = (graph.mid - y) / (graph.height / 2 - 18)
                                             * Equalizer.range;
                                    const snapped = Math.round(db * 2) / 2;
                                    if (Math.abs(snapped - band.gain) < 0.25)
                                        return;
                                    Equalizer.setGain(band.index, snapped);
                                    Sfx.tick();
                                }

                                onActiveChanged: if (!drag.active) Sfx.tap()
                            }

                            TapHandler {
                                onDoubleTapped: {
                                    Equalizer.setGain(band.index, 0);
                                    Sfx.toggleOff();
                                }
                            }
                        }
                    }
                }

                Row {
                    width: parent.width

                    Repeater {
                        model: Equalizer.labels

                        Text {
                            required property string modelData
                            required property int index

                            width: graph.width / Equalizer.bands
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData
                            color: Colors.fgDim
                            opacity: 0.45
                            font.family: root.mono
                            font.pixelSize: 9
                        }
                    }
                }

                Flow {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: Equalizer.presetNames

                        Rectangle {
                            id: pill

                            required property string modelData

                            readonly property bool active: Equalizer.preset === modelData

                            width: pillText.implicitWidth + 20
                            height: 26
                            radius: 10
                            color: pill.active
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.2)
                                : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.5)
                            border.width: 1
                            border.color: pill.active
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.5)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            scale: presetTap.pressed ? 0.95 : 1
                            Behavior on scale { Spring {} }

                            Text {
                                id: pillText
                                anchors.centerIn: parent
                                text: I18n.t("eq." + pill.modelData) || pill.modelData
                                color: pill.active ? Colors.accent : Colors.fgDim
                                font.family: root.mono
                                font.pixelSize: 10
                            }

                            TapHandler {
                                id: presetTap
                                onTapped: {
                                    Equalizer.apply(pill.modelData);
                                    Sfx.pick();
                                }
                            }
                        }
                    }
                }
            }

            Keys.onEscapePressed: root.close()
        }
    }
}
