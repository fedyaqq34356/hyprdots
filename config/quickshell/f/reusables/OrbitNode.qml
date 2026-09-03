import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: node

    property var item: null

    property color tint: "#ffffff"
    property string mono: "JetBrainsMono Nerd Font"
    property int appearDelay: 0

    property real depth: 1.0

    signal activated()
    signal scrolled(real delta)
    signal hoverToggled(bool on)
    signal holdToggled(bool on)

    property int holdTime: 620

    readonly property bool hovered: hover.hovered
    readonly property bool holding: press.pressed
    readonly property real charge: chargeState.value
    readonly property bool active: !!(node.item && node.item.active)
    readonly property bool working: !!(node.item && node.item.working)
    readonly property int bars: node.item && node.item.bars !== undefined
                              ? node.item.bars : -1

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    width: 96
    height: 44

    opacity: 0.5 + node.depth * 0.5
    scale: 0.9 + node.depth * 0.1

    HoverHandler {
        id: hover
        onHoveredChanged: node.hoverToggled(hovered)
    }
    QtObject {
        id: chargeState
        property real value: 0
        property int handle: -1
    }

    TapHandler {
        id: press

        onPressedChanged: {
            node.holdToggled(press.pressed);
            if (press.pressed) {
                release.stop();
                chargeState.handle = Sfx.loop(
                    Sfx.serp + "reusables/fillbutton/charge_loop.wav", 0.32);
                fill.restart();
            } else if (fill.running) {
                fill.stop();
                Sfx.stop(chargeState.handle);
                chargeState.handle = -1;
                Sfx.toggleOff();
                release.restart();
            }
        }
    }

    NumberAnimation {
        id: fill
        target: chargeState
        property: "value"
        to: 1
        duration: node.holdTime
        easing.type: Easing.Linear
        onFinished: {
            Sfx.stop(chargeState.handle);
            chargeState.handle = -1;
            Sfx.tapAlt();
            node.activated();
            release.restart();
        }
    }

    NumberAnimation {
        id: release
        target: chargeState
        property: "value"
        to: 0
        duration: Motion.base
        easing.type: Easing.OutCubic
    }
    WheelHandler {
        onWheel: event => {
            node.scrolled(event.angleDelta.y > 0 ? 1 : -1);
            event.accepted = true;
        }
    }
    Component.onDestruction: {
        if (hover.hovered) node.hoverToggled(false);
        if (press.pressed) node.holdToggled(false);
        Sfx.stop(chargeState.handle);
    }

    Item {
        id: content
        anchors.fill: parent

        opacity: hover.hovered ? 1.0 : 0.86
        Behavior on opacity { NumberAnimation { duration: 160 } }

        scale: press.pressed ? 1.06 + node.charge * 0.06
             : (hover.hovered ? 1.12 : 1.0)
        Behavior on scale { NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

        Item {
            anchors.fill: parent
            opacity: 0
            SequentialAnimation on opacity {
                running: true
                PauseAnimation { duration: node.appearDelay }
                NumberAnimation { from: 0; to: 1; duration: 340; easing.type: Easing.OutCubic }
            }

            RectRing {
                anchors.fill: parent
                anchors.margins: -3
                radius: Shape.field
                thickness: 2.5
                inset: 0
                value: node.charge
                color: node.tint
                visible: node.charge > 0.001
                z: 5
            }

            Rectangle {
                anchors.fill: parent
                anchors.margins: -4
                radius: Shape.field
                antialiasing: true
                color: "transparent"
                border.width: 3
                border.color: node.alpha(node.tint,
                    hover.hovered ? 0.26 : (node.active ? 0.18 : 0.07))
                Behavior on border.color { ColorAnimation { duration: 200 } }
            }

            Rectangle {
                anchors.fill: parent
                radius: Shape.chip
                antialiasing: true

                color: node.active ? node.alpha(node.tint, 0.26)
                     : hover.hovered ? node.alpha(Colors.bgAlt, 0.99)
                     : node.alpha(Colors.bgAlt, 0.78)
                Behavior on color { ColorAnimation { duration: 200 } }

                border.width: 1
                border.color: node.active ? node.alpha(node.tint, 0.65)
                            : hover.hovered ? node.alpha(node.tint, 0.5)
                            : node.alpha(Colors.outline, 0.22)
                Behavior on border.color { ColorAnimation { duration: 200 } }

                Rectangle {
                    visible: node.item && node.item.level !== undefined
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.margins: 6
                    height: 2
                    radius: 1
                    color: node.alpha(Colors.outline, 0.22)

                    Rectangle {
                        width: parent.width * Math.max(0, Math.min(1,
                            node.item && node.item.level !== undefined ? node.item.level : 0))
                        height: parent.height
                        radius: parent.radius
                        color: node.tint
                        opacity: node.active ? 0.95 : 0.55
                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }
                }

                Column {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset:
                        node.item && node.item.level !== undefined ? -3 : 0
                    width: parent.width - 14
                    spacing: 3

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: node.item ? node.item.title : ""
                        color: node.active ? Colors.fg : Colors.fgDim
                        opacity: node.active ? 1 : 0.94
                        elide: Text.ElideRight
                        font.family: node.mono
                        font.pixelSize: 10
                        font.weight: node.active ? Font.DemiBold : Font.Normal
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 5

                        Row {
                            visible: node.bars >= 0
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1.5

                            Repeater {
                                model: 4
                                Rectangle {
                                    required property int index
                                    readonly property bool lit: node.bars > index
                                    width: 2.5
                                    height: 3 + index * 2.5
                                    radius: 1.2
                                    anchors.bottom: parent.bottom
                                    color: lit ? (node.active ? node.tint : Colors.fg)
                                               : Colors.fgDim
                                    opacity: lit ? (node.active ? 1 : 0.72) : 0.16
                                    Behavior on opacity { NumberAnimation { duration: 250 } }
                                }
                            }
                        }

                        Text {
                            visible: node.bars < 0 && text !== ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: node.item && node.item.glyph ? node.item.glyph : ""
                            color: node.active ? node.tint : Colors.fgDim
                            opacity: node.active ? 1 : 0.75
                            font.family: node.mono
                            font.pixelSize: 11
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: node.item && node.item.detail ? node.item.detail : ""
                            color: node.active ? node.tint : Colors.fgDim
                            opacity: node.active ? 0.9 : 0.5
                            font.family: node.mono
                            font.pixelSize: 9
                        }

                        Text {
                            visible: !!(node.item && node.item.locked)
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰌾"
                            color: Colors.fgDim
                            opacity: 0.4
                            font.family: node.mono
                            font.pixelSize: 9
                        }
                    }
                }

                Rectangle {
                    anchors.fill: parent
                    radius: parent.radius
                    color: "transparent"
                    border.width: 1.5
                    border.color: node.tint
                    visible: node.working
                    SequentialAnimation on opacity {
                        running: node.working
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.15; to: 0.9; duration: 620 }
                        NumberAnimation { from: 0.9; to: 0.15; duration: 620 }
                    }
                }
            }
        }
    }
}
