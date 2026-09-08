import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/services"

Scope {
    id: root

    property bool showing: false

    readonly property int hold: 1150

    readonly property string name: Quickshell.env("USER")

    function up() {
        if (root.showing)
            return;
        root.showing = true;
        life.restart();
    }

    Timer {
        id: life
        interval: root.hold
        onTriggered: root.showing = false
    }

    IpcHandler {
        target: "curtain"

        function up(): string {
            root.up();
            return "ok";
        }
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-curtain"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        screen: Focus.screen
        visible: root.showing || veilFade.running

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"
        mask: Region {}

        Rectangle {
            id: veil

            anchors.fill: parent
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.82)
            opacity: root.showing ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    id: veilFade
                    duration: root.showing ? Motion.instant : Motion.lazy
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.expo
                }
            }

            Grain {
                anchors.fill: parent
                amount: 0.02
            }
        }

        Column {
            id: body

            anchors.centerIn: parent
            spacing: 18
            opacity: root.showing ? 1 : 0

            transform: Translate {
                y: root.showing ? 0 : -26
                Behavior on y {
                    NumberAnimation {
                        duration: Motion.lazy
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.expo
                    }
                }
            }

            Behavior on opacity {
                NumberAnimation { duration: Motion.slow }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: I18n.t("hello.back")
                color: Colors.fg
                font.family: Fonts.display
                font.pixelSize: 52
                font.weight: Font.Light
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.name
                color: Colors.accent
                font.family: Fonts.mono
                font.pixelSize: 15
                font.letterSpacing: 6
                opacity: 0.9
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 220
                height: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop {
                        position: 0.5
                        color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                       Colors.outline.b, 0.7)
                    }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }
    }
}
