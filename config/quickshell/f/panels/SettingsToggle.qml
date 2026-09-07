import QtQuick
import "root:/design"
import "root:/reusables"

Item {
    id: row

    property string title: ""
    property string hint: ""
    property bool checked: false
    property string mono: Fonts.mono

    signal toggled(bool value)

    implicitHeight: 44
    height: implicitHeight

    Rectangle {
        anchors.fill: parent
        anchors.margins: -8
        radius: Shape.chip
        color: hover.hovered
            ? Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.06)
            : "transparent"
        Behavior on color { ColorAnimation { duration: Motion.fast } }
    }

    HoverHandler { id: hover }

    Column {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width - 60
        spacing: 2

        Text {
            width: parent.width
            text: row.title
            color: Colors.fg
            opacity: row.checked ? 1 : 0.55
            elide: Text.ElideRight
            font.family: Fonts.display
            font.pixelSize: Fonts.headingSize
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: row.hint
            color: Colors.fgDim
            opacity: 0.45
            elide: Text.ElideRight
            font.family: row.mono
            font.pixelSize: 10
        }
    }

    Switch {
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        checked: row.checked
        onToggled: (value) => row.toggled(value)
    }
}
