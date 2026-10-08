import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: card
    readonly property Item hero: thumb
    property string clipImage: ""
    property string clipText: ""
    property color tint: Colors.accent

    ClippingRectangle {
        id: thumb
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        width: Math.min(parent.width * 0.42,
                        shot.implicitHeight > 0
                            ? height * shot.implicitWidth / shot.implicitHeight
                            : height)
        radius: 14
        color: Colors.alpha(card.tint, 0.16)
        border.width: 1
        border.color: Colors.alpha(Colors.fg, 0.12)

        scale: 0.6
        rotation: -6
        Component.onCompleted: { thumb.scale = 1; thumb.rotation = 0; }
        Behavior on scale { Spring {} }
        Behavior on rotation { Spring {} }

        Image {
            id: shot
            anchors.fill: parent
            source: card.clipImage
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            mipmap: true
            smooth: true
        }
    }

    Column {
        anchors.left: thumb.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Text {
            text: I18n.t("isle.clip.copied")
            color: Colors.alpha(Colors.fg, 0.45)
            font.family: Fonts.display
            font.pixelSize: 11
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 0.4
        }

        Text {
            width: parent.width
            text: card.clipText !== "" ? card.clipText : I18n.t("isle.clip.image")
            color: Colors.fg
            font.family: Fonts.display
            font.pixelSize: 14
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            visible: shot.status === Image.Ready
            text: shot.implicitWidth + " × " + shot.implicitHeight
            color: card.tint
            font.family: Fonts.mono
            font.pixelSize: 12
        }
    }
}
