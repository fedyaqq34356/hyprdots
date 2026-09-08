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
    property int step: 0

    readonly property string mono: Fonts.mono

    readonly property var steps: [
        {
            glyph: "󰄛",
            title: I18n.t("guide.hello.title"),
            body: I18n.t("guide.hello.body"),
            keys: ["Super+Shift+P"],
            tune: "start"
        },
        {
            glyph: "󰉼",
            title: I18n.t("guide.look.title"),
            body: I18n.t("guide.look.body"),
            keys: [],
            tune: "look"
        },
        {
            glyph: "󰍜",
            title: I18n.t("guide.panels.title"),
            body: I18n.t("guide.panels.body"),
            keys: ["Super+D", "Super+Tab", "Super+V", "Super+N", "Super+A"],
            tune: ""
        },
        {
            glyph: "󰕮",
            title: I18n.t("guide.desk.title"),
            body: I18n.t("guide.desk.body"),
            keys: ["Super+Shift+W"],
            tune: "desk"
        },
        {
            glyph: "󰖐",
            title: I18n.t("guide.place.title"),
            body: I18n.t("guide.place.body"),
            keys: [],
            tune: "place"
        },
        {
            glyph: "󰽉",
            title: I18n.t("guide.quick.title"),
            body: I18n.t("guide.quick.body"),
            keys: ["Super+Shift+G", "Super+Shift+A"],
            tune: ""
        },
        {
            glyph: "󰒲",
            title: I18n.t("guide.quiet.title"),
            body: I18n.t("guide.quiet.body"),
            keys: [],
            tune: "quiet"
        },
        {
            glyph: "󰔟",
            title: I18n.t("guide.time.title"),
            body: I18n.t("guide.time.body"),
            keys: ["Super+Shift+N", "Super+Ctrl+N"],
            tune: ""
        }
    ]

    readonly property var current: root.steps[Math.max(0, Math.min(root.steps.length - 1, root.step))]
    readonly property bool last: root.step >= root.steps.length - 1

    function open() {
        root.step = 0;
        root.shown = true;
        Sfx.tip();
    }

    function close() {
        if (!root.shown)
            return;
        root.shown = false;
        Prefs.set("guideSeen", true);
        Sfx.panelOut();
    }

    function next() {
        if (root.last) {
            root.close();
            return;
        }
        root.step++;
        Sfx.tip();
    }

    function back() {
        if (root.step === 0)
            return;
        root.step--;
        Sfx.pick();
    }

    Connections {
        target: Prefs
        function onLoadedChanged() {
            if (Prefs.loaded && !Prefs.guideSeen)
                delay.start();
        }
    }

    Timer {
        id: delay
        interval: 1200
        onTriggered: if (!Prefs.guideSeen) root.open()
    }

    WeatherHold { active: root.shown && root.current.tune === "place" }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-guide"
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
            color: Qt.rgba(0, 0, 0, 0.6)
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.slow } }
        }

        Glass {
            id: card

            anchors.centerIn: parent
            width: 520
            height: 452
            radius: Shape.modal
            elevation: 3
            tintOpacity: 0.92

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                NumberAnimation {
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.snap
                }
            }

            Item {
                id: stage

                anchors.fill: parent
                anchors.margins: 36
                clip: true

                Column {
                    id: page

                    width: parent.width
                    spacing: 14

                    transform: Translate { id: shift; x: 0 }

                    Text {
                        text: root.current.glyph
                        color: Colors.accent
                        font.family: root.mono
                        font.pixelSize: 40
                    }

                    Text {
                        text: root.current.title
                        color: Colors.fg
                        font.family: Fonts.display
                        font.pixelSize: 22
                    }

                    Text {
                        width: page.width
                        text: root.current.body
                        color: Colors.fgDim
                        opacity: 0.8
                        wrapMode: Text.WordWrap
                        lineHeight: 1.3
                        font.family: Fonts.display
                        font.pixelSize: 13
                    }

                    Loader {
                        width: page.width
                        active: root.current.tune !== ""
                        sourceComponent: {
                            switch (root.current.tune) {
                            case "start": return startTune;
                            case "look":  return lookTune;
                            case "desk":  return deskTune;
                            case "place": return placeTune;
                            case "quiet": return quietTune;
                            }
                            return null;
                        }
                    }

                    Flow {
                        width: page.width
                        spacing: 6

                        Repeater {
                            model: root.current.keys

                            Rectangle {
                                required property string modelData

                                width: keyLabel.implicitWidth + 18
                                height: 24
                                radius: 8
                                color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                               Colors.bgAlt.b, 0.75)
                                border.width: 1
                                border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                      Colors.outline.b, 0.2)

                                Text {
                                    id: keyLabel
                                    anchors.centerIn: parent
                                    text: parent.modelData
                                    color: Colors.accentAlt
                                    font.family: root.mono
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: startTune

                Column {
                    spacing: 10

                    SettingsChoice {
                        width: parent.width
                        mono: root.mono
                        label: I18n.t("set.language")
                        current: Prefs.language
                        options: [
                            { value: "en", label: "english" },
                            { value: "ru", label: "русский" }
                        ]
                        onPicked: (value) => {
                            Prefs.set("language", value);
                            Sfx.tapAlt();
                        }
                    }

                    SettingsChoice {
                        width: parent.width
                        mono: root.mono
                        label: I18n.t("set.font")
                        current: Prefs.fontDisplay
                        options: Fonts.displayChoices
                        onPicked: (value) => {
                            Prefs.set("fontDisplay", value);
                            Sfx.tapAlt();
                        }
                    }
                }
            }

            Component {
                id: lookTune

                Column {
                    spacing: 10

                    SettingsChoice {
                        width: parent.width
                        mono: root.mono
                        label: I18n.t("set.barPosition")
                        current: Prefs.barPosition
                        options: [
                            { value: "top", label: I18n.t("set.barTop") },
                            { value: "bottom", label: I18n.t("set.barBottom") }
                        ]
                        onPicked: (value) => {
                            Prefs.set("barPosition", value);
                            Sfx.tapAlt();
                        }
                    }

                    SettingsChoice {
                        width: parent.width
                        mono: root.mono
                        label: I18n.t("set.osd")
                        current: Prefs.osdStyle
                        options: [
                            { value: "island", label: I18n.t("set.osdIsland") },
                            { value: "panel", label: I18n.t("set.osdPanel") }
                        ]
                        onPicked: (value) => {
                            Prefs.set("osdStyle", value);
                            Sfx.tapAlt();
                        }
                    }

                    Item {
                        width: parent.width
                        height: 34

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            text: I18n.t("set.rounding")
                            color: Colors.fgDim
                            opacity: 0.7
                            font.family: root.mono
                            font.pixelSize: 11
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            text: Prefs.cornerRadius
                            color: Colors.fg
                            font.family: root.mono
                            font.pixelSize: 11
                        }

                        Slider {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            value: Prefs.cornerRadius / 48
                            onMoved: (value) =>
                                Prefs.set("cornerRadius", Math.round(value * 48))
                        }
                    }
                }
            }

            Component {
                id: deskTune

                Column {
                    spacing: 6

                    SettingsToggle {
                        width: parent.width
                        mono: root.mono
                        title: I18n.t("set.widgets")
                        hint: I18n.t("set.widgetsHint")
                        checked: Prefs.widgetsEnabled
                        onToggled: (value) => Prefs.set("widgetsEnabled", value)
                    }

                    SettingsToggle {
                        width: parent.width
                        mono: root.mono
                        title: I18n.t("set.dock")
                        hint: I18n.t("set.dockHint")
                        checked: Prefs.dockEnabled
                        onToggled: (value) => Prefs.set("dockEnabled", value)
                    }
                }
            }

            Component {
                id: placeTune

                Column {
                    spacing: 8

                    Field {
                        width: parent.width
                        height: 38
                        mono: root.mono
                        placeholder: I18n.t("set.placeInput")
                        text: Prefs.weatherPlace

                        onAccepted: (value) => {
                            Prefs.set("weatherPlace", value.trim());
                            Sfx.tapAlt();
                        }
                    }

                    Text {
                        width: parent.width
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
            }

            Component {
                id: quietTune

                Column {
                    spacing: 6

                    SettingsToggle {
                        width: parent.width
                        mono: root.mono
                        title: I18n.t("set.idle")
                        hint: I18n.t("set.idleHint")
                        checked: Prefs.idleEnabled
                        onToggled: (value) => Prefs.set("idleEnabled", value)
                    }

                    Item {
                        width: parent.width
                        height: 34
                        opacity: Prefs.idleEnabled ? 1 : 0.35

                        Text {
                            anchors.left: parent.left
                            anchors.top: parent.top
                            text: I18n.t("set.dimLead")
                            color: Colors.fgDim
                            opacity: 0.7
                            font.family: root.mono
                            font.pixelSize: 11
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            text: Prefs.idleDimLeadSec === 0
                                ? I18n.t("set.timerNone")
                                : Prefs.idleDimLeadSec + "s"
                            color: Colors.fg
                            font.family: root.mono
                            font.pixelSize: 11
                        }

                        Slider {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            enabled: Prefs.idleEnabled
                            value: Prefs.idleDimLeadSec / 180
                            onMoved: (value) =>
                                Prefs.set("idleDimLeadSec", Math.round(value * 180))
                        }
                    }

                    SettingsToggle {
                        width: parent.width
                        mono: root.mono
                        title: I18n.t("set.sfx")
                        hint: I18n.t("set.sfxHint")
                        checked: Prefs.sfxEnabled
                        onToggled: (value) => Prefs.set("sfxEnabled", value)
                    }
                }
            }

            SequentialAnimation {
                id: turn
                NumberAnimation {
                    target: shift; property: "x"; to: -18
                    duration: Motion.instant; easing.type: Easing.InQuad
                }
                PropertyAction { target: shift; property: "x"; value: 26 }
                NumberAnimation {
                    target: shift; property: "x"; to: 0
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.expo
                }
            }

            Connections {
                target: root
                function onStepChanged() { turn.restart(); }
            }

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 36
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 30
                spacing: 7

                Repeater {
                    model: root.steps.length

                    Rectangle {
                        required property int index

                        width: index === root.step ? 18 : 6
                        height: 6
                        radius: 3
                        color: index === root.step ? Colors.accent : Colors.fgDim
                        opacity: index === root.step ? 1 : 0.3
                        anchors.verticalCenter: parent.verticalCenter

                        Behavior on width {
                            NumberAnimation {
                                duration: Motion.base
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.snap
                            }
                        }
                        Behavior on opacity { NumberAnimation { duration: Motion.base } }
                    }
                }
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 30
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 22
                spacing: 10

                IconButton {
                    glyph: "󰅁"
                    tip: I18n.t("guide.back")
                    tint: Colors.fgDim
                    opacity: root.step === 0 ? 0.3 : 1
                    onActivated: root.back()
                }

                IconButton {
                    glyph: root.last ? "󰄬" : "󰅂"
                    tip: root.last ? I18n.t("guide.finish") : I18n.t("guide.next")
                    tint: root.last ? Colors.good : Colors.accent
                    onActivated: root.next()
                }
            }

            Keys.onEscapePressed: root.close()
            Keys.onRightPressed: root.next()
            Keys.onLeftPressed: root.back()
            Keys.onReturnPressed: root.next()
            Keys.onSpacePressed: root.next()
        }
    }
}
