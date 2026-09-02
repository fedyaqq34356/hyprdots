import Quickshell
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property var strokes: []
    property int hue: 0

    readonly property var palette: [
        Colors.accent, Colors.accentAlt, Colors.bad, Colors.good, Colors.fg
    ]
    readonly property color ink: root.palette[root.hue % root.palette.length]

    function toggle() {
        root.shown = !root.shown;
        Sfx.panel(root.shown);
    }

    function close() {
        if (!root.shown)
            return;
        root.shown = false;
        Sfx.panelOut();
    }

    function clear() {
        root.strokes = [];
        Sfx.toggleOff();
    }

    function undo() {
        if (root.strokes.length === 0)
            return;
        root.strokes = root.strokes.slice(0, -1);
        Sfx.pick();
    }

    PanelWindow {
            id: win

            WlrLayershell.namespace: "qs-draw"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            screen: Focus.screen
            visible: root.shown

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.10)
            }

            Canvas {
                id: sheet
                anchors.fill: parent
                renderStrategy: Canvas.Cooperative
                antialiasing: true

                property var live: []

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.lineCap = "round";
                    ctx.lineJoin = "round";

                    function draw(stroke) {
                        if (stroke.points.length < 2)
                            return;
                        ctx.strokeStyle = stroke.color;
                        ctx.lineWidth = stroke.width;
                        ctx.beginPath();
                        ctx.moveTo(stroke.points[0].x, stroke.points[0].y);
                        for (let i = 1; i < stroke.points.length - 1; i++) {
                            const a = stroke.points[i];
                            const b = stroke.points[i + 1];
                            ctx.quadraticCurveTo(a.x, a.y, (a.x + b.x) / 2, (a.y + b.y) / 2);
                        }
                        const last = stroke.points[stroke.points.length - 1];
                        ctx.lineTo(last.x, last.y);
                        ctx.stroke();
                    }

                    for (const s of root.strokes)
                        draw(s);
                    if (sheet.live.length > 1)
                        draw({ points: sheet.live, color: root.ink, width: 4 });
                }
            }

            Connections {
                target: root
                function onStrokesChanged() { sheet.requestPaint(); }
                function onHueChanged() { sheet.requestPaint(); }
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor

                onPressed: (mouse) => {
                    sheet.live = [{ x: mouse.x, y: mouse.y }];
                    Sfx.tick();
                }

                onPositionChanged: (mouse) => {
                    if (!pressed)
                        return;
                    const pts = sheet.live.slice();
                    pts.push({ x: mouse.x, y: mouse.y });
                    sheet.live = pts;
                    sheet.requestPaint();
                }

                onReleased: {
                    if (sheet.live.length > 1) {
                        const all = root.strokes.slice();
                        all.push({
                            points: sheet.live,
                            color: String(root.ink),
                            width: 4
                        });
                        root.strokes = all;
                    }
                    sheet.live = [];
                    sheet.requestPaint();
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 42
                width: tools.implicitWidth + 32
                height: 62
                radius: 22
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.92)
                antialiasing: true

                Sheen {
                    anchors.fill: parent
                    radius: parent.radius
                    edgeOpacity: 0.2
                }

                Row {
                    id: tools
                    anchors.centerIn: parent
                    spacing: 10

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        radius: 15
                        color: root.ink
                        border.width: 2
                        border.color: Qt.rgba(1, 1, 1, 0.2)
                        Behavior on color { ColorAnimation { duration: Motion.fast } }

                        TapHandler {
                            onTapped: {
                                root.hue = root.hue + 1;
                                Sfx.pick();
                            }
                        }
                    }

                    IconButton {
                        glyph: "󰕌"
                        tip: I18n.t("act.undo")
                        tint: Colors.accentAlt
                        onActivated: root.undo()
                    }

                    IconButton {
                        glyph: "󰩹"
                        tip: I18n.t("act.clearAll")
                        tint: Colors.bad
                        onActivated: root.clear()
                    }

                    IconButton {
                        glyph: "󰄬"
                        tip: I18n.t("act.close")
                        tint: Colors.good
                        onActivated: root.close()
                    }
                }
            }

            Item {
                anchors.fill: parent
                focus: true
                Keys.onEscapePressed: root.close()
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Z && (event.modifiers & Qt.ControlModifier))
                        root.undo();
                    else if (event.key === Qt.Key_C)
                        root.clear();
                }
            }
        }
    
}
