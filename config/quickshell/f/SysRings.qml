import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// System monitor panel: six load gauges, opened on a keybind.
//
// Everything lives inside a Loader that is inactive by default. While the panel
// is closed there is no window, no Canvas, no timer and no sysmon.py process;
// toggling it on creates them, toggling it off destroys them. That keeps a
// widget that is only glanced at a few times a day from polling nvidia-smi
// around the clock.
Scope {
    id: root

    property bool shown: false

    function toggle() {
        root.shown = !root.shown;
    }

    function close() {
        root.shown = false;
    }

    Loader {
        // Kept alive briefly past `shown` so the close animation can play.
        active: root.shown || closeDelay.running

        sourceComponent: Component {
            PanelWindow {
                WlrLayershell.namespace: "qs-sysrings"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                screen: Focus.screen

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                exclusiveZone: 0
                color: "transparent"

                // Click anywhere outside the card to dismiss.
                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                Keys.onEscapePressed: root.close()
                Component.onCompleted: forceActiveFocus()

                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    width: grid.width + 56
                    height: grid.height + 76
                    radius: 26

                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.93)
                    border.width: 1
                    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.28)

                    // Swallow clicks so they do not reach the dismiss handler.
                    MouseArea { anchors.fill: parent }

                    opacity: root.shown ? 1 : 0
                    scale: root.shown ? 1 : 0.9

                    Behavior on opacity { NumberAnimation { duration: 200 } }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 340
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.1
                        }
                    }

                    Text {
                        id: heading
                        anchors.top: parent.top
                        anchors.topMargin: 20
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "system"
                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                       Colors.fgDim.b, 0.55)
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                        font.letterSpacing: 3
                    }

                    Grid {
                        id: grid
                        anchors.top: heading.bottom
                        anchors.topMargin: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        columns: 3
                        spacing: 14

                        Ring {
                            id: cpuRing
                            caption: "CPU"
                            value: -1
                        }
                        Ring {
                            id: memRing
                            caption: "RAM"
                            value: -1
                        }
                        Ring {
                            id: tempRing
                            caption: "CPU TEMP"
                            value: -1
                        }
                        Ring {
                            id: gpuRing
                            caption: "GPU"
                            value: -1
                        }
                        Ring {
                            id: vramRing
                            caption: "VRAM"
                            value: -1
                        }
                        Ring {
                            id: gputempRing
                            caption: "GPU TEMP"
                            value: -1
                        }
                    }

                    // Rings appear one after another rather than all at once.
                    SequentialAnimation {
                        running: root.shown
                        PauseAnimation { duration: 60 }
                        ScriptAction {
                            script: {
                                const rings = [cpuRing, memRing, tempRing,
                                               gpuRing, vramRing, gputempRing];
                                for (let i = 0; i < rings.length; i++)
                                    rings[i].animationDuration = 700 + i * 90;
                            }
                        }
                    }
                }

                // The data source. Dies with the Loader.
                Process {
                    id: monitor
                    running: true
                    command: [Quickshell.env("HOME")
                              + "/.config/hypr/scripts/sysmon.py"]

                    stdout: SplitParser {
                        onRead: function (line) {
                            let s;
                            try {
                                s = JSON.parse(line);
                            } catch (e) {
                                return;
                            }

                            function apply(ring, value, label) {
                                ring.value = value === null ? -1 : value;
                                ring.label = label || "";
                            }

                            apply(cpuRing, s.cpu, s.cpu_label);
                            apply(memRing, s.mem, s.mem_label);
                            apply(tempRing, s.temp, s.temp_label);
                            apply(gpuRing, s.gpu, s.gpu_label);
                            apply(vramRing, s.vram, s.vram_label);
                            apply(gputempRing, s.gputemp, s.gputemp_label);
                        }
                    }
                }
            }
        }
    }

    // Holds the Loader open just long enough for the fade-out.
    Timer {
        id: closeDelay
        interval: 360
    }

    onShownChanged: {
        if (!root.shown)
            closeDelay.restart();
        else
            closeDelay.stop();
    }
}
