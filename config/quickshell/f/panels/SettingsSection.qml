import QtQuick
import "root:/design"

Column {
    id: section

    property string glyph: ""
    property string title: ""
    property string mono: Fonts.mono

    default property alias rows: inner.data

    spacing: 12

    Row {
        spacing: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: section.glyph
            color: Colors.accent
            opacity: 0.85
            font.family: section.mono
            font.pixelSize: 13
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: section.title
            color: Colors.fgDim
            opacity: 0.7
            font.family: section.mono
            font.pixelSize: 10
            font.letterSpacing: 2
        }
    }

    Rectangle {
        width: section.width
        height: inner.implicitHeight + 32
        radius: Shape.field
        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.28)
        border.width: 1
        border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                              Colors.outline.b, 0.12)

        Column {
            id: inner

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 16
        }
    }
}
