import QtQuick
import "root:/design"
import "root:/reusables"

Column {
    id: choice

    property string label: ""
    property var options: []
    property string current: ""
    property string mono: "JetBrainsMono Nerd Font"

    signal picked(string value)

    readonly property bool wide: pills.implicitWidth > choice.width - name.implicitWidth - 24

    spacing: 8

    Item {
        width: parent.width
        height: choice.wide ? name.implicitHeight : Math.max(name.implicitHeight, 26)

        Text {
            id: name

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            text: choice.label
            color: Colors.fgDim
            opacity: 0.7
            font.family: choice.mono
            font.pixelSize: 11
        }

        Segment {
            id: pills

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !choice.wide
            mono: choice.mono
            auto: false
            options: choice.options
            current: choice.current
            onPicked: (value) => choice.picked(value)
        }
    }

    Segment {
        visible: choice.wide
        mono: choice.mono
        auto: false
        options: choice.options
        current: choice.current
        onPicked: (value) => choice.picked(value)
    }
}
