import Quickshell
import QtQuick
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: cc
    readonly property Item hero: badge

    property color tint: Colors.accent
    property var info: ({})
    property string took: ""

    signal focusWin(string win)

    readonly property bool ok: cc.info.ok !== false
    readonly property string win: cc.info.win || ""

    IslandTile {
        id: badge
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        size: 50
        round: true
        glyph: cc.ok ? "󰄬" : "󰅖"
        tint: cc.tint
        sonar: cc.ok
        sparks: cc.ok
        implode: !cc.ok

        transform: Translate {
            SequentialAnimation on x {
                running: !cc.ok
                NumberAnimation { to: -5; duration: 50 }
                NumberAnimation { to: 5;  duration: 70 }
                NumberAnimation { to: -3; duration: 60 }
                NumberAnimation { to: 2;  duration: 60 }
                NumberAnimation { to: 0;  duration: 60 }
            }
        }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: 16
        anchors.right: back.visible ? back.left : parent.right
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        StatusLine {
            text: cc.ok
                  ? I18n.t("isle.cmd.ok") + "  ·  " + cc.took
                  : I18n.t("isle.cmd.fail") + " " + (cc.info.code || 0)
                    + "  ·  " + cc.took
            tint: cc.tint
            ok: cc.ok
        }

        Marquee {
            width: parent.width
            text: cc.info.line || ""
            color: Colors.fg
            family: Fonts.mono
            pixelSize: 14
            weight: Font.DemiBold
        }
    }

    RoundKey {
        id: back
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        visible: cc.win !== ""
        glyph: "󰆍"
        tint: cc.tint
        onActivated: cc.focusWin(cc.win)
    }
}
