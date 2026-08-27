import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick
import Quickshell.Wayland

Scope {
    id: root

    property bool shown: false
    property int selected: 0

    readonly property var actions: [
        {
            key: "l", glyph: "󰌾", label: "Заблокировать",
            hint: "экран гаснет, сессия остаётся",
            run: ["/bin/sh", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"]
        },
        {
            key: "s", glyph: "󰒲", label: "Сон",
            hint: "в память, просыпается мгновенно",
            run: ["loginctl", "suspend"]
        },
        {
            key: "e", glyph: "󰗽", label: "Выйти",
            hint: "закрыть сессию Hyprland",
            run: ["hyprctl", "dispatch", "exit"]
        },
        {
            key: "r", glyph: "󰜉", label: "Перезагрузка",
            hint: "все программы будут закрыты",
            danger: true,
            run: ["loginctl", "reboot"]
        },
        {
            key: "p", glyph: "󰐥", label: "Выключить",
            hint: "все программы будут закрыты",
            danger: true,
            run: ["loginctl", "poweroff"]
        }
    ]

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: {
        if (shown) {
            selected = 0;
            uptime.running = true;
            card.forceActiveFocus();
        }
    }

    Process { id: runner }

    readonly property var farewell: ["e", "r", "p"]

    function activate(index) {
        const action = root.actions[index];
        if (!action) return;
        root.close();

        if (root.farewell.indexOf(action.key) !== -1) {
            Bye.run(action.run);
            return;
        }

        runner.command = action.run;
        runner.running = true;
    }

    function activateKey(text) {
        for (let i = 0; i < root.actions.length; i++) {
            if (root.actions[i].key === text.toLowerCase()) {
                root.activate(i);
                return true;
            }
        }
        return false;
    }

    property string uptimeText: ""

    Process {
        id: uptime
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeText = text.trim()
        }
    }

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-power"
        id: win
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.62 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        FocusScope {
            id: card
            anchors.centerIn: parent
            width: column.implicitWidth + 76
            height: column.implicitHeight + 56
            focus: true

            Rectangle {
                anchors.fill: parent
                radius: 30
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.72)
                border.width: 1
                border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                      Colors.outline.b, 0.20)
            }

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale {
                NumberAnimation { duration: 300; easing.type: Easing.OutBack }
            }

            Keys.onEscapePressed: root.close()
            Keys.onLeftPressed: root.selected =
                (root.selected - 1 + root.actions.length) % root.actions.length
            Keys.onRightPressed: root.selected =
                (root.selected + 1) % root.actions.length
            Keys.onReturnPressed: root.activate(root.selected)
            Keys.onEnterPressed: root.activate(root.selected)
            Keys.onPressed: event => {
                if (event.text && root.activateKey(event.text)) event.accepted = true;
            }

            Column {
                id: column
                anchors.centerIn: parent
                spacing: 26

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 6

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Colors.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 46
                        font.weight: Font.Light
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            const parts = [];
                            if (root.uptimeText !== "") parts.push(root.uptimeText);
                            const dev = UPower.displayDevice;
                            if (dev && dev.isLaptopBattery)
                                parts.push(Math.round(dev.percentage * 100) + "% battery");
                            return parts.join("  ·  ");
                        }
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }
                }

                Row {
                    id: row
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 14

                    Repeater {
                        model: root.actions

                        Rectangle {
                            id: tile
                            required property var modelData
                            required property int index

                            readonly property bool current: root.selected === index
                            readonly property color tint:
                                modelData.danger ? Colors.bad : Colors.accent

                            width: 132
                            height: 132
                            radius: 20
                            color: current
                                ? Qt.rgba(tile.tint.r, tile.tint.g, tile.tint.b, 0.16)
                                : Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.85)
                            border.width: 1
                            border.color: current
                                ? Qt.rgba(tile.tint.r, tile.tint.g, tile.tint.b, 0.65)
                                : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.25)

                            scale: current ? 1.06 : 1.0

                            Behavior on color { ColorAnimation { duration: 180 } }
                            Behavior on border.color { ColorAnimation { duration: 180 } }
                            Behavior on scale {
                                NumberAnimation { duration: 260; easing.type: Easing.OutBack }
                            }

                            Rectangle {
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                                radius: parent.radius
                                color: "transparent"
                                border.width: 2
                                border.color: tile.tint
                                opacity: tile.current ? 0.35 : 0
                                scale: tile.current ? 1.12 : 1
                                z: -1
                                Behavior on opacity { NumberAnimation { duration: 260 } }
                                Behavior on scale { NumberAnimation { duration: 260 } }
                            }

                            Column {
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: tile.modelData.glyph
                                    color: tile.current ? tile.tint : Colors.fgDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 34
                                    Behavior on color { ColorAnimation { duration: 180 } }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: tile.modelData.label
                                    color: tile.current ? Colors.fg : Colors.fgDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    font.weight: tile.current ? Font.DemiBold : Font.Normal
                                }
                            }

                            Rectangle {
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 9
                                width: 16
                                height: 16
                                radius: 5
                                color: tile.current
                                    ? tile.tint
                                    : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                              Colors.outline.b, 0.22)

                                Text {
                                    anchors.centerIn: parent
                                    text: tile.modelData.key
                                    color: tile.current ? Colors.accentText : Colors.fgDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selected = tile.index
                                onClicked: root.activate(tile.index)
                            }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 14
                    text: root.actions[root.selected] ? root.actions[root.selected].hint : ""
                    color: Colors.fgDim
                    opacity: 0.55
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 11
                }
            }
        }
    }
}
