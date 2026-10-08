import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: prc
    readonly property Item hero: box
    property color tint: Colors.accent

    property var demo: ({})
    readonly property var d: prc.demo && prc.demo.print ? prc.demo.print : null
    readonly property int queue: prc.d ? prc.d.queue : Printing.jobs.length

    IslandTile {
        id: box
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        size: 48
        glyph: "󰐪"
        tint: prc.tint
    }

    Rectangle {
        id: sheet
        x: box.x + box.width / 2 - width / 2
        width: 22
        height: 4
        radius: 2
        antialiasing: true
        color: "white"
        y: box.y + box.height - 10
        opacity: 0

        SequentialAnimation {
            running: prc.queue > 0
            loops: Animation.Infinite
            ParallelAnimation {
                NumberAnimation {
                    target: sheet; property: "y"
                    from: box.y + box.height - 12; to: box.y + box.height + 4
                    duration: 900; easing.type: Easing.OutCubic
                }
                SequentialAnimation {
                    NumberAnimation { target: sheet; property: "opacity"; from: 0; to: 0.95; duration: 200 }
                    NumberAnimation { target: sheet; property: "opacity"; to: 0; duration: 620 }
                }
            }
            PauseAnimation { duration: 320 }
        }
    }

    Column {
        anchors.left: box.right
        anchors.leftMargin: 16
        anchors.right: count.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        StatusLine {
            text: prc.queue > 0 ? I18n.t("isle.print.queue")
                                : I18n.t("isle.print.done")
            tint: prc.tint
            ok: prc.queue === 0
        }

        Text {
            width: parent.width
            text: prc.d ? prc.d.printer : Printing.selected !== "" ? Printing.selected
                                           : I18n.t("isle.src.print")
            color: Colors.fg
            font.family: Fonts.display
            font.pixelSize: 16
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    RollText {
        id: count
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        visible: prc.queue > 0
        text: visible ? String(prc.queue) : ""
        color: prc.tint
        family: Fonts.display
        pixelSize: 26
        weight: Font.DemiBold
    }
}
