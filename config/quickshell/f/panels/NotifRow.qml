import Quickshell
import Quickshell.Widgets
import QtQuick
import "root:/design"
import "root:/services"

Rectangle {
    id: row

    required property var entry
    property string mono: "JetBrainsMono Nerd Font"
    property bool fresh: false

    signal dismissed()

    readonly property bool critical: entry.critical === true
    readonly property color edge: critical ? Colors.bad : Colors.accent

    readonly property bool hasArt: entry.image !== "" || entry.icon !== ""
    readonly property color avatar: NotifHistory.appColor(entry.app)

    property bool leaving: false

    width: parent ? parent.width : 0
    height: Math.max(52, content.implicitHeight + 22)
    radius: 14

    color: hover.hovered ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.62)
                         : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.34)
    Behavior on color { ColorAnimation { duration: Motion.fast } }

    border.width: 1
    border.color: critical
        ? Qt.rgba(row.edge.r, row.edge.g, row.edge.b, 0.45)
        : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b,
                  hover.hovered ? 0.22 : 0.10)
    Behavior on border.color { ColorAnimation { duration: Motion.fast } }

    HoverHandler { id: hover }

    ParallelAnimation {
        id: leave
        onFinished: row.dismissed()

        NumberAnimation {
            target: slide; property: "x"; to: 60
            duration: Motion.base
            easing.type: Easing.Bezier
            easing.bezierCurve: Motion.quick
        }
        NumberAnimation {
            target: row; property: "opacity"; to: 0
            duration: Motion.base
        }
    }

    transform: Translate { id: slide }

    function dismiss() {
        if (row.leaving)
            return;
        row.leaving = true;
        leave.start();
    }

    Rectangle {
        visible: row.critical
        anchors.left: parent.left
        anchors.leftMargin: 1
        anchors.verticalCenter: parent.verticalCenter
        width: 3
        height: parent.height * 0.55
        radius: 2
        color: row.edge
    }

    Rectangle {
        id: iconBox
        anchors.left: parent.left
        anchors.leftMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        width: 30
        height: 30
        radius: 10
        color: row.critical
            ? Qt.rgba(row.edge.r, row.edge.g, row.edge.b, 0.18)
            : Qt.rgba(row.avatar.r, row.avatar.g, row.avatar.b, 0.16)

        IconImage {
            anchors.centerIn: parent
            visible: row.hasArt
            implicitSize: 18
            source: !row.hasArt ? ""
                : (row.entry.image !== "" ? row.entry.image
                                          : Quickshell.iconPath(row.entry.icon, ""))
        }

        Text {
            anchors.centerIn: parent
            visible: !row.hasArt
            text: NotifHistory.appLetter(row.entry.app)
            color: row.critical ? row.edge : row.avatar
            font.family: row.mono
            font.pixelSize: 14
            font.weight: Font.DemiBold
        }
    }

    Column {
        id: content
        anchors.left: iconBox.right
        anchors.leftMargin: 11
        anchors.right: parent.right
        anchors.rightMargin: 40
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Row {
            width: parent.width
            spacing: 6

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: row.fresh
                width: 5
                height: 5
                radius: 3
                color: Colors.accent
            }

            Text {
                width: parent.width - (row.fresh ? 11 : 0)
                text: row.entry.summary !== "" ? row.entry.summary : row.entry.app
                color: Colors.fg
                opacity: 0.95
                font.family: row.mono
                font.pixelSize: 11
                font.weight: Font.DemiBold
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }

        Text {
            width: parent.width
            visible: text !== ""
            text: row.entry.body
            color: Colors.fgDim
            opacity: 0.62
            font.family: row.mono
            font.pixelSize: 9
            wrapMode: Text.WordWrap
            elide: Text.ElideRight
            maximumLineCount: 2
        }
    }

    Text {
        id: stamp
        anchors.right: parent.right
        anchors.rightMargin: 12
        anchors.top: parent.top
        anchors.topMargin: 10
        text: NotifHistory.ago(row.entry.time)
        color: Colors.fgDim
        opacity: hover.hovered ? 0 : 0.45
        font.family: row.mono
        font.pixelSize: 9
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }
    }

    Rectangle {
        anchors.right: parent.right
        anchors.rightMargin: 9
        anchors.verticalCenter: parent.verticalCenter
        width: 22
        height: 22
        radius: 8
        color: closeHover.hovered
            ? Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.22)
            : "transparent"
        opacity: hover.hovered ? 1 : 0
        Behavior on color { ColorAnimation { duration: Motion.fast } }
        Behavior on opacity { NumberAnimation { duration: Motion.fast } }

        scale: closeTap.pressed ? 0.88 : 1
        Behavior on scale { Spring {} }

        HoverHandler { id: closeHover }
        TapHandler {
            id: closeTap
            onTapped: {
                Sfx.toggleOff();
                row.dismiss();
            }
        }

        Text {
            anchors.centerIn: parent
            text: "󰅖"
            color: closeHover.hovered ? Colors.bad : Colors.fgDim
            opacity: closeHover.hovered ? 1 : 0.6
            font.family: row.mono
            font.pixelSize: 10
        }
    }
}
