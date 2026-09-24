import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    function toggle() { root.shown = !root.shown; }
    function close() {
        root.shown = false;
        IslandConfig.writeNow();
    }

    onShownChanged: Sfx.panel(root.shown)

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-islandsettings"
        id: win
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.55 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Emerge {
            id: emerge
            card: card
            win: win
            open: root.shown
        }

        FocusScope {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 880)
            height: Math.min(parent.height - 90, 700)
            focus: true

            Keys.onEscapePressed: root.close()

            Glass {
                anchors.fill: parent
                radius: Shape.modal
                elevation: 3
                tintOpacity: 0.96
            }

            opacity: emerge.on ? emerge.cardOpacity : (root.shown ? 1 : 0)
            scale: emerge.on ? 1 : (root.shown ? 1 : 0.96)
            transform: Translate { x: emerge.dx; y: emerge.dy }
            Behavior on opacity { enabled: !emerge.on; NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                enabled: !emerge.on
                SpringAnimation {
                    spring: Motion.panelSpring
                    damping: Motion.panelDamping
                    mass: Motion.panelMass
                    epsilon: 0.001
                }
            }

            Item {
                id: head
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Shape.padLoose
                height: 40

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.t("isle.title")
                    color: Colors.fg
                    font.family: Fonts.display
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    anchors.centerIn: parent
                    width: onText.implicitWidth + 52
                    height: 28
                    radius: Shape.chip
                    antialiasing: true
                    color: IslandConfig.s("enabled")
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                  Colors.accent.b, 0.22)
                        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                  Colors.fgDim.b, 0.08)
                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                    Row {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: IslandConfig.s("enabled") ? "󰔡" : "󰔢"
                            color: IslandConfig.s("enabled") ? Colors.accent : Colors.fgDim
                            font.family: Fonts.glyph
                            font.pixelSize: 13
                        }

                        Text {
                            id: onText
                            anchors.verticalCenter: parent.verticalCenter
                            text: IslandConfig.s("enabled") ? I18n.t("state.on")
                                                            : I18n.t("state.off")
                            color: IslandConfig.s("enabled") ? Colors.accent : Colors.fgDim
                            font.family: Fonts.display
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            IslandConfig.setStyle("enabled",
                                                  !IslandConfig.s("enabled"));
                            Sfx.tick();
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    IconButton {
                        width: 30; height: 30
                        glyph: "󰑐"
                        tip: I18n.t("barc.reset")
                        tint: Colors.bad
                        onActivated: IslandConfig.reset()
                    }

                    IconButton {
                        width: 30; height: 30
                        glyph: "󰅖"
                        tip: I18n.t("act.done")
                        tint: Colors.good
                        onActivated: root.close()
                    }
                }
            }

            Rectangle {
                id: headLine
                anchors.top: head.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Shape.padLoose
                anchors.topMargin: 6
                height: 1
                color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                               Colors.outline.b, 0.18)
            }

            ScrollView {
                anchors.top: headLine.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Shape.padLoose
                anchors.topMargin: 14
                clip: true

                opacity: IslandConfig.s("enabled") ? 1 : 0.42
                Behavior on opacity { NumberAnimation { duration: Motion.base } }

                Column {
                    id: col
                    width: card.width - Shape.padLoose * 2
                    spacing: 18

                    readonly property real colWidth: (col.width - 26) / 2

                    Repeater {
                        model: IslandConfig.groups

                        Column {
                            required property var modelData
                            width: col.width
                            spacing: 8

                            Text {
                                text: IslandConfig.groupTitle(parent.modelData.key)
                                color: Colors.fgDim
                                opacity: 0.5
                                font.family: Fonts.mono
                                font.pixelSize: 9
                                font.letterSpacing: 2
                            }

                            Grid {
                                columns: 2
                                columnSpacing: 26
                                rowSpacing: 10
                                width: col.width

                                Repeater {
                                    model: parent.parent.modelData.names

                                    OptionRow {
                                        required property string modelData
                                        width: col.colWidth
                                        name: modelData
                                        label: IslandConfig.optTitle(modelData)
                                        valueLabel: v => IslandConfig.valueTitle(v)
                                        spec: IslandConfig.spec[modelData]
                                        value: IslandConfig.s(modelData)
                                        onCommit: v => IslandConfig.setStyle(modelData, v)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
