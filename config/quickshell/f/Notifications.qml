import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Widgets
import QtQuick
import Quickshell.Wayland

Scope {
    id: root

    NotificationServer {
        id: server
        keepOnReload: false
        actionsSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        imageSupported: true

        onNotification: function (n) {
            n.tracked = true;
        }
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-notifications"
        id: win
        screen: Focus.screen

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusiveZone: 0
        color: "transparent"

        visible: !GameMode.active

        mask: Region { item: col }

        Column {
            id: col
            anchors.top: parent.top
            anchors.right: parent.right
            anchors.topMargin: 42
            anchors.rightMargin: 12
            spacing: 8

            move: Transition {
                NumberAnimation {
                    properties: "y"
                    duration: 280
                    easing.type: Easing.OutCubic
                }
            }

            Repeater {
                model: server.trackedNotifications

                Rectangle {
                    id: card
                    required property var modelData

                    readonly property bool critical:
                        modelData.urgency === NotificationUrgency.Critical
                    readonly property color edge:
                        critical ? Colors.bad : Colors.accent

                    width: 250
                    height: 48
                    radius: 13
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.94)
                    border.width: 1
                    border.color: Qt.rgba(edge.r, edge.g, edge.b, 0.38)

                    opacity: 0
                    scale: 0.15
                    transform: Translate { id: tr }

                    Component.onCompleted: {
                        const c = card.mapToItem(null, card.width / 2, card.height / 2);
                        tr.x = win.width / 2 - c.x;
                        tr.y = 17 - c.y;
                        burst.start();
                    }

                    ParallelAnimation {
                        id: burst

                        NumberAnimation {
                            target: tr; property: "x"; to: 0
                            duration: 560
                            easing.type: Easing.OutBack; easing.overshoot: 1.15
                        }
                        NumberAnimation {
                            target: tr; property: "y"; to: 0
                            duration: 560
                            easing.type: Easing.OutBack; easing.overshoot: 1.15
                        }
                        NumberAnimation {
                            target: card; property: "scale"; to: 1
                            duration: 520
                            easing.type: Easing.OutBack; easing.overshoot: 1.4
                        }
                        NumberAnimation {
                            target: card; property: "opacity"; to: 1
                            duration: 220
                        }
                    }

                    Behavior on scale {
                        enabled: !burst.running
                        NumberAnimation { duration: 150 }
                    }

                    Rectangle {
                        width: 3
                        height: parent.height - 16
                        radius: 2
                        color: card.edge
                        anchors.left: parent.left
                        anchors.leftMargin: 7
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Timer {
                        interval: card.modelData.expireTimeout > 0
                                  ? card.modelData.expireTimeout
                                  : 5000
                        running: !card.critical
                        onTriggered: card.modelData.dismiss()
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 18
                        anchors.rightMargin: 12
                        spacing: 9

                        IconImage {
                            visible: source !== ""
                            source: card.modelData.image !== ""
                                    ? card.modelData.image
                                    : Quickshell.iconPath(card.modelData.appIcon,
                                                          "dialog-information")
                            implicitSize: 22
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - 40
                            spacing: 0
                            anchors.verticalCenter: parent.verticalCenter

                            Text {
                                width: parent.width
                                text: card.modelData.summary
                                color: Colors.fg
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: card.modelData.appName
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.60)
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 9
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        hoverEnabled: true
                        onEntered: card.scale = 1.02
                        onExited: card.scale = 1.0
                        onClicked: card.modelData.dismiss()
                    }
                }
            }
        }
    }
}
