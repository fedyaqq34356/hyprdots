import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
import QtQuick
import Quickshell.Wayland

Scope {
    id: root

    property bool shown: false

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    Connections {
        target: Media
        function onHasChanged() { if (!Media.has) root.close(); }
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-media"
        id: win
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.30 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.16
            width: 380
            height: body.implicitHeight + 36
            radius: 22
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
            border.width: 1
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.30)

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 190 } }
            Behavior on scale { NumberAnimation { duration: 280; easing.type: Easing.OutBack } }

            focus: true
            Keys.onEscapePressed: root.close()
            Keys.onSpacePressed: Media.toggle()

            Column {
                id: body
                anchors.fill: parent
                anchors.margins: 18
                spacing: 14

                Row {
                    width: parent.width
                    spacing: 14

                    Rectangle {
                        width: 76
                        height: 76
                        radius: 14
                        clip: true
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.6)

                        Image {
                            id: cover
                            anchors.fill: parent
                            source: Media.art
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: Media.art !== "" && status === Image.Ready
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !cover.visible
                            text: "󰎈"
                            color: Colors.fgDim
                            opacity: 0.45
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 30
                        }
                    }

                    Column {
                        width: parent.width - 90
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            width: parent.width
                            text: Media.title !== "" ? Media.title : "Ничего не играет"
                            color: Colors.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: Media.artist !== ""
                            text: Media.artist
                            color: Colors.fgDim
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: Media.source !== ""
                            text: Media.source
                            color: Colors.fgDim
                            opacity: 0.45
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                    }
                }

                Column {
                    width: parent.width
                    spacing: 6
                    visible: Media.hasPosition

                    Rectangle {
                        id: track
                        width: parent.width
                        height: 4
                        radius: 2
                        color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.25)

                        Rectangle {
                            width: parent.width * Media.progress
                            height: parent.height
                            radius: parent.radius
                            color: Colors.accent
                            Behavior on width { NumberAnimation { duration: 250 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -7
                            cursorShape: Qt.PointingHandCursor
                            onClicked: mouse => Media.seekTo(mouse.x / width)
                        }
                    }

                    Row {
                        width: parent.width

                        Text {
                            text: Media.has ? Media.clock(Media.player.position) : "0:00"
                            color: Colors.fgDim
                            opacity: 0.6
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }

                        Item { width: parent.width - 80; height: 1 }

                        Text {
                            text: Media.has ? Media.clock(Media.player.length) : "0:00"
                            color: Colors.fgDim
                            opacity: 0.6
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }
                }

                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 18

                    component Ctl: Rectangle {
                        property string glyph: ""
                        property bool enabled: true
                        property bool primary: false
                        signal activated

                        width: primary ? 42 : 32
                        height: width
                        radius: width / 2
                        color: primary
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b,
                                      hover.hovered ? 0.30 : 0.18)
                            : hover.hovered
                                ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
                                : "transparent"
                        opacity: enabled ? 1 : 0.30

                        Behavior on color { ColorAnimation { duration: 150 } }

                        HoverHandler { id: hover; enabled: parent.enabled }

                        Text {
                            anchors.centerIn: parent
                            text: parent.glyph
                            color: parent.primary ? Colors.accent : Colors.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: parent.primary ? 16 : 13
                        }

                        MouseArea {
                            anchors.fill: parent
                            enabled: parent.enabled
                            cursorShape: Qt.PointingHandCursor
                            onClicked: parent.activated()
                        }
                    }

                    Ctl {
                        glyph: "󰒮"
                        enabled: Media.canPrev
                        anchors.verticalCenter: parent.verticalCenter
                        onActivated: Media.previous()
                    }

                    Ctl {
                        glyph: Media.playing ? "󰏤" : "󰐊"
                        primary: true
                        enabled: Media.canToggle
                        anchors.verticalCenter: parent.verticalCenter
                        onActivated: Media.toggle()
                    }

                    Ctl {
                        glyph: "󰒭"
                        enabled: Media.canNext
                        anchors.verticalCenter: parent.verticalCenter
                        onActivated: Media.next()
                    }
                }
            }
        }
    }
}
