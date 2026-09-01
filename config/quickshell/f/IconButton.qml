import QtQuick

Rectangle {
    id: button

    property string glyph: ""
    property color tint: "#ffffff"
    property string mono: "JetBrainsMono Nerd Font"
    property string tip: ""
    property bool spinning: false

    signal activated()

    width: 36
    height: 36
    radius: 13

    color: hover.hovered ? Qt.rgba(button.tint.r, button.tint.g, button.tint.b, 0.22)
                         : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.6)
    Behavior on color { ColorAnimation { duration: 160 } }

    border.width: 1
    border.color: hover.hovered
        ? Qt.rgba(button.tint.r, button.tint.g, button.tint.b, 0.4)
        : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.16)
    Behavior on border.color { ColorAnimation { duration: 160 } }

    scale: tap.pressed ? 0.93 : 1
    Behavior on scale { NumberAnimation { duration: 120 } }

    HoverHandler { id: hover }
    TapHandler { id: tap; onTapped: button.activated() }

    Text {
        anchors.centerIn: parent
        text: button.glyph
        color: hover.hovered ? button.tint : Colors.fgDim
        opacity: hover.hovered ? 1 : 0.7
        font.family: button.mono
        font.pixelSize: 14

        RotationAnimation on rotation {
            running: button.spinning
            loops: Animation.Infinite
            from: 0; to: 360; duration: 1100
        }
    }

    Rectangle {
        visible: hover.hovered && button.tip !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.bottom
        anchors.topMargin: 6
        width: tipText.implicitWidth + 16
        height: 22
        radius: 8
        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
        border.width: 1
        border.color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)
        z: 10

        Text {
            id: tipText
            anchors.centerIn: parent
            text: button.tip
            color: Colors.fgDim
            font.family: button.mono
            font.pixelSize: 10
        }
    }
}
