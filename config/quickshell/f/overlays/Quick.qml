import Quickshell
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property var draw: null
    property var dock: null
    property var desk: null

    property bool open: false
    property real anchorY: 0.42

    property var timerPanel: null

    readonly property var soon: Timers.soonest
    readonly property bool timerRunning: root.soon !== null && !root.soon.ringing
    readonly property real timerProgress: Timers.progress(root.soon)

    function openTimer() {
        if (Timers.anyRinging) {
            Timers.dismissAll();
            return;
        }
        if (root.timerPanel)
            root.timerPanel.open("count");
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-quick"
        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        anchors {
            top: true
            bottom: true
            right: true
        }

        implicitWidth: 240
        exclusiveZone: 0
        color: "transparent"

        mask: Region {
            x: island.x
            y: island.y
            width: island.width
            height: island.height
        }

        Item {
            id: island

            x: win.width - width - (root.open ? 18 : 6)
            y: root.anchorY * win.height
            width: root.open ? column.implicitWidth + 26 : 26
            height: root.open ? column.implicitHeight + 26 : 74

            Behavior on x {
                NumberAnimation {
                    duration: Motion.base
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.expo
                }
            }
            Behavior on width { Spring {} }
            Behavior on height { Spring {} }

            Rectangle {
                anchors.fill: parent
                radius: root.open ? 26 : 13
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b,
                               root.open ? 0.92 : 0.55)
                antialiasing: true

                Behavior on radius { NumberAnimation { duration: Motion.base } }
                Behavior on color { ColorAnimation { duration: Motion.base } }

                Sheen {
                    anchors.fill: parent
                    radius: parent.radius
                    edgeOpacity: root.open ? 0.2 : 0.1
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 3
                opacity: root.open ? 0 : 1
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.soon !== null
                    text: Timers.clock(Timers.left(root.soon))
                    color: Timers.anyRinging ? Colors.bad : Colors.accent
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 9
                    rotation: 90
                }

                Repeater {
                    model: root.soon !== null ? 0 : 3

                    Rectangle {
                        width: 4
                        height: 4
                        radius: 2
                        color: Colors.fgDim
                        opacity: 0.55
                    }
                }
            }

            Column {
                id: column

                anchors.centerIn: parent
                spacing: 8
                opacity: root.open ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Motion.base } }

                IconButton {
                    glyph: "󰽉"
                    tip: I18n.t("quick.draw")
                    tint: Colors.accent
                    onActivated: if (root.draw) root.draw.toggle()
                }

                Item {
                    width: 36
                    height: 36

                    Canvas {
                        id: ring
                        anchors.fill: parent
                        antialiasing: true

                        readonly property real p: root.timerProgress
                        onPChanged: ring.requestPaint()

                        onPaint: {
                            const ctx = getContext("2d");
                            ctx.reset();
                            if (ring.p <= 0)
                                return;
                            ctx.lineWidth = 2;
                            ctx.lineCap = "round";
                            ctx.strokeStyle = Timers.anyRinging ? Colors.bad : Colors.accentAlt;
                            ctx.beginPath();
                            ctx.arc(width / 2, height / 2, width / 2 - 2,
                                    -Math.PI / 2,
                                    -Math.PI / 2 + Math.PI * 2 * ring.p);
                            ctx.stroke();
                        }
                    }

                    IconButton {
                        anchors.fill: parent
                        glyph: Timers.anyRinging ? "󰂚"
                             : (root.timerRunning ? "󰔛" : "󰔟")
                        tip: Timers.anyRinging
                            ? I18n.t("timer.dismiss")
                            : (root.soon ? Timers.clock(Timers.left(root.soon))
                                         : I18n.t("timer.title"))
                        tint: Timers.anyRinging ? Colors.bad : Colors.accentAlt
                        onActivated: root.openTimer()
                    }
                }

                IconButton {
                    glyph: "󰍛"
                    tip: Sys.cpu >= 0
                        ? "cpu " + Math.round(Sys.cpu) + "%  ram " + Math.round(Sys.mem) + "%"
                        : I18n.t("quick.load")
                    tint: Sys.cpu > 85 ? Colors.bad : Colors.good
                    onActivated: Sfx.usage()

                    Component.onCompleted: Sys.acquire()
                    Component.onDestruction: Sys.release()
                }

                IconButton {
                    glyph: "󰕰"
                    tip: root.dock && root.dock.pinned ? I18n.t("quick.unpinDock") : I18n.t("quick.pinDock")
                    tint: root.dock && root.dock.pinned ? Colors.accent : Colors.fgDim
                    onActivated: if (root.dock) root.dock.toggle()
                }

                IconButton {
                    glyph: "󰕮"
                    tip: I18n.t("quick.deskEdit")
                    tint: Colors.accentAlt
                    onActivated: if (root.desk) root.desk.toggle()
                }
            }

            HoverHandler {
                onHoveredChanged: {
                    if (hovered && !root.open) {
                        root.open = true;
                        Sfx.open();
                    } else if (!hovered && root.open) {
                        closeDelay.restart();
                    }
                }
            }

            DragHandler {
                yAxis.enabled: true
                xAxis.enabled: false
                onActiveChanged: {
                    if (active)
                        return;
                    root.anchorY = Math.max(0.02,
                        Math.min(0.9, island.y / win.height));
                    Sfx.fill();
                }
            }

            Timer {
                id: closeDelay
                interval: 400
                onTriggered: {
                    root.open = false;
                    Sfx.panelOut();
                }
            }
        }
    }
}
