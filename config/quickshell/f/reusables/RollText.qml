import QtQuick

Row {
    id: root

    property string text: ""
    property color color: "white"
    property string family: "JetBrainsMono Nerd Font"
    property int pixelSize: 12
    property int weight: Font.DemiBold
    property int rollDuration: 320

    TextMetrics {
        id: metrics
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        text: "0"
    }

    Repeater {
        model: root.text.length

        Item {
            id: cell
            required property int index
            readonly property string ch: root.text.charAt(index)

            width: metrics.width
            height: metrics.height * 1.25
            clip: true

            Text {
                id: outgoing
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                y: (cell.height - metrics.height) / 2
                text: cell.ch
                color: root.color
                font.family: root.family
                font.pixelSize: root.pixelSize
                font.weight: root.weight
            }

            Text {
                id: incoming
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                y: cell.height
                text: ""
                color: root.color
                font.family: root.family
                font.pixelSize: root.pixelSize
                font.weight: root.weight
            }

            onChChanged: {
                if (roll.running)
                    roll.complete();
                if (outgoing.text === cell.ch)
                    return;
                incoming.text = cell.ch;
                roll.restart();
            }

            ParallelAnimation {
                id: roll

                NumberAnimation {
                    target: outgoing; property: "y"
                    to: -metrics.height
                    duration: root.rollDuration
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: incoming; property: "y"
                    to: (cell.height - metrics.height) / 2
                    duration: root.rollDuration
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: outgoing; property: "opacity"
                    from: 1; to: 0
                    duration: root.rollDuration
                }
                NumberAnimation {
                    target: incoming; property: "opacity"
                    from: 0; to: 1
                    duration: root.rollDuration
                }

                onFinished: {
                    outgoing.text = incoming.text;
                    outgoing.y = (cell.height - metrics.height) / 2;
                    outgoing.opacity = 1;
                    incoming.y = cell.height;
                    incoming.opacity = 0;
                }
            }
        }
    }
}
