import Quickshell
import Quickshell.Widgets
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: cc
    property color tint: Colors.accent
    property var call: null

    signal accept()
    signal decline()

    readonly property string name: cc.call ? cc.call.name : ""
    readonly property string app: cc.call ? cc.call.app : ""
    readonly property string image: cc.call ? cc.call.image : ""
    readonly property string iconSrc: {
        const i = cc.call ? cc.call.icon : "";
        return i === "" ? "" : i.startsWith("/") || i.startsWith("image:")
            ? i : Quickshell.iconPath(i, true);
    }

    readonly property color green: Qt.rgba(0.20, 0.78, 0.35, 1)
    readonly property color red: Qt.rgba(1.0, 0.23, 0.19, 1)

    Item {
        id: face
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        width: 50
        height: 50

        Repeater {
            model: 2
            Rectangle {
                id: ring
                required property int index
                anchors.centerIn: parent
                width: face.width
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 2
                border.color: cc.tint
                opacity: 0

                SequentialAnimation {
                    running: cc.visible
                    loops: Animation.Infinite
                    PauseAnimation { duration: ring.index * 600 }
                    ParallelAnimation {
                        NumberAnimation { target: ring; property: "scale"; from: 1; to: 1.7; duration: 1800; easing.type: Easing.OutCubic }
                        NumberAnimation { target: ring; property: "opacity"; from: 0.9; to: 0; duration: 1800; easing.type: Easing.OutQuad }
                    }
                    PauseAnimation { duration: (1 - ring.index) * 600 }
                }
            }
        }

        Item {
            id: pulse
            anchors.fill: parent

            SequentialAnimation on scale {
                running: cc.visible
                loops: Animation.Infinite
                NumberAnimation { from: 1; to: 1.06; duration: 600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1.06; to: 1; duration: 600; easing.type: Easing.InOutSine }
            }

            Rectangle {
                anchors.fill: parent
                visible: !photo.visible
                radius: width / 2
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.lighter(cc.tint, 1.2) }
                    GradientStop { position: 1; color: Qt.darker(cc.tint, 1.5) }
                }
                Text {
                    anchors.centerIn: parent
                    text: NotifHistory.appLetter(cc.name)
                    color: "white"
                    font.family: Fonts.display
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }
            }

            ClippingRectangle {
                id: photo
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                visible: cc.image !== "" && pic.status === Image.Ready
                Image {
                    id: pic
                    anchors.fill: parent
                    source: cc.image
                    fillMode: Image.PreserveAspectCrop
                    sourceSize.width: 100
                    sourceSize.height: 100
                    asynchronous: true
                }
            }
        }

        Rectangle {
            visible: cc.iconSrc !== ""
            width: 20
            height: 20
            radius: 6
            x: parent.width - width + 4
            y: parent.height - height + 4
            color: "black"
            IconImage {
                anchors.fill: parent
                anchors.margins: 1.5
                source: cc.iconSrc
                asynchronous: true
            }
        }
    }

    Column {
        anchors.left: face.right
        anchors.leftMargin: 14
        anchors.right: keys.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: cc.name
            color: Colors.fg
            font.family: Fonts.display
            font.pixelSize: 16
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: cc.app + " · " + I18n.t("isle.call")
            color: Colors.alpha(Colors.fg, 0.55)
            font.family: Fonts.display
            font.pixelSize: 12
            elide: Text.ElideRight
        }
    }

    Row {
        id: keys
        anchors.right: parent.right
        anchors.rightMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        CallKey {
            hue: cc.red
            glyph: "󰏷"
            onHit: cc.decline()
        }

        CallKey {
            id: yes
            hue: cc.green
            glyph: "󰏲"
            onHit: cc.accept()

            SequentialAnimation on rotation {
                running: cc.visible
                loops: Animation.Infinite
                PauseAnimation { duration: 900 }
                NumberAnimation { to: -14; duration: 80; easing.type: Easing.OutQuad }
                NumberAnimation { to: 12; duration: 110; easing.type: Easing.InOutQuad }
                NumberAnimation { to: -6; duration: 100; easing.type: Easing.InOutQuad }
                NumberAnimation { to: 0; duration: 90; easing.type: Easing.OutQuad }
            }
        }
    }

    component CallKey: Rectangle {
        id: key
        property color hue: "white"
        property string glyph: ""
        signal hit()

        width: 44
        height: 44
        radius: width / 2
        antialiasing: true
        color: hov.hovered ? Qt.lighter(key.hue, 1.12) : key.hue
        scale: tap.pressed ? 0.9 : hov.hovered ? 1.08 : 1
        Behavior on scale { Spring {} }
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        Text {
            anchors.centerIn: parent
            text: key.glyph
            color: "white"
            font.family: Fonts.glyph
            font.pixelSize: 20
        }

        HoverHandler { id: hov; cursorShape: Qt.PointingHandCursor }
        TapHandler { id: tap; onTapped: key.hit() }
    }
}
