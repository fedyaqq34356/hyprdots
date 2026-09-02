import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/services"

Scope {
    id: root

    property bool showing: false
    readonly property int hold: 3400

    readonly property string name: Quickshell.env("USER")

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    readonly property string part: {
        const h = clock.date.getHours();
        if (h < 5)  return "night";
        if (h < 12) return "morning";
        if (h < 18) return "day";
        if (h < 23) return "evening";
        return "night";
    }

    readonly property string date:
        Qt.formatDateTime(clock.date, "dddd, d MMMM")

    readonly property var facts: {
        const out = [];

        if (Weather.ready)
            out.push({ glyph: Weather.glyph,
                       text: Math.round(Weather.temp) + "°" });

        const battery = UPower.displayDevice;
        if (battery && battery.isLaptopBattery)
            out.push({ glyph: battery.state === UPowerDeviceState.Charging ? "󰂄" : "󰁹",
                       text: Math.round(battery.percentage * 100) + "%" });

        if (NotifHistory.unseen > 0)
            out.push({ glyph: "󰂚",
                       text: I18n.count("plural.notification", NotifHistory.unseen) });

        if (Updates.count > 0)
            out.push({ glyph: "󰏗",
                       text: Updates.count + I18n.t("notif.packages") });

        return out;
    }

    function show() {
        if (root.showing)
            return;
        root.showing = true;
        Sfx.sessionStart();
        life.restart();
    }

    Timer {
        id: life
        interval: root.hold
        onTriggered: root.showing = false
    }

    FileView {
        id: marker
        path: (Quickshell.env("XDG_RUNTIME_DIR") || "/tmp") + "/quickshell-greeted"
        blockLoading: true

        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                return;
            marker.setText(String(Date.now()));
            if (Prefs.greetingEnabled)
                start.start();
        }
    }

    Timer {
        id: start
        interval: 900
        onTriggered: root.show()
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-greeting"
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        screen: Focus.screen
        visible: root.showing || fade.running

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"
        mask: Region {}

        Rectangle {
            id: scrim

            anchors.fill: parent
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.72)
            opacity: root.showing ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    id: fade
                    duration: Motion.lazy
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
                text: I18n.t("hello." + root.part)
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
                    GradientStop { position: 0.5; color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.7) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.date.toLowerCase()
                color: Colors.fgDim
                font.family: Fonts.mono
                font.pixelSize: 12
                font.letterSpacing: 2
                opacity: 0.75
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 22
                visible: root.facts.length > 0

                Repeater {
                    model: root.facts

                    Row {
                        required property var modelData
                        required property int index

                        spacing: 7
                        opacity: 0

                        SequentialAnimation on opacity {
                            running: root.showing
                            PauseAnimation { duration: 420 + index * 110 }
                            NumberAnimation { to: 1; duration: Motion.slow }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.glyph
                            color: Colors.accentAlt
                            font.family: Fonts.glyph
                            font.pixelSize: 14
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: modelData.text
                            color: Colors.fgDim
                            font.family: Fonts.mono
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
