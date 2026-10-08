import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Row {
    id: sl
    property string text: ""
    property color tint: Colors.accent
    property bool ok: true
    spacing: 5

    IslandCheck {
        anchors.verticalCenter: parent.verticalCenter
        visible: sl.ok
        width: 13
        height: 13
        tint: sl.tint
    }

    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: sl.text
        color: sl.tint
        font.family: Fonts.display
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }
}
