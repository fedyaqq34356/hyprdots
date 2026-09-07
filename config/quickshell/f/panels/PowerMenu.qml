import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property int selected: 0

    readonly property var actions: [
        {
            key: "l", glyph: "󰌾", label: I18n.t("power.lock"),
            hint: I18n.t("power.lockSub"),
            run: ["/bin/sh", "-c", Quickshell.env("HOME") + "/.config/hypr/scripts/lock.sh"]
        },
        {
            key: "s", glyph: "󰒲", label: I18n.t("power.sleep"),
            hint: I18n.t("power.sleepSub"),
            run: ["loginctl", "suspend"]
        },
        {
            key: "e", glyph: "󰗽", label: I18n.t("power.logout"),
            hint: I18n.t("power.logoutSub"),
            run: ["hyprctl", "dispatch", "exit"]
        },
        {
            key: "r", glyph: "󰜉", label: I18n.t("power.reboot"),
            hint: I18n.t("power.warn"),
            danger: true,
            run: ["loginctl", "reboot"]
        },
        {
            key: "p", glyph: "󰐥", label: I18n.t("power.shutdown"),
            hint: I18n.t("power.warn"),
            danger: true,
            run: ["loginctl", "poweroff"]
        }
    ]

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (shown) {
            selected = 0;
            uptime.running = true;
            hostProbe.running = true;
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
            Sfx.sessionExit();
            Bye.run(action.run);
            return;
        }

        Sfx.tapAlt();
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
    property string hostText: ""

    Process {
        id: uptime
        command: ["uptime", "-p"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeText = text.trim()
        }
    }

    Process {
        id: hostProbe
        command: ["hostname"]
        stdout: StdioCollector {
            onStreamFinished: root.hostText = text.trim()
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
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.80) }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.62) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.86) }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            anchors.centerIn: card
            width: card.width * 1.5
            height: card.height * 1.7
            radius: width / 2
            color: {
                const a = root.actions[root.selected];
                return a && a.danger ? Colors.bad : Colors.accent;
            }
            opacity: root.shown ? 0.13 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.slow } }
            Behavior on color { ColorAnimation { duration: Motion.base } }

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 64
            }
        }

        FocusScope {
            id: card
            anchors.centerIn: parent
            width: column.implicitWidth + 92
            height: column.implicitHeight + 72
            focus: true

            Glass {
                anchors.fill: parent
                radius: Shape.modal
                elevation: 3
                tintOpacity: 0.74
            }

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.95
            transform: Translate { y: root.shown ? 0 : 18
                Behavior on y {
                    NumberAnimation {
                        duration: Motion.slow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.expo
                    }
                }
            }

            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                SpringAnimation {
                    spring: Motion.panelSpring
                    damping: Motion.panelDamping
                    mass: Motion.panelMass
                    epsilon: 0.001
                }
            }

            Keys.onEscapePressed: root.close()
            Keys.onLeftPressed: {
                root.selected =
                    (root.selected - 1 + root.actions.length) % root.actions.length;
                Sfx.tick();
            }
            Keys.onRightPressed: {
                root.selected = (root.selected + 1) % root.actions.length;
                Sfx.tick();
            }
            Keys.onReturnPressed: root.activate(root.selected)
            Keys.onEnterPressed: root.activate(root.selected)
            Keys.onPressed: event => {
                if (event.text && root.activateKey(event.text)) event.accepted = true;
            }

            Column {
                id: column
                anchors.centerIn: parent
                spacing: 24

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 18

                    Item {
                        width: 62
                        height: 62
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: width / 2
                            antialiasing: true
                            color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                           Colors.accent.b, 0.14)
                        }

                        ClippingRectangle {
                            anchors.centerIn: parent
                            width: 54
                            height: 54
                            radius: 27
                            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                           Colors.bgAlt.b, 0.6)
                            border.width: 2
                            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                  Colors.accent.b, 0.7)

                            Image {
                                id: avatar
                                anchors.fill: parent
                                anchors.margins: 2
                                source: "file://" + Quickshell.env("HOME")
                                        + "/.local/share/avatar/avatar.png"
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 128
                                visible: status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !avatar.visible
                                text: "󰀄"
                                color: Colors.accent
                                font.family: Fonts.mono
                                font.pixelSize: 24
                            }
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 3

                        Text {
                            text: Quickshell.env("USER")
                                + (root.hostText !== "" ? "@" + root.hostText : "")
                            color: Colors.fg
                            font.family: Fonts.display
                            font.pixelSize: 17
                            font.weight: Font.DemiBold
                        }

                        Text {
                            text: {
                                const parts = [];
                                if (root.uptimeText !== "") parts.push(root.uptimeText);
                                const dev = UPower.displayDevice;
                                if (dev && dev.isLaptopBattery)
                                    parts.push(Math.round(dev.percentage * 100) + "%");
                                return parts.join("  ·  ");
                            }
                            color: Colors.fgDim
                            opacity: 0.65
                            font.family: Fonts.mono
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 1
                        height: 42
                        color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                       Colors.outline.b, 0.22)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Colors.fg
                        font.family: Fonts.mono
                        font.pixelSize: 40
                        font.weight: Font.Light
                    }
                }

                Item {
                    id: rack
                    anchors.horizontalCenter: parent.horizontalCenter
                    implicitWidth: row.implicitWidth
                    implicitHeight: row.implicitHeight

                    readonly property real tileW: 128
                    readonly property real tileStep: tileW + 14

                    readonly property color tint: {
                        const a = root.actions[root.selected];
                        return a && a.danger ? Colors.bad : Colors.accent;
                    }

                    Rectangle {
                        z: -2
                        y: -10
                        x: root.selected * rack.tileStep - 10
                        width: rack.tileW + 20
                        height: rack.tileW + 20
                        radius: Shape.modal + 10
                        color: rack.tint
                        opacity: 0.32

                        Behavior on x {
                            NumberAnimation {
                                duration: Motion.base
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.expo
                            }
                        }
                        Behavior on color { ColorAnimation { duration: Motion.base } }

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: 1.0
                            blurMax: 40
                        }
                    }

                    Rectangle {
                        z: -1
                        x: root.selected * rack.tileStep
                        width: rack.tileW
                        height: rack.tileW
                        radius: Shape.modal
                        antialiasing: true
                        color: Qt.rgba(rack.tint.r, rack.tint.g, rack.tint.b, 0.16)
                        border.width: 1.5
                        border.color: Qt.rgba(rack.tint.r, rack.tint.g, rack.tint.b, 0.75)

                        Behavior on x {
                            SpringAnimation {
                                spring: 4.0
                                damping: 0.55
                                mass: 0.8
                                epsilon: 0.25
                            }
                        }
                        Behavior on color { ColorAnimation { duration: Motion.base } }
                        Behavior on border.color { ColorAnimation { duration: Motion.base } }
                    }

                    Row {
                        id: row
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

                                width: rack.tileW
                                height: rack.tileW
                                radius: Shape.modal
                                antialiasing: true
                                color: current
                                    ? "transparent"
                                    : Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
                                border.width: 1
                                border.color: current
                                    ? "transparent"
                                    : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                              Colors.outline.b, 0.20)

                                scale: current ? 1.05 : 1.0

                                Behavior on color { ColorAnimation { duration: Motion.fast } }
                                Behavior on border.color { ColorAnimation { duration: Motion.fast } }
                                Behavior on scale { Spring {} }

                                Column {
                                    anchors.centerIn: parent
                                    spacing: 12

                                    Item {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        width: 54
                                        height: 54

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: width / 2
                                            antialiasing: true
                                            color: tile.current
                                                ? Qt.rgba(tile.tint.r, tile.tint.g,
                                                          tile.tint.b, 0.22)
                                                : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                          Colors.fgDim.b, 0.07)
                                            Behavior on color {
                                                ColorAnimation { duration: Motion.fast }
                                            }
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            text: tile.modelData.glyph
                                            color: tile.current ? tile.tint : Colors.fgDim
                                            opacity: tile.current ? 1 : 0.75
                                            font.family: Fonts.mono
                                            font.pixelSize: 27
                                            Behavior on color {
                                                ColorAnimation { duration: Motion.fast }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.horizontalCenter: parent.horizontalCenter
                                        text: tile.modelData.label
                                        color: tile.current ? Colors.fg : Colors.fgDim
                                        opacity: tile.current ? 1 : 0.7
                                        font.family: Fonts.display
                                        font.pixelSize: 12
                                        font.weight: tile.current ? Font.DemiBold : Font.Normal
                                    }
                                }

                                Rectangle {
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                    anchors.margins: 10
                                    width: 17
                                    height: 17
                                    radius: Shape.detail
                                    antialiasing: true
                                    color: tile.current
                                        ? tile.tint
                                        : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                  Colors.outline.b, 0.18)
                                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: tile.modelData.key
                                        color: tile.current ? Colors.accentText : Colors.fgDim
                                        font.family: Fonts.mono
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onEntered: {
                                        if (root.selected !== tile.index) {
                                            root.selected = tile.index;
                                            Sfx.tick();
                                        }
                                    }
                                    onClicked: root.activate(tile.index)
                                }
                            }
                        }
                    }
                }

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        height: 15
                        text: root.actions[root.selected]
                            ? root.actions[root.selected].hint : ""
                        color: root.actions[root.selected]
                               && root.actions[root.selected].danger
                            ? Colors.bad : Colors.fgDim
                        opacity: 0.7
                        font.family: Fonts.mono
                        font.pixelSize: 11
                        Behavior on color { ColorAnimation { duration: Motion.fast } }
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        component Cap: Rectangle {
                            property string label: ""
                            width: capText.implicitWidth + 14
                            height: 20
                            radius: Shape.detail
                            antialiasing: true
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.07)
                            border.width: 1
                            border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                  Colors.outline.b, 0.18)

                            Text {
                                id: capText
                                anchors.centerIn: parent
                                text: parent.label
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.65)
                                font.family: Fonts.mono
                                font.pixelSize: 9
                            }
                        }

                        Cap { label: "󰌍 󰌏  " + I18n.t("power.keyPick") }
                        Cap { label: "󰌑  " + I18n.t("power.keyRun") }
                        Cap { label: "esc  " + I18n.t("power.keyClose") }
                    }
                }
            }
        }
    }
}
