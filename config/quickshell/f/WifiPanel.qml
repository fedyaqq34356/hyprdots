import Quickshell
import Quickshell.Hyprland
import QtQuick

Scope {
    id: root

    property bool shown: false
    property string pendingSsid: ""

    function toggle() { root.shown = !root.shown; }
    function close()   { root.shown = false; }

    onShownChanged: {
        if (shown) {
            root.pendingSsid = "";
            password.text = "";
            Network.refresh();
            Network.rescan();
        }
        // Throughput is only sampled while the panel is actually on screen.
        Network.sampling = shown;
    }

    function bars(strength) {
        if (strength >= 75) return "󰤨";
        if (strength >= 50) return "󰤥";
        if (strength >= 25) return "󰤢";
        return "󰤟";
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
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
            opacity: root.shown ? 0.30 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.16
            width: 400
            height: body.implicitHeight + 36
            radius: 22
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
            border.width: 1
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30)

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 190 } }
            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }
            Behavior on height { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

            focus: true
            Keys.onEscapePressed: root.close()

            Column {
                id: body
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        text: Network.glyph
                        color: Network.connected ? Colors.accent : Colors.fgDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 18
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        width: parent.width - 110
                        spacing: 2
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            text: Network.connected ? Network.ssid
                                : Network.radio ? "Не подключено" : "Wi-Fi выключен"
                            color: Colors.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                            width: parent.width
                        }

                        Text {
                            visible: Network.connected
                            text: {
                                const parts = ["сигнал " + Network.strength + "%"];
                                if (Network.linkRate !== "") parts.push(Network.linkRate);
                                return parts.join("  ·  ");
                            }
                            color: Colors.fgDim
                            opacity: 0.6
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }

                        Row {
                            visible: Network.connected
                            spacing: 10

                            Text {
                                text: "↓ " + Network.human(Network.rxRate)
                                color: Colors.fgDim
                                opacity: 0.85
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }

                            Text {
                                text: "↑ " + Network.human(Network.txRate)
                                color: Colors.fgDim
                                opacity: 0.5
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }
                        }
                    }

                    Rectangle {
                        width: 62
                        height: 26
                        radius: 9
                        anchors.verticalCenter: parent.verticalCenter
                        color: Network.radio
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.18)
                            : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.5)

                        Text {
                            anchors.centerIn: parent
                            text: Network.radio ? "вкл" : "выкл"
                            color: Network.radio ? Colors.accent : Colors.fgDim
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Network.toggleRadio()
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.18)
                }

                Column {
                    width: parent.width
                    spacing: 3
                    visible: Network.radio

                    Repeater {
                        model: Network.networks.slice(0, 8)

                        Rectangle {
                            id: row
                            required property var modelData

                            width: parent.width
                            height: 34
                            radius: 10
                            color: modelData.active
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.14)
                                : hover.hovered
                                    ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.45)
                                    : "transparent"
                            Behavior on color { ColorAnimation { duration: 140 } }

                            HoverHandler { id: hover }

                            Row {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 9

                                Text {
                                    text: root.bars(row.modelData.strength)
                                    color: row.modelData.active ? Colors.accent : Colors.fgDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    width: parent.width - 90
                                    text: row.modelData.ssid
                                    color: row.modelData.active ? Colors.fg : Colors.fgDim
                                    elide: Text.ElideRight
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    visible: row.modelData.secured
                                    text: "󰌾"
                                    color: Colors.fgDim
                                    opacity: 0.5
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (row.modelData.active) {
                                        Network.disconnect();
                                        return;
                                    }
                                    if (row.modelData.secured) {
                                        root.pendingSsid = row.modelData.ssid;
                                        password.text = "";
                                        password.forceActiveFocus();
                                    } else {
                                        Network.connect(row.modelData.ssid, "");
                                    }
                                }
                            }
                        }
                    }
                }

                // Password prompt, shown only after picking a secured network.
                Rectangle {
                    width: parent.width
                    height: 38
                    radius: 11
                    visible: root.pendingSsid !== ""
                    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
                    border.width: 1
                    border.color: password.activeFocus
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.55)
                        : "transparent"

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 9

                        Text {
                            text: "󰌾"
                            color: Colors.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: password
                            width: parent.width - 40
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 12
                            echoMode: TextInput.Password
                            selectByMouse: true
                            clip: true

                            onAccepted: {
                                Network.connect(root.pendingSsid, text);
                                root.pendingSsid = "";
                                text = "";
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: password.text === ""
                                text: "пароль для " + root.pendingSsid + ", Enter"
                                color: Colors.fgDim
                                opacity: 0.45
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }
                        }
                    }
                }

                Text {
                    width: parent.width
                    visible: Network.error !== ""
                    text: Network.error
                    color: Colors.bad
                    wrapMode: Text.WordWrap
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }
        }
    }
}
