import QtQuick
import Quickshell.Widgets
import "root:/design"

Item {
    id: disc

    property string art: ""
    property bool spinning: false
    property int grooves: 11
    property real labelRatio: 0.5
    property int period: 18000

    implicitWidth: 160
    implicitHeight: 160

    scale: disc.spinning ? 1.0 : 0.965
    Behavior on scale {
        NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
    }

    Item {
        id: plate

        anchors.fill: parent

        RotationAnimator on rotation {
            running: disc.spinning
            loops: Animation.Infinite
            from: 0
            to: 360
            duration: disc.period
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            color: "#0b0b0d"
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.07)
        }

        Repeater {
            model: disc.grooves

            Rectangle {
                required property int index

                anchors.centerIn: parent
                width: disc.width * (0.96 - index * 0.055)
                height: width
                radius: width / 2
                color: "transparent"
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, index % 2 === 0 ? 0.06 : 0.03)
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: width / 2
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.00) }
                GradientStop { position: 0.42; color: Qt.rgba(1, 1, 1, 0.05) }
                GradientStop { position: 0.50; color: Qt.rgba(1, 1, 1, 0.09) }
                GradientStop { position: 0.58; color: Qt.rgba(1, 1, 1, 0.05) }
                GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.00) }
            }
        }

        ClippingRectangle {
            anchors.centerIn: parent
            width: disc.width * disc.labelRatio
            height: width
            radius: width / 2
            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.9)
            border.width: 1
            border.color: Qt.rgba(0, 0, 0, 0.55)

            Image {
                id: cover
                anchors.fill: parent
                source: disc.art
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                visible: disc.art !== "" && status === Image.Ready
            }

            Repeater {
                model: cover.visible ? 0 : 2

                Rectangle {
                    required property int index

                    anchors.centerIn: parent
                    width: parent.width * (0.78 - index * 0.28)
                    height: width
                    radius: width / 2
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                          Colors.fgDim.b, 0.18)
                }
            }
        }

        Rectangle {
            anchors.centerIn: parent
            width: Math.max(4, disc.width * 0.03)
            height: width
            radius: width / 2
            color: Qt.rgba(0, 0, 0, 0.85)
        }
    }
}
