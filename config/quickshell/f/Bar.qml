import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

Scope {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 34
            exclusiveZone: 34
            color: "transparent"

            component Island: Rectangle {
                id: island
                property bool hovered: false

                radius: 12
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b,
                               hovered ? 0.92 : 0.80)
                border.width: 1
                border.color: hovered
                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.55)
                    : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.32)

                scale: hovered ? 1.04 : 1.0

                Behavior on color { ColorAnimation { duration: 220 } }
                Behavior on border.color { ColorAnimation { duration: 220 } }
                Behavior on scale {
                    NumberAnimation { duration: 240; easing.type: Easing.OutBack }
                }

                HoverHandler {
                    onHoveredChanged: island.hovered = hovered
                }
            }

            Island {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                height: 26
                width: wsRow.implicitWidth + 16

                Row {
                    id: wsRow
                    anchors.centerIn: parent
                    spacing: 7

                    Repeater {
                        model: Hyprland.workspaces

                        Rectangle {
                            required property var modelData
                            readonly property bool isActive:
                                Hyprland.focusedWorkspace
                                && Hyprland.focusedWorkspace.id === modelData.id

                            width: isActive ? 20 : 7
                            height: 7
                            radius: 4
                            color: isActive ? Colors.accent
                                            : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                      Colors.fgDim.b, 0.30)
                            anchors.verticalCenter: parent.verticalCenter

                            Behavior on width {
                                NumberAnimation { duration: 280; easing.type: Easing.OutBack }
                            }
                            Behavior on color { ColorAnimation { duration: 200 } }

                            Rectangle {
                                id: pulse
                                anchors.centerIn: parent
                                width: parent.width
                                height: parent.height
                                radius: height / 2
                                color: "transparent"
                                border.width: 2
                                border.color: Colors.accent
                                opacity: 0
                                z: -1
                            }

                            ParallelAnimation {
                                id: pulseAnim
                                NumberAnimation {
                                    target: pulse; property: "scale"
                                    from: 1; to: 3.4
                                    duration: 520; easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: pulse; property: "opacity"
                                    from: 0.85; to: 0
                                    duration: 520; easing.type: Easing.OutCubic
                                }
                            }

                            onIsActiveChanged: if (isActive) pulseAnim.restart()

                            MouseArea {
                                anchors.fill: parent
                                anchors.margins: -5
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Hyprland.dispatch("workspace " + modelData.id)
                            }
                        }
                    }
                }
            }

            Island {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                height: 26
                width: clockText.implicitWidth + 24

                RollText {
                    id: clockText
                    anchors.centerIn: parent
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    color: Colors.fg
                    pixelSize: 12
                }
            }

            Island {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 8
                height: 26
                width: rightRow.implicitWidth + 20

                RowLayout {
                    id: rightRow
                    anchors.centerIn: parent
                    spacing: 11

                    Repeater {
                        model: SystemTray.items

                        IconImage {
                            required property var modelData
                            source: {
                                const i = modelData.icon;
                                if (!i) return "";
                                if (i.startsWith("/") || i.includes("://")
                                    || i.includes("?")) return i;
                                return Quickshell.iconPath(i, "application-x-executable");
                            }
                            implicitSize: 15

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                cursorShape: Qt.PointingHandCursor
                                onClicked: function (mouse) {
                                    if (mouse.button === Qt.LeftButton)
                                        modelData.activate();
                                    else
                                        modelData.secondaryActivate();
                                }
                            }
                        }
                    }

                    Text {
                        text: Keyboard.code
                        color: Colors.accentAlt
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11
                        font.weight: Font.DemiBold

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -3
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Keyboard.next()
                        }

                        Behavior on color { ColorAnimation { duration: 200 } }
                    }

                    Text {
                        readonly property var src: Pipewire.defaultAudioSource
                        visible: src && src.audio && src.audio.muted
                        text: "󰍭"
                        color: Colors.bad
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 12
                    }

                    Text {
                        readonly property var sink: Pipewire.defaultAudioSink
                        readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
                        readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

                        text: muted ? "󰝟" : "󰕾  " + Math.round(vol * 100) + "%"
                        color: muted ? Colors.fgDim : Colors.fg
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (parent.sink && parent.sink.audio)
                                    parent.sink.audio.muted = !parent.sink.audio.muted;
                            }
                            onWheel: function (wheel) {
                                if (!parent.sink || !parent.sink.audio) return;
                                const step = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
                                parent.sink.audio.volume =
                                    Math.max(0, Math.min(1, parent.sink.audio.volume + step));
                            }
                        }
                    }

                    Text {
                        readonly property var dev: UPower.displayDevice
                        readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
                        readonly property bool charging:
                            dev && dev.state === UPowerDeviceState.Charging

                        visible: dev && dev.isLaptopBattery
                        text: (charging ? "󰂄 " : "") + pct + "%"
                        color: charging ? Colors.good
                             : pct <= 12 ? Colors.bad
                             : pct <= 25 ? Colors.warn
                             : Colors.fgDim
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 11

                        Behavior on color { ColorAnimation { duration: 300 } }
                    }
                }
            }
        }
    }
}
