import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    function edit() {
        DeskLayout.editing = true;
        DeskLayout.selected = -1;
        Sfx.panelIn();
    }

    function done() {
        if (!DeskLayout.editing)
            return;
        DeskLayout.editing = false;
        DeskLayout.selected = -1;
        DeskLayout.save();
        Sfx.panelOut();
    }

    function toggle() {
        if (DeskLayout.editing) root.done();
        else root.edit();
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            screen: modelData

            WlrLayershell.namespace: "qs-desk"
            WlrLayershell.layer: DeskLayout.editing
                ? WlrLayer.Overlay
                : WlrLayer.Background
            WlrLayershell.keyboardFocus: DeskLayout.editing
                ? WlrKeyboardFocus.Exclusive
                : WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            color: "transparent"

            mask: DeskLayout.editing ? full : nothing

            Region { id: nothing }
            Region {
                id: full
                x: 0
                y: 0
                width: win.width
                height: win.height
            }

            Rectangle {
                anchors.fill: parent
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
                opacity: DeskLayout.editing ? 1 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Motion.slow } }
            }

            Canvas {
                anchors.fill: parent
                opacity: DeskLayout.editing ? 0.16 : 0
                visible: opacity > 0.01
                Behavior on opacity { NumberAnimation { duration: Motion.slow } }

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();
                    ctx.strokeStyle = Colors.fgDim;
                    ctx.lineWidth = 1;
                    const step = 64;
                    for (let x = step; x < width; x += step) {
                        ctx.beginPath();
                        ctx.moveTo(x + 0.5, 0);
                        ctx.lineTo(x + 0.5, height);
                        ctx.stroke();
                    }
                    for (let y = step; y < height; y += step) {
                        ctx.beginPath();
                        ctx.moveTo(0, y + 0.5);
                        ctx.lineTo(width, y + 0.5);
                        ctx.stroke();
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                enabled: DeskLayout.editing
                onClicked: DeskLayout.selected = -1
            }

            Repeater {
                model: DeskLayout.forScreen(win.modelData.name)

                DeskFrame {
                    required property var modelData
                    entry: modelData
                    fieldWidth: win.width
                    fieldHeight: win.height
                }
            }

            Rectangle {
                id: palette

                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: DeskLayout.editing ? 48 : -120
                width: paletteRow.implicitWidth + 36
                height: 74
                radius: 26
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.92)
                antialiasing: true

                opacity: DeskLayout.editing ? 1 : 0
                visible: opacity > 0.01

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
                    edgeOpacity: 0.2
                }

                Row {
                    id: paletteRow
                    anchors.centerIn: parent
                    spacing: 10

                    Repeater {
                        model: DeskLayout.types

                        IconButton {
                            required property var modelData

                            glyph: DeskLayout.registry[modelData].glyph
                            tip: DeskLayout.registry[modelData].title
                            tint: Colors.accent
                            onActivated: DeskLayout.add(modelData, win.modelData.name)
                        }
                    }

                    Rectangle {
                        width: 1
                        height: 26
                        anchors.verticalCenter: parent.verticalCenter
                        color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                       Colors.outline.b, 0.25)
                    }

                    IconButton {
                        glyph: "󰄬"
                        tip: I18n.t("act.done")
                        tint: Colors.good
                        onActivated: root.done()
                    }
                }
            }

            FocusScope {
                anchors.fill: parent
                focus: DeskLayout.editing
                Keys.onEscapePressed: root.done()
            }
        }
    }
}
