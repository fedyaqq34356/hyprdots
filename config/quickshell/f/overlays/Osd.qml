import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    readonly property bool active:
        Prefs.osdStyle === "panel" && Feedback.shown

    PanelWindow {
        WlrLayershell.namespace: "qs-osd"
        id: win

        screen: Focus.screen
        visible: root.active

        anchors.bottom: true
        exclusiveZone: 0
        implicitWidth: 260
        implicitHeight: 130
        color: "transparent"
        mask: Region {}

        Rectangle {
            anchors.centerIn: card
            width: card.width + 40
            height: card.height + 40
            radius: Shape.card + 20
            color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.5)
            opacity: 0
            visible: opacity > 0.01

            layer.enabled: true
            layer.effect: MultiEffect {
                blurEnabled: true
                blur: 1.0
                blurMax: 48
            }

            SequentialAnimation on opacity {
                running: root.active
                NumberAnimation { to: 0.22; duration: Motion.instant }
                NumberAnimation { to: 0.0; duration: Motion.lazy; easing.type: Easing.OutCubic }
            }
        }

        Glass {
            id: card

            anchors.centerIn: parent
            width: 224
            height: Feedback.showBar ? 110 : 78
            radius: Shape.card
            elevation: 2
            tintOpacity: 0.9

            opacity: root.active ? 1 : 0
            scale: root.active ? 1 : 0.9
            y: root.active ? (parent.height - height) / 2
                           : (parent.height - height) / 2 + 22

            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
            Behavior on scale { Spring {} }
            Behavior on y {
                NumberAnimation {
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.expo
                }
            }
            Behavior on height {
                NumberAnimation {
                    duration: Motion.base
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.decel
                }
            }

            SequentialAnimation {
                id: nudge
                NumberAnimation { target: card; property: "scale"; to: 1.035; duration: Motion.instant }
                NumberAnimation {
                    target: card; property: "scale"; to: 1.0; duration: Motion.slow
                    easing.type: Easing.Bezier; easing.bezierCurve: Motion.snap
                }
            }

            Connections {
                target: Feedback
                function onPulseChanged() {
                    if (root.active)
                        nudge.restart();
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: 12
                width: parent.width - 40

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 12

                    Text {
                        id: glyph

                        text: Feedback.icon
                        color: Colors.accent
                        font.family: Fonts.glyph
                        font.pixelSize: 22
                        anchors.verticalCenter: parent.verticalCenter

                        SequentialAnimation {
                            id: pop
                            NumberAnimation { target: glyph; property: "scale"; to: 1.18; duration: Motion.instant }
                            NumberAnimation {
                                target: glyph; property: "scale"; to: 1.0; duration: Motion.base
                                easing.type: Easing.Bezier; easing.bezierCurve: Motion.snap
                            }
                        }

                        Connections {
                            target: Feedback
                            function onPulseChanged() { pop.restart(); }
                        }
                    }

                    RollText {
                        text: Feedback.label
                        color: Colors.fg
                        family: Fonts.mono
                        pixelSize: 15
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                WaveMeter {
                    visible: Feedback.showBar
                    width: parent.width
                    height: 26

                    value: Feedback.value
                    flat: Feedback.flat
                    spectrum: Cava.active ? Cava.levels : []
                    animating: root.active

                    fillColor: Colors.accent
                    trackColor: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                        Colors.fgDim.b, 0.22)
                }
            }
        }
    }
}
