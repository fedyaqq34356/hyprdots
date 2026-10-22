import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/services"

Scope {
    id: root

    property string phase: "closed"
    property int selected: 0
    property var pending: null

    readonly property var actions: [
        { key: "l", glyph: "󰌾", label: I18n.t("power.lock"), farewell: false,
          run: ["/bin/sh", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/lock/lock.sh"] },
        { key: "s", glyph: "󰒲", label: I18n.t("power.sleep"), farewell: false,
          run: ["loginctl", "suspend"] },
        { key: "e", glyph: "󰗽", label: I18n.t("power.logout"), farewell: true,
          run: ["hyprctl", "dispatch", "exit"] },
        { key: "r", glyph: "󰜉", label: I18n.t("power.reboot"), farewell: true,
          run: ["loginctl", "reboot"] },
        { key: "p", glyph: "󰐥", label: I18n.t("power.shutdown"), farewell: true,
          run: ["loginctl", "poweroff"] }
    ]

    function toggle() { phase === "open" ? close() : open(); }

    function open() {
        if (phase === "open" || phase === "firing")
            return;
        selected = 0;
        phase = "open";
        uptime.running = true;
        Sfx.panel(true);
    }

    function close() {
        if (phase !== "open")
            return;
        phase = "closing";
        Sfx.panel(false);
    }

    function fire(i) {
        if (phase !== "open")
            return;
        selected = i;
        pending = actions[i];
        phase = "firing";
        Sfx.tapAlt();
    }

    Process { id: runner }

    function finish() {
        const a = pending;
        pending = null;
        phase = "closed";
        if (!a)
            return;
        if (a.farewell) {
            Sfx.sessionExit();
            Bye.run(a.run);
        } else {
            runner.command = a.run;
            runner.running = true;
        }
    }

    property string uptimeText: ""
    Process {
        id: uptime
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeText = text.trim().replace(/^up\s+/, "")
        }
    }

    property real p: 0
    Behavior on p {
        NumberAnimation {
            duration: root.phase === "open" ? 420 : 300
            easing.type: root.phase === "open" ? Easing.OutCubic : Easing.InCubic
        }
    }
    onPhaseChanged: {
        if (phase === "open")
            p = 1;
        else if (phase === "closing")
            p = 0;
        else if (phase === "closed")
            p = 0;
    }
    onPChanged: if (phase === "closing" && p === 0) phase = "closed"

    PanelWindow {
        id: win
        WlrLayershell.namespace: "qs-power"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: root.phase === "open" ? WlrKeyboardFocus.Exclusive
                                                          : WlrKeyboardFocus.None
        screen: Focus.screen
        visible: root.phase !== "closed"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"

        Item {
            id: stage
            anchors.fill: parent
            focus: true

            readonly property real d: 84
            readonly property real gap: 26

            Keys.onPressed: e => {
                if (root.phase !== "open")
                    return;
                const k = e.key;
                if (k === Qt.Key_Escape) {
                    root.close();
                } else if (k === Qt.Key_Left || k === Qt.Key_H || k === Qt.Key_Backtab) {
                    root.selected = (root.selected + root.actions.length - 1) % root.actions.length;
                } else if (k === Qt.Key_Right || k === Qt.Key_Tab) {
                    root.selected = (root.selected + 1) % root.actions.length;
                } else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space) {
                    root.fire(root.selected);
                } else {
                    const t = e.text.toLowerCase();
                    const i = root.actions.findIndex(a => a.key === t);
                    if (i < 0)
                        return;
                    root.fire(i);
                }
                e.accepted = true;
            }

            Connections {
                target: root
                function onPhaseChanged() {
                    if (root.phase === "open")
                        stage.forceActiveFocus();
                }
            }

            Rectangle {
                anchors.fill: parent
                opacity: root.p
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.alpha(Colors.bg, 0.78) }
                    GradientStop { position: 0.5; color: Qt.alpha(Colors.bg, 0.52) }
                    GradientStop { position: 1.0; color: Qt.alpha(Colors.bg, 0.82) }
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            Item {
                id: group
                anchors.centerIn: parent
                width: row.width
                height: row.height
                opacity: root.p
                scale: 0.94 + 0.06 * root.p
                transform: Translate { y: 18 * (1 - root.p) }

                Rectangle {
                    id: glow
                    width: stage.d * 1.9
                    height: width
                    radius: width / 2
                    x: lens.x + lens.width / 2 - width / 2
                    y: lens.y + lens.height / 2 - height / 2
                    color: Colors.accent
                    property real breath: 0.5
                    opacity: root.phase === "firing" ? 0 : 0.18 + 0.14 * breath
                    Behavior on opacity { NumberAnimation { duration: 260 } }
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blur: 1.0
                        blurMax: 48
                    }
                    SequentialAnimation on breath {
                        running: root.phase === "open"
                        loops: Animation.Infinite
                        NumberAnimation { to: 1; duration: 3500; easing.type: Easing.InOutSine }
                        NumberAnimation { to: 0; duration: 3500; easing.type: Easing.InOutSine }
                    }
                }

                Rectangle {
                    id: lens
                    width: stage.d
                    height: stage.d
                    radius: width / 2
                    x: root.selected * (stage.d + stage.gap)
                    Behavior on x {
                        NumberAnimation { duration: 380; easing.type: Easing.OutCubic }
                    }
                    color: root.phase === "firing" ? Colors.bg : Colors.accent
                    Behavior on color { ColorAnimation { duration: 520; easing.type: Easing.InOutCubic } }

                    property real grow: 1
                    scale: grow
                    NumberAnimation on grow {
                        id: burst
                        running: false
                        to: Math.hypot(stage.width, stage.height) / stage.d * 1.1
                        duration: 620
                        easing.type: Easing.InOutCubic
                        onFinished: root.finish()
                    }
                    Connections {
                        target: root
                        function onPhaseChanged() {
                            if (root.phase === "firing") {
                                burst.restart();
                            } else if (root.phase === "open") {
                                burst.stop();
                                lens.grow = 1;
                            }
                        }
                    }
                    z: root.phase === "firing" ? 10 : 0
                }

                Row {
                    id: row
                    spacing: stage.gap
                    z: 1

                    Repeater {
                        model: root.actions
                        Item {
                            id: cell
                            required property var modelData
                            required property int index
                            readonly property bool on: root.selected === index
                            width: stage.d
                            height: stage.d
                            opacity: root.phase === "firing" && !on ? 0 : 1
                            Behavior on opacity { NumberAnimation { duration: 200 } }

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: Qt.alpha(Colors.surface2, 0.42)
                                border.width: 1
                                border.color: Qt.alpha(Colors.fg, 0.08)
                                opacity: cell.on ? 0 : 1
                                Behavior on opacity { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            }

                            Text {
                                anchors.centerIn: parent
                                text: cell.modelData.glyph
                                font.family: Fonts.glyph
                                font.pixelSize: 30
                                color: cell.on ? Colors.accentText : Colors.fg
                                Behavior on color { ColorAnimation { duration: 260 } }
                                scale: cell.on ? 1.06 : 1
                                Behavior on scale { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                                opacity: root.phase === "firing" ? 0 : 1
                                Behavior on opacity { NumberAnimation { duration: 160 } }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: if (root.phase === "open") root.selected = cell.index
                                onClicked: root.fire(cell.index)
                            }
                        }
                    }
                }

                Item {
                    id: caption
                    anchors.top: row.bottom
                    anchors.topMargin: 30
                    anchors.horizontalCenter: row.horizontalCenter
                    width: 360
                    height: 30
                    opacity: root.phase === "firing" ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: 180 } }

                    property string shown: root.actions[root.selected].label
                    property string leaving: ""
                    property real t: 1

                    Connections {
                        target: root
                        function onSelectedChanged() {
                            caption.leaving = caption.shown;
                            caption.shown = root.actions[root.selected].label;
                            swap.restart();
                        }
                    }
                    NumberAnimation {
                        id: swap
                        target: caption; property: "t"
                        from: 0; to: 1; duration: 320
                        easing.type: Easing.OutCubic
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -8 * caption.t
                        opacity: 1 - caption.t
                        text: caption.leaving
                        font.family: Fonts.display
                        font.pixelSize: Fonts.larger
                        font.weight: Font.Medium
                        color: Colors.fg
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 8 * (1 - caption.t)
                        opacity: caption.t
                        text: caption.shown
                        font.family: Fonts.display
                        font.pixelSize: Fonts.larger
                        font.weight: Font.Medium
                        color: Colors.fg
                    }
                }

                Text {
                    anchors.top: caption.bottom
                    anchors.topMargin: 10
                    anchors.horizontalCenter: row.horizontalCenter
                    text: root.uptimeText
                    font.family: Fonts.mono
                    font.pixelSize: Fonts.small
                    font.features: Fonts.nums
                    color: Colors.fgDim
                    opacity: root.phase === "firing" ? 0 : 0.55
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                }
            }
        }
    }

    IpcHandler {
        target: "power"
        function toggle(): string { root.toggle(); return root.phase; }
        function close(): string { root.close(); return root.phase; }
    }
}
