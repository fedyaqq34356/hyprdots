import Quickshell.Widgets
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: orb

    property real size: 22
    property color tint: Colors.accent
    property bool live: true

    width: orb.size
    height: orb.size

    Spectrum {
        anchors.centerIn: parent
        width: orb.size
        height: orb.size
        visible: orb.live
        mode: "radial"
        tint: orb.tint
        hole: 0.58
        resolution: 26
        gap: 0.34
    }

    ClippingRectangle {
        anchors.centerIn: parent
        width: Math.round(orb.size * 0.56)
        height: width
        radius: width / 2
        color: Colors.alpha(Colors.bgAlt, 0.7)

        Image {
            anchors.fill: parent
            visible: Media.art !== ""
            source: Media.art
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            sourceSize.width: 48
        }

        Text {
            anchors.centerIn: parent
            visible: Media.art === ""
            text: "󰎈"
            color: orb.tint
            font.family: Fonts.glyph
            font.pixelSize: Math.max(7, parent.width * 0.6)
        }
    }
}
