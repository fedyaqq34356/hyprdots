import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: Sfx.panel(root.shown)

    readonly property string mono: "JetBrainsMono Nerd Font"

    readonly property var rows: [
        { key: "sfxEnabled",          title: I18n.t("set.sfx"),        hint: I18n.t("set.sfxHint") },
        { key: "widgetsEnabled",      title: I18n.t("set.widgets"),    hint: I18n.t("set.widgetsHint") },
        { key: "dockEnabled",         title: I18n.t("set.dock"),       hint: I18n.t("set.dockHint") },
        { key: "quickActionsEnabled", title: I18n.t("set.quick"),      hint: I18n.t("set.quickHint") },
        { key: "drawEnabled",         title: I18n.t("set.draw"),       hint: I18n.t("set.drawHint") },
        { key: "wellbeingEnabled",    title: I18n.t("set.screentime"), hint: I18n.t("set.screentimeHint") },
        { key: "polkitEnabled",       title: I18n.t("set.polkit"),     hint: I18n.t("set.polkitHint") },
        { key: "idleEnabled",         title: I18n.t("set.idle"),       hint: I18n.t("set.idleHint") }
    ]

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
            color: Qt.rgba(0, 0, 0, 0.4)
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Glass {
            id: card

            anchors.centerIn: parent
            width: 460
            height: body.implicitHeight + 52
            radius: 32
            elevation: 3

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                NumberAnimation {
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.snap
                }
            }

            Column {
                id: body

                anchors.centerIn: parent
                width: parent.width - 52
                spacing: 16

                Row {
                    width: parent.width

                    Text {
                        text: I18n.t("set.title")
                        color: Colors.fg
                        font.family: Fonts.display
                        font.pixelSize: Fonts.titleSize
                    }

                    Item { width: parent.width - 120; height: 1 }

                    Text {
                        text: Wellbeing.human(Wellbeing.total)
                        color: Colors.accent
                        opacity: Prefs.wellbeingEnabled ? 0.9 : 0.25
                        font.family: root.mono
                        font.pixelSize: 11
                    }
                }

                Repeater {
                    model: root.rows

                    Item {
                        id: row

                        required property var modelData

                        readonly property bool on: Prefs[modelData.key]

                        width: body.width
                        height: 44

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -8
                            radius: 14
                            color: rowHover.hovered
                                ? Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.06)
                                : "transparent"
                            Behavior on color { ColorAnimation { duration: Motion.fast } }
                        }

                        HoverHandler { id: rowHover }

                        Column {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: row.modelData.title
                                color: Colors.fg
                                opacity: row.on ? 1 : 0.55
                                font.family: Fonts.display
                                font.pixelSize: Fonts.headingSize
                                Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                            }

                            Text {
                                text: row.modelData.hint
                                color: Colors.fgDim
                                opacity: 0.45
                                font.family: root.mono
                                font.pixelSize: 10
                            }
                        }

                        Switch {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            checked: row.on
                            onToggled: (value) => Prefs.set(row.modelData.key, value)
                        }
                    }
                }

                Rectangle {
                    width: parent.width
                    height: 1
                    color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                   Colors.outline.b, 0.15)
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

                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.t("set.language")
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: root.mono
                        font.pixelSize: 11
                    }

                    Segment {
                        anchors.verticalCenter: parent.verticalCenter
                        current: Prefs.language
                        auto: false
                        options: [
                            { value: "en", label: "english" },
                            { value: "ru", label: "русский" }
                        ]
                        onPicked: (value) => Prefs.set("language", value)
                    }
                }

                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.t("set.barPosition")
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: root.mono
                        font.pixelSize: 11
                    }

                    Segment {
                        anchors.verticalCenter: parent.verticalCenter
                        current: Prefs.barPosition
                        auto: false
                        options: [
                            { value: "top", label: I18n.t("set.barTop") },
                            { value: "bottom", label: I18n.t("set.barBottom") }
                        ]
                        onPicked: (value) => Prefs.set("barPosition", value)
                    }
                }

                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.t("set.font")
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: root.mono
                        font.pixelSize: 11
                    }

                    Segment {
                        anchors.verticalCenter: parent.verticalCenter
                        current: Prefs.fontDisplay
                        auto: false
                        options: Fonts.displayChoices
                        onPicked: (value) => Prefs.set("fontDisplay", value)
                    }
                }

                Row {
                    width: parent.width
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.t("set.tone")
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: root.mono
                        font.pixelSize: 11
                    }

                    Segment {
                        anchors.verticalCenter: parent.verticalCenter
                        current: Prefs.notifySound
                        auto: false
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

                Row {
                    anchors.right: parent.right
                    spacing: 10

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

            Keys.onEscapePressed: root.close()
        }
    }
}
