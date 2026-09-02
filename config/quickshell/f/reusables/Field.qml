import QtQuick
import "root:/design"
import "root:/services"

Rectangle {
    id: field

    property alias text: input.text
    property string placeholder: ""
    property bool secret: false
    property color tint: Colors.accent
    property string mono: "JetBrainsMono Nerd Font"

    signal accepted(string text)

    readonly property bool focused: input.activeFocus

    function grab() { input.forceActiveFocus(); }
    function clear() { input.text = ""; }

    height: 44
    radius: 14
    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.6)
    border.width: 1
    border.color: field.focused
        ? Qt.rgba(field.tint.r, field.tint.g, field.tint.b, 0.5)
        : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.18)
    Behavior on border.color { ColorAnimation { duration: Motion.fast } }

    TextInput {
        id: input

        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        verticalAlignment: TextInput.AlignVCenter
        color: Colors.fg
        font.family: field.mono
        font.pixelSize: 14
        clip: true
        selectByMouse: true
        selectionColor: Qt.rgba(field.tint.r, field.tint.g, field.tint.b, 0.35)

        echoMode: field.secret ? TextInput.Password : TextInput.Normal
        passwordCharacter: "•"

        property int lastLength: 0
        onTextChanged: {
            if (input.text.length !== input.lastLength)
                Sfx.type();
            input.lastLength = input.text.length;
        }

        onAccepted: field.accepted(input.text)
    }

    Text {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text === ""
        text: field.placeholder
        color: Colors.fgDim
        opacity: 0.4
        font.family: field.mono
        font.pixelSize: 13
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        x: 16 + input.positionToRectangle(input.cursorPosition).x
        width: 2
        height: 18
        radius: 1
        color: field.tint
        visible: field.focused

        SequentialAnimation on opacity {
            running: field.focused
            loops: Animation.Infinite
            NumberAnimation { to: 0.15; duration: 480; easing.type: Easing.InOutQuad }
            NumberAnimation { to: 1; duration: 480; easing.type: Easing.InOutQuad }
        }
    }
}
