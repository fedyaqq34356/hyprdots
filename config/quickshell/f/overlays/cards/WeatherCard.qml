import Quickshell
import QtQuick
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: wc
    readonly property Item hero: cloud

    property color tint: Colors.accent
    property var info: ({})

    readonly property bool snow: wc.info.kind === "snow"

    Item {
        id: sky
        anchors.fill: parent
        anchors.margins: -12
        opacity: 1

        SequentialAnimation on opacity {
            running: true
            PauseAnimation { duration: 2600 }
            NumberAnimation { to: 0; duration: 900; easing.type: Easing.InOutSine }
        }
        visible: opacity > 0.01

        Repeater {
            model: wc.snow ? 20 : 26

            Item {
                id: bit
                required property int index

                readonly property real seed: (bit.index * 0.6180339) % 1
                readonly property real lane: (bit.index + 0.5) / (wc.snow ? 20 : 26)
                readonly property real fall: wc.snow ? 2400 + bit.seed * 1400
                                                     : 520 + bit.seed * 300
                readonly property real startX: bit.lane * sky.width

                x: bit.startX
                y: -16

                Rectangle {
                    width: wc.snow ? 3 + bit.seed * 2.5 : 1.5
                    height: wc.snow ? width : 9 + bit.seed * 7
                    radius: width / 2
                    rotation: wc.snow ? 0 : 14
                    antialiasing: true
                    color: wc.snow ? Qt.rgba(1, 1, 1, 0.75 + 0.2 * bit.seed)
                                   : Colors.alpha(Qt.lighter(wc.tint, 1.4),
                                                  0.35 + 0.35 * bit.seed)
                }

                SequentialAnimation on y {
                    loops: Animation.Infinite
                    PauseAnimation { duration: bit.seed * bit.fall }
                    NumberAnimation {
                        from: -16
                        to: sky.height + 8
                        duration: bit.fall
                        easing.type: wc.snow ? Easing.Linear : Easing.InQuad
                    }
                }

                SequentialAnimation on x {
                    loops: Animation.Infinite
                    PauseAnimation { duration: bit.seed * bit.fall }
                    NumberAnimation {
                        from: bit.startX
                        to: bit.startX - (wc.snow ? 10 : 6)
                        duration: wc.snow ? bit.fall / 2 : bit.fall
                        easing.type: Easing.InOutSine
                    }
                    NumberAnimation {
                        to: bit.startX
                        duration: wc.snow ? bit.fall / 2 : 1
                        easing.type: Easing.InOutSine
                    }
                }
            }
        }
    }

    IslandTile {
        id: cloud
        anchors.left: parent.left
        anchors.leftMargin: 2
        anchors.verticalCenter: parent.verticalCenter
        size: 50
        round: true
        glyph: wc.snow ? "󰖘" : "󰖗"
        tint: wc.tint
        sonar: true
    }

    Column {
        anchors.left: cloud.right
        anchors.leftMargin: 16
        anchors.right: chance.left
        anchors.rightMargin: 12
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Text {
            width: parent.width
            text: I18n.t(wc.snow ? "isle.sky.snow" : "isle.sky.rain")
            color: Qt.lighter(wc.tint, 1.2)
            font.family: Fonts.display
            font.pixelSize: 12
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Text {
            width: parent.width
            text: wc.info.when || ""
            color: Colors.fg
            font.family: Fonts.display
            font.pixelSize: 20
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }
    }

    Row {
        id: chance
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        visible: (wc.info.chance || 0) > 0

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰖌"
            color: wc.tint
            font.family: Fonts.glyph
            font.pixelSize: 16
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: (wc.info.chance || 0) + "%"
            color: Colors.fg
            font.family: Fonts.display
            font.pixelSize: 24
            font.weight: Font.DemiBold
        }
    }
}
