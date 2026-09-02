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

    readonly property string mono: "JetBrainsMono Nerd Font"

    readonly property var steps: [
        {
            glyph: "󰄛",
            title: I18n.t("guide.hello.title"),
            body: I18n.t("guide.hello.body"),
            keys: ["Super+Shift+P"]
        },
        {
            glyph: "󰍜",
            title: I18n.t("guide.panels.title"),
            body: I18n.t("guide.panels.body"),
            keys: ["Super+D", "Super+Tab", "Super+V", "Super+N", "Super+A"]
        },
        {
            glyph: "󰕮",
            title: I18n.t("guide.desk.title"),
            body: I18n.t("guide.desk.body"),
            keys: ["Super+Shift+W"]
        },
        {
            glyph: "󰽉",
            title: I18n.t("guide.quick.title"),
            body: I18n.t("guide.quick.body"),
            keys: ["Super+Shift+G", "Super+Shift+A"]
        },
        {
            glyph: "󰔟",
            title: I18n.t("guide.time.title"),
            body: I18n.t("guide.time.body"),
            keys: ["Super+Shift+N", "Super+Ctrl+N"]
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
            height: 300
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
