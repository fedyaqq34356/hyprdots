import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    WeatherHold { active: root.shown }

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: Sfx.panel(root.shown)

    readonly property string mono: Fonts.mono

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-settings"
        WlrLayershell.layer: WlrLayer.Overlay

        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Bloom {
            target: card
            amount: root.shown ? 0.20 : 0
        }

        Glass {
            id: card

            anchors.centerIn: parent
            width: 520
            height: Math.min(parent.height - 80, body.implicitHeight + head.height + 76)
            radius: Shape.modal
            elevation: 3
            edge: Colors.accent

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.95
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

            Item {
                id: head

                anchors { top: parent.top; left: parent.left; right: parent.right }
                anchors.margins: 26
                height: 44

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: 40
                        radius: Shape.chip
                        antialiasing: true
                        color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                       Colors.accent.b, 0.16)
                        border.width: 1
                        border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                              Colors.accent.b, 0.30)

                        Text {
                            anchors.centerIn: parent
                            text: "󰒓"
                            color: Colors.accent
                            font.family: root.mono
                            font.pixelSize: 18
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2

                        Text {
                            text: I18n.t("set.title")
                            color: Colors.fg
                            font.family: Fonts.display
                            font.pixelSize: Fonts.titleSize
                        }

                        Text {
                            text: Wellbeing.human(Wellbeing.total)
                            color: Colors.accent
                            opacity: Prefs.wellbeingEnabled ? 0.85 : 0.25
                            font.family: root.mono
                            font.pixelSize: 10
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    HoldButton {
                        glyph: "󰩹"
                        tip: I18n.t("set.clearStats")
                        onConfirmed: Wellbeing.clear()
                    }

                    IconButton {
                        glyph: "󰋖"
                        tip: I18n.t("set.guide")
                        tint: Colors.accentAlt
                        onActivated: {
                            root.close();
                            Hyprland.dispatch("global quickshell:guide");
                        }
                    }

                    IconButton {
                        glyph: "󰄬"
                        tip: I18n.t("act.close")
                        tint: Colors.good
                        onActivated: root.close()
                    }
                }
            }

            Flickable {
                id: scroll

                anchors { top: head.bottom; left: parent.left; right: parent.right;
                          bottom: parent.bottom }
                anchors.topMargin: 8
                anchors.leftMargin: 26
                anchors.rightMargin: 26
                anchors.bottomMargin: 26

                clip: true
                contentHeight: body.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: body

                    width: scroll.width
                    spacing: 22

                    SettingsSection {
                        width: parent.width
                        glyph: "󰸌"
                        title: I18n.t("set.secLook")

                        SettingsChoice {
                            width: parent.width
                            label: I18n.t("set.font")
                            current: Prefs.fontDisplay
                            options: Fonts.displayChoices
                            onPicked: (value) => Prefs.set("fontDisplay", value)
                        }

                        SettingsChoice {
                            width: parent.width
                            label: I18n.t("set.barPosition")
                            current: Prefs.barPosition
                            options: [
                                { value: "top", label: I18n.t("set.barTop") },
                                { value: "bottom", label: I18n.t("set.barBottom") }
                            ]
                            onPicked: (value) => Prefs.set("barPosition", value)
                        }

                        SettingsChoice {
                            width: parent.width
                            label: I18n.t("set.osd")
                            current: Prefs.osdStyle
                            options: [
                                { value: "island", label: I18n.t("set.osdIsland") },
                                { value: "panel", label: I18n.t("set.osdPanel") }
                            ]
                            onPicked: (value) => Prefs.set("osdStyle", value)
                        }

                        SettingsChoice {
                            width: parent.width
                            label: I18n.t("set.language")
                            current: Prefs.language
                            options: [
                                { value: "en", label: "english" },
                                { value: "ru", label: "русский" }
                            ]
                            onPicked: (value) => Prefs.set("language", value)
                        }
                    }

                    SettingsSection {
                        width: parent.width
                        glyph: "󰇄"
                        title: I18n.t("set.secDesk")

                        Repeater {
                            model: [
                                { key: "widgetsEnabled",      title: I18n.t("set.widgets"),  hint: I18n.t("set.widgetsHint") },
                                { key: "dockEnabled",         title: I18n.t("set.dock"),     hint: I18n.t("set.dockHint") },
                                { key: "quickActionsEnabled", title: I18n.t("set.quick"),    hint: I18n.t("set.quickHint") },
                                { key: "drawEnabled",         title: I18n.t("set.draw"),     hint: I18n.t("set.drawHint") },
                                { key: "greetingEnabled",     title: I18n.t("set.greeting"), hint: I18n.t("set.greetingHint") }
                            ]

                            SettingsToggle {
                                required property var modelData
                                width: parent.width
                                title: modelData.title
                                hint: modelData.hint
                                checked: Prefs[modelData.key]
                                onToggled: (value) => Prefs.set(modelData.key, value)
                            }
                        }
                    }

                    SettingsSection {
                        width: parent.width
                        glyph: "󰕾"
                        title: I18n.t("set.secSound")

                        SettingsToggle {
                            width: parent.width
                            title: I18n.t("set.sfx")
                            hint: I18n.t("set.sfxHint")
                            checked: Prefs.sfxEnabled
                            onToggled: (value) => Prefs.set("sfxEnabled", value)
                        }

                        Column {
                            width: parent.width
                            spacing: 10

                            Row {
                                width: parent.width

                                Text {
                                    text: I18n.t("set.volume")
                                    color: Colors.fgDim
                                    opacity: 0.7
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }

                                Item { width: parent.width - 190; height: 1 }

                                Text {
                                    text: Math.round(Prefs.sfxVolume * 100) + "%"
                                    color: Colors.fg
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }
                            }

                            Slider {
                                width: parent.width
                                value: Prefs.sfxVolume
                                onMoved: (value) => Prefs.set("sfxVolume", value)
                            }
                        }

                        SettingsChoice {
                            width: parent.width
                            label: I18n.t("set.tone")
                            current: Prefs.notifySound
                            options: [
                                { value: "Sine", label: "sine" },
                                { value: "Botanica", label: "botanica" },
                                { value: "Progress", label: "progress" }
                            ]
                            onPicked: (value) => {
                                Prefs.set("notifySound", value);
                                Sfx.notify();
                            }
                        }
                    }

                    SettingsSection {
                        width: parent.width
                        glyph: "󰍛"
                        title: I18n.t("set.secSystem")

                        Repeater {
                            model: [
                                { key: "wellbeingEnabled", title: I18n.t("set.screentime"), hint: I18n.t("set.screentimeHint") },
                                { key: "polkitEnabled",    title: I18n.t("set.polkit"),     hint: I18n.t("set.polkitHint") },
                                { key: "idleEnabled",      title: I18n.t("set.idle"),       hint: I18n.t("set.idleHint") }
                            ]

                            SettingsToggle {
                                required property var modelData
                                width: parent.width
                                title: modelData.title
                                hint: modelData.hint
                                checked: Prefs[modelData.key]
                                onToggled: (value) => Prefs.set(modelData.key, value)
                            }
                        }

                        SettingsToggle {
                            width: parent.width
                            mono: root.mono
                            title: I18n.t("set.weather")
                            hint: I18n.t("set.weatherHint")
                            checked: Prefs.weatherEnabled
                            onToggled: (value) => Prefs.set("weatherEnabled", value)
                        }

                        Column {
                            width: parent.width
                            spacing: 6
                            opacity: Prefs.weatherEnabled ? 1 : 0.35

                            Row {
                                width: parent.width

                                Text {
                                    text: I18n.t("set.weatherEvery")
                                    color: Colors.fgDim
                                    opacity: 0.7
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }

                                Item { width: parent.width - 190; height: 1 }

                                Text {
                                    text: Prefs.weatherEveryMin + I18n.t("set.minShort")
                                    color: Colors.fg
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }
                            }

                            Slider {
                                width: parent.width
                                enabled: Prefs.weatherEnabled
                                value: (Prefs.weatherEveryMin - 15) / 165
                                onMoved: (value) => Prefs.set(
                                    "weatherEveryMin",
                                    Math.round(15 + value * 165))
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Row {
                                width: parent.width

                                Text {
                                    text: I18n.t("set.place")
                                    color: Colors.fgDim
                                    opacity: 0.7
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }

                                Item { width: parent.width - 230; height: 1 }

                                Text {
                                    text: Weather.ready && Weather.city !== ""
                                        ? Weather.city.toLowerCase() + "  "
                                          + Math.round(Weather.temp) + "°"
                                        : I18n.t("set.placeHint")
                                    color: Weather.ready ? Colors.accent : Colors.fgDim
                                    opacity: Weather.ready ? 0.9 : 0.45
                                    elide: Text.ElideRight
                                    font.family: root.mono
                                    font.pixelSize: 10
                                }
                            }

                            Field {
                                width: parent.width
                                height: 40
                                placeholder: I18n.t("set.placeInput")
                                mono: root.mono
                                text: Prefs.weatherPlace

                                onAccepted: (value) => {
                                    Prefs.set("weatherPlace", value.trim());
                                    Sfx.tapAlt();
                                }
                            }
                        }
                    }

                    SettingsSection {
                        width: parent.width
                        glyph: "󰍹"
                        title: I18n.t("set.secMode")

                        Item {
                            width: parent.width
                            implicitHeight: Math.max(44, info.implicitHeight)
                            height: implicitHeight

                            Column {
                                id: info

                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 60
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: I18n.t("set.serezha")
                                    color: Colors.fg
                                    elide: Text.ElideRight
                                    font.family: Fonts.display
                                    font.pixelSize: Fonts.headingSize
                                }

                                Text {
                                    width: parent.width
                                    text: I18n.t("set.serezhaHint")
                                    color: Colors.bad
                                    opacity: 0.8
                                    wrapMode: Text.WordWrap
                                    font.family: root.mono
                                    font.pixelSize: 10
                                }
                            }

                            HoldButton {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                glyph: "󰐥"
                                tip: I18n.t("set.serezhaGo")
                                holdTime: 1400
                                onConfirmed: {
                                    Prefs.set("serezhaMode", true);
                                    root.close();
                                    Quickshell.execDetached(["sh", "-c",
                                        "sleep 0.3; exec \"$HOME/.local/bin/serezha-mode\" on"]);
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
