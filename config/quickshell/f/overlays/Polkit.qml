import Quickshell
import Quickshell.Services.Polkit
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    PolkitAgent {
        id: agent
        onAuthenticationRequestStarted: {
            root.error = "";
            Sfx.panelIn();
        }
    }

    property string error: ""

    readonly property var flow: agent.flow
    readonly property bool active: agent.isActive

    Connections {
        target: agent.flow
        ignoreUnknownSignals: true

        function onAuthenticationFailed() {
            root.error = agent.flow && agent.flow.supplementaryMessage
                ? agent.flow.supplementaryMessage
                : I18n.t("polkit.failed");
            Sfx.critical();
            shake.restart();
        }

        function onAuthenticationSucceeded() {
            root.error = "";
            Sfx.netConnect();
        }

        function onAuthenticationRequestCancelled() {
            root.error = "";
        }
    }

    PanelWindow {
            id: win

            WlrLayershell.namespace: "qs-polkit"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

            screen: Focus.screen
            visible: root.active

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            exclusiveZone: 0
            color: "transparent"

            readonly property string mono: "JetBrainsMono Nerd Font"

            Rectangle {
                id: dim

                anchors.fill: parent
                color: Qt.rgba(0, 0, 0, 0.55)
                opacity: 0
                Component.onCompleted: dimIn.start()

                NumberAnimation {
                    id: dimIn
                    target: dim
                    property: "opacity"
                    to: 1
                    duration: Motion.base
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: agent.flow && agent.flow.cancelAuthenticationRequest()
                }
            }

            Glass {
                id: card

                anchors.centerIn: parent
                width: 420
                elevation: 3
                height: body.implicitHeight + 56
                radius: Shape.modal

                transform: Translate { id: shift; x: 0 }

                opacity: 0
                scale: 0.94
                Component.onCompleted: {
                    cardIn.start();
                    password.grab();
                }

                ParallelAnimation {
                    id: cardIn
                    NumberAnimation {
                        target: card; property: "opacity"; to: 1
                        duration: Motion.base
                    }
                    NumberAnimation {
                        target: card; property: "scale"; to: 1
                        duration: Motion.slow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.snap
                    }
                }

                SequentialAnimation {
                    id: shake
                    NumberAnimation { target: shift; property: "x"; to: -12; duration: 55 }
                    NumberAnimation { target: shift; property: "x"; to: 10; duration: 65 }
                    NumberAnimation { target: shift; property: "x"; to: -6; duration: 60 }
                    NumberAnimation { target: shift; property: "x"; to: 0; duration: 70 }
                }

                Column {
                    id: body
                    anchors.centerIn: parent
                    width: parent.width - 56
                    spacing: 18

                    Row {
                        spacing: 14

                        Rectangle {
                            width: 46
                            height: 46
                            radius: Shape.field
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                           Colors.accent.b, 0.16)

                            Text {
                                anchors.centerIn: parent
                                text: "󰌾"
                                color: Colors.accent
                                font.family: win.mono
                                font.pixelSize: 20
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: I18n.t("polkit.title")
                                color: Colors.fg
                                font.family: Fonts.display
                                font.pixelSize: 15
                            }

                            Text {
                                width: body.width - 70
                                text: agent.flow && agent.flow.actionId
                                    ? agent.flow.actionId : ""
                                color: Colors.fgDim
                                opacity: 0.55
                                elide: Text.ElideMiddle
                                font.family: win.mono
                                font.pixelSize: 10
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: agent.flow && agent.flow.message
                            ? agent.flow.message
                            : I18n.t("polkit.body")
                        color: Colors.fgDim
                        wrapMode: Text.WordWrap
                        font.family: win.mono
                        font.pixelSize: 12
                    }

                    Field {
                        id: password

                        width: parent.width
                        secret: true
                        visible: !agent.flow || agent.flow.isResponseRequired !== false
                        placeholder: agent.flow && agent.flow.inputPrompt
                            ? agent.flow.inputPrompt.trim()
                            : I18n.t("polkit.password")
                        mono: win.mono

                        onAccepted: (value) => {
                            if (!agent.flow)
                                return;
                            Sfx.tapAlt();
                            agent.flow.submit(value);
                            password.clear();
                        }
                    }

                    Text {
                        width: parent.width
                        visible: root.error !== ""
                        text: root.error
                        color: Colors.bad
                        wrapMode: Text.WordWrap
                        font.family: win.mono
                        font.pixelSize: 11
                    }

                    Row {
                        anchors.right: parent.right
                        spacing: 10

                        IconButton {
                            glyph: "󰅖"
                            tip: I18n.t("act.cancel")
                            tint: Colors.bad
                            onActivated: agent.flow && agent.flow.cancelAuthenticationRequest()
                        }

                        IconButton {
                            glyph: "󰄬"
                            tip: I18n.t("act.confirm")
                            tint: Colors.good
                            onActivated: {
                                if (!agent.flow)
                                    return;
                                agent.flow.submit(password.text);
                                password.clear();
                            }
                        }
                    }
                }

                Keys.onEscapePressed: agent.flow && agent.flow.cancelAuthenticationRequest()
            }
        }
    
}
