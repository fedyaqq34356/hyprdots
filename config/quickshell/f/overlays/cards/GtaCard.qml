import Quickshell
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/gtavi"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: gtac
    property real rem: Math.max(0, GtaConfig.releaseFallbackMs - Date.now())

    FrameAnimation {
        running: true
        onTriggered: gtac.rem = Math.max(0, GtaConfig.releaseFallbackMs - Date.now())
    }

    function two(n) { return String(n).padStart(2, "0"); }
    readonly property string clock: gtac.two(Math.floor(gtac.rem / 86400000)) + ":"
        + gtac.two(Math.floor(gtac.rem / 3600000) % 24) + ":"
        + gtac.two(Math.floor(gtac.rem / 60000) % 60) + ":"
        + gtac.two(Math.floor(gtac.rem / 1000) % 60)
    readonly property string ms: String(Math.floor(gtac.rem % 1000)).padStart(3, "0")

    FontMetrics { id: gtaBig; font.family: "Barlow Condensed"; font.weight: Font.ExtraBold; font.pixelSize: 34 }
    FontMetrics { id: gtaSmall; font.family: "Barlow Condensed"; font.weight: Font.Bold; font.pixelSize: 19 }
    readonly property real cell: {
        let w = 0;
        for (let d = 0; d <= 9; d++)
            w = Math.max(w, gtaBig.advanceWidth(String(d)));
        return Math.ceil(w) + 1;
    }

    Image {
        id: viMark
        anchors.left: parent.left
        anchors.leftMargin: 4
        anchors.verticalCenter: parent.verticalCenter
        height: 46
        width: height * sourceSize.width / Math.max(1, sourceSize.height)
        source: Qt.resolvedUrl("../../gtavi/assets/vi-mark.png")
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
    }

    Column {
        anchors.left: viMark.right
        anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Text {
            text: gtac.rem > 0 ? "GRAND THEFT AUTO VI" : "GRAND THEFT AUTO VI · OUT NOW"
            color: "#e5ddff"
            opacity: 0.6
            font.family: "Lexend"
            font.weight: Font.DemiBold
            font.pixelSize: 10
            font.letterSpacing: 2.6
        }

        Row {
            Repeater {
                model: gtac.clock.length
                Item {
                    required property int index
                    readonly property string ch: gtac.clock.charAt(index)
                    width: ch === ":" ? 12 : gtac.cell
                    height: gtaBig.height

                    Text {
                        visible: parent.ch === ":"
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: -(0.70 * 34 - gtaBig.xHeight) / 2
                        text: ":"
                        color: "#f976b0"
                        font.family: "Barlow Condensed"
                        font.weight: Font.Bold
                        font.pixelSize: 34
                    }
                    DigitCell {
                        visible: parent.ch !== ":"
                        value: parent.ch === ":" ? "0" : parent.ch
                        family: "Barlow Condensed"
                        weight: Font.ExtraBold
                        pixelSize: 34
                        cellWidth: gtac.cell
                        color: "#fff9cb"
                        rollMs: 360
                    }
                }
            }

            Item {
                width: msText.implicitWidth + 4
                height: gtaBig.height
                Text {
                    id: msText
                    x: 4
                    y: gtaBig.ascent - gtaSmall.ascent
                    text: "." + gtac.ms
                    color: "#f976b0"
                    font.family: "Barlow Condensed"
                    font.weight: Font.Bold
                    font.pixelSize: 19
                    font.features: { "tnum": 1 }
                }
            }
        }

        Text {
            text: "NOVEMBER 19, 2026  ·  CLICK TO OPEN"
            color: "#e5ddff"
            opacity: 0.45
            font.family: "Lexend"
            font.weight: Font.DemiBold
            font.pixelSize: 9
            font.letterSpacing: 2.2
        }
    }
}
