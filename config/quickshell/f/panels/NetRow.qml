import Quickshell.Bluetooth
import QtQuick
import "root:/design"
import "root:/services"

Rectangle {
    id: row

    property var entry: null
    property bool wifi: true
    property color tint: "#ffffff"
    property string mono: "JetBrainsMono Nerd Font"
    property bool expanded: false

    signal activated()
    signal forgetRequested()

    readonly property bool active: {
        if (!row.entry) return false;
        return row.wifi ? !!row.entry.active : !!row.entry.connected;
    }

    readonly property bool working: {
        if (!row.entry || row.wifi) return false;
        return row.entry.state === BluetoothDeviceState.Connecting
            || row.entry.state === BluetoothDeviceState.Disconnecting
            || !!row.entry.pairing;
    }

    readonly property int strength: row.wifi && row.entry ? row.entry.strength : 0

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    height: 48
    radius: 15

    color: row.active ? row.alpha(row.tint, 0.16)
         : hover.hovered ? row.alpha(Colors.bgAlt, 0.55)
         : row.alpha(Colors.bgAlt, 0.20)
    Behavior on color { ColorAnimation { duration: 160 } }

    border.width: 1
    border.color: row.active ? row.alpha(row.tint, 0.38)
                             : row.alpha(Colors.outline, hover.hovered ? 0.20 : 0.08)
    Behavior on border.color { ColorAnimation { duration: 160 } }

    scale: press.pressed ? 0.985 : 1
    Behavior on scale { NumberAnimation { duration: 110 } }

    HoverHandler { id: hover }

    Rectangle {
        anchors.left: parent.left
        anchors.leftMargin: 1
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: row.active ? parent.height - 18 : 0
        radius: 2
        color: row.tint
        Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    Row {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 14
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Item {
            width: 22
            height: 22
            anchors.verticalCenter: parent.verticalCenter

            Row {
                visible: row.wifi
                anchors.centerIn: parent
                spacing: 2

                Repeater {
                    model: 4
                    Rectangle {
                        required property int index
                        readonly property bool lit: row.strength >= (index + 1) * 20
                        width: 3
                        height: 5 + index * 4
                        radius: 1.5
                        anchors.bottom: parent.bottom
                        color: lit ? (row.active ? row.tint : Colors.fg) : Colors.fgDim
                        opacity: lit ? (row.active ? 1 : 0.75) : 0.18
                        Behavior on opacity { NumberAnimation { duration: 200 } }
                    }
                }
            }

            Text {
                visible: !row.wifi
                anchors.centerIn: parent
                text: Bt.icon(row.entry)
                color: row.active ? row.tint : Colors.fgDim
                opacity: row.active ? 1 : 0.7
                font.family: row.mono
                font.pixelSize: 16
            }
        }

        Column {
            width: parent.width - 34 - 74
            anchors.verticalCenter: parent.verticalCenter
            spacing: 2

            Text {
                width: parent.width
                text: row.wifi ? row.entry.ssid : Bt.label(row.entry)
                color: row.active ? Colors.fg : Colors.fgDim
                opacity: row.active ? 1 : 0.9
                elide: Text.ElideRight
                font.family: row.mono
                font.pixelSize: 13
                font.weight: row.active ? Font.DemiBold : Font.Normal
            }

            Text {
                width: parent.width
                visible: text !== ""
                text: {
                    if (!row.entry) return "";
                    if (row.wifi) {
                        const bits = [row.strength + "%"];
                        if (row.entry.secured) bits.push(I18n.t("net.secured"));
                        if (row.entry.active) bits.push(I18n.t("net.connected"));
                        return bits.join("  ·  ");
                    }
                    if (row.working)
                        return row.entry.pairing ? I18n.t("net.pairing")
                             : row.entry.state === BluetoothDeviceState.Connecting
                                ? I18n.t("net.connecting") : I18n.t("net.disconnecting");
                    const bits = [];
                    if (row.entry.connected) bits.push(I18n.t("net.connected"));
                    else if (row.entry.paired || row.entry.bonded) bits.push(I18n.t("net.paired"));
                    else bits.push(I18n.t("net.new"));
                    if (row.entry.batteryAvailable)
                        bits.push(Math.round(row.entry.battery * 100) + "%");
                    return bits.join("  ·  ");
                }
                color: row.active ? row.tint : Colors.fgDim
                opacity: row.active ? 0.75 : 0.45
                elide: Text.ElideRight
                font.family: row.mono
                font.pixelSize: 10
            }
        }

        Item {
            width: 62
            height: 26
            anchors.verticalCenter: parent.verticalCenter

            Row {
                anchors.centerIn: parent
                visible: row.working
                spacing: 4

                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: 5; height: 5; radius: 2.5
                        color: row.tint
                        SequentialAnimation on opacity {
                            running: row.working
                            loops: Animation.Infinite
                            PauseAnimation { duration: index * 150 }
                            NumberAnimation { from: 0.25; to: 1.0; duration: 320 }
                            NumberAnimation { from: 1.0; to: 0.25; duration: 320 }
                            PauseAnimation { duration: 450 - index * 150 }
                        }
                    }
                }
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.working && row.wifi && row.entry && row.entry.secured && !row.active
                text: "󰌾"
                color: Colors.fgDim
                opacity: 0.4
                font.family: row.mono
                font.pixelSize: 12
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.working && row.active
                width: 26
                height: 24
                radius: 9
                color: disconnectHover.hovered ? row.alpha(Colors.bad, 0.22)
                                               : row.alpha(row.tint, 0.16)
                Behavior on color { ColorAnimation { duration: 150 } }

                HoverHandler { id: disconnectHover }

                Text {
                    anchors.centerIn: parent
                    text: "󰅖"
                    color: disconnectHover.hovered ? Colors.bad : row.tint
                    font.family: row.mono
                    font.pixelSize: 11
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Sfx.tap();
                        row.activated();
                    }
                }
            }

            Rectangle {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: !row.working && !row.wifi && !row.active
                         && row.entry && (row.entry.paired || row.entry.bonded)
                         && hover.hovered
                width: 26
                height: 24
                radius: 9
                color: forgetHover.hovered ? row.alpha(Colors.bad, 0.22) : "transparent"

                HoverHandler { id: forgetHover }

                Text {
                    anchors.centerIn: parent
                    text: "󰧧"
                    color: forgetHover.hovered ? Colors.bad : Colors.fgDim
                    opacity: forgetHover.hovered ? 1 : 0.45
                    font.family: row.mono
                    font.pixelSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        Sfx.toggleOff();
                        row.forgetRequested();
                    }
                }
            }
        }
    }

    Rectangle {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: row.expanded ? parent.width - 28 : 0
        height: 1.5
        radius: 1
        color: row.tint
        opacity: 0.6
        Behavior on width { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
    }

    TapHandler {
        id: press
        onTapped: row.activated()
    }
}
