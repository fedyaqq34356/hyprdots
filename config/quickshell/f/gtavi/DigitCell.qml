import QtQuick

Item {
    id: cell

    property string value: "0"
    property bool roll: true
    property string family: "Barlow Condensed"
    property int weight: Font.ExtraBold
    property real pixelSize: 100
    property color color: "#fff9cb"
    property real cellWidth: pixelSize * 0.5
    property int rollMs: 420
    property real capRatio: 0.70

    width: cellWidth
    height: metrics.height

    property string shown: ""
    Component.onCompleted: shown = value

    onValueChanged: {
        if (!roll || value === shown) {
            shown = value;
            return;
        }
        if (anim.running)
            anim.complete();
        before.text = shown;
        shown = value;
        anim.restart();
    }

    FontMetrics {
        id: metrics
        font.family: cell.family
        font.weight: cell.weight
        font.pixelSize: cell.pixelSize
    }

    Item {
        id: slot
        readonly property real pad: cell.pixelSize * 0.05
        y: metrics.ascent - cell.capRatio * cell.pixelSize - pad
        width: cell.cellWidth
        height: cell.capRatio * cell.pixelSize + 2 * pad
        clip: cell.roll

        Text {
            id: now
            y: -slot.y
            width: cell.cellWidth
            horizontalAlignment: Text.AlignHCenter
            text: cell.shown
            color: cell.color
            font: metrics.font
            textFormat: Text.PlainText
        }

        Text {
            id: before
            y: -slot.y
            width: cell.cellWidth
            horizontalAlignment: Text.AlignHCenter
            color: cell.color
            font: metrics.font
            textFormat: Text.PlainText
            visible: anim.running
        }
    }

    ParallelAnimation {
        id: anim
        readonly property real rest: -slot.y
        readonly property real travel: slot.height
        readonly property var curve: [0.32, 0.72, 0, 1, 1, 1]

        NumberAnimation { target: now; property: "y"; from: anim.rest + anim.travel; to: anim.rest
                          duration: cell.rollMs; easing.type: Easing.BezierSpline; easing.bezierCurve: anim.curve }
        NumberAnimation { target: before; property: "y"; from: anim.rest; to: anim.rest - anim.travel
                          duration: cell.rollMs; easing.type: Easing.BezierSpline; easing.bezierCurve: anim.curve }
        onFinished: { now.y = anim.rest; before.y = anim.rest; }
    }
}
