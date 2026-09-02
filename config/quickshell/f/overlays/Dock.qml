import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import "root:/design"
import "root:/services"

Scope {
    id: root

    property bool pinned: false

    function toggle() {
        root.pinned = !root.pinned;
        Sfx.flip(root.pinned);
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "qs-dock"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                bottom: true
                left: true
                right: true
            }

            implicitHeight: win.open ? 128 : 4
            exclusiveZone: 0
            color: "transparent"

            readonly property bool open: hover.hovered || root.pinned
            readonly property int strip: 3

            mask: Region {
                x: 0
                y: win.open ? win.height - 112 : win.height - win.strip
                width: win.width
                height: win.open ? 112 : win.strip
            }

            HoverHandler { id: hover }

            readonly property var apps: {
                const list = ToplevelManager.toplevels
                    ? ToplevelManager.toplevels.values : [];
                const seen = ({});
                const out = [];
                for (const t of list) {
                    if (!t || !t.appId || t.appId === "")
                        continue;
                    if (seen[t.appId] !== undefined) {
                        out[seen[t.appId]].count++;
                        continue;
                    }
                    seen[t.appId] = out.length;
                    out.push({ appId: t.appId, toplevel: t, count: 1 });
                }
                return out;
            }

            Rectangle {
                id: shelf

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: win.open ? (Prefs.barAtTop ? 12 : 46) : -96
                width: Math.max(84, icons.implicitWidth + 28)
                height: 78
                radius: Shape.card
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.88)
                antialiasing: true
                visible: win.apps.length > 0

                opacity: win.open ? 1 : 0

                Behavior on anchors.bottomMargin {
                    NumberAnimation {
                        duration: Motion.slow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.expo
                    }
                }
                Behavior on opacity { NumberAnimation { duration: Motion.base } }

                Sheen {
                    anchors.fill: parent
                    radius: parent.radius
                    edgeOpacity: 0.18
                }

                Row {
                    id: icons
                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: win.apps

                        Item {
                            id: slot

                            required property var modelData

                            readonly property real dist: {
                                if (!hover.hovered)
                                    return 99;
                                const centre = slot.x + slot.width / 2;
                                return Math.abs(pointer.x - centre) / 58;
                            }
                            readonly property real lift:
                                Math.max(0, 1 - slot.dist * slot.dist * 0.35)

                            width: 52
                            height: 58

                            IconImage {
                                id: art

                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 10 + slot.lift * 10

                                implicitSize: 38
                                source: Quickshell.iconPath(slot.modelData.appId,
                                                            "application-x-executable")

                                scale: 1 + slot.lift * 0.55
                                Behavior on scale { Spring {} }
                                Behavior on anchors.bottomMargin {
                                    NumberAnimation { duration: Motion.fast }
                                }
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 2
                                spacing: 3

                                Repeater {
                                    model: Math.min(3, slot.modelData.count)

                                    Rectangle {
                                        width: 3
                                        height: 3
                                        radius: 1.5
                                        color: Colors.accent
                                        opacity: 0.7
                                    }
                                }
                            }

                            Rectangle {
                                id: tip

                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.top
                                anchors.bottomMargin: 4
                                width: tipText.implicitWidth + 16
                                height: 22
                                radius: 8
                                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96)
                                border.width: 1
                                border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                      Colors.outline.b, 0.2)

                                opacity: slot.lift > 0.75 ? 1 : 0
                                visible: opacity > 0.01
                                Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                                Text {
                                    id: tipText
                                    anchors.centerIn: parent
                                    text: slot.modelData.appId
                                    color: Colors.fgDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                }
                            }

                            TapHandler {
                                onTapped: {
                                    Sfx.tap();
                                    slot.modelData.toplevel.activate();
                                }
                            }
                        }
                    }
                }

                QtObject {
                    id: pointer
                    property real x: 0
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.NoButton
                    hoverEnabled: true
                    onPositionChanged: (mouse) => {
                        pointer.x = mouse.x - icons.x;
                    }
                }
            }
        }
    }
}
