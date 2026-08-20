import QtQuick

Item {
    id: root

    property string text: ""
    property color color: "white"
    property string family: "JetBrainsMono Nerd Font"
    property int pixelSize: 11
    property int weight: Font.Normal

    property real speed: 26
    property int hold: 1400

    clip: true
    implicitHeight: metrics.height

    TextMetrics {
        id: metrics
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        text: root.text
    }

    readonly property bool overflows: metrics.width > root.width
    readonly property real travel: Math.max(0, metrics.width - root.width)

    Text {
        id: label
        text: root.text
        color: root.color
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        anchors.verticalCenter: parent.verticalCenter
        x: 0
    }

    SequentialAnimation {
        id: scroll
        running: root.overflows && root.visible
        loops: Animation.Infinite

        PauseAnimation { duration: root.hold }
        NumberAnimation {
            target: label; property: "x"
            from: 0; to: -root.travel
            duration: Math.max(1, root.travel / root.speed * 1000)
            easing.type: Easing.InOutSine
        }
        PauseAnimation { duration: root.hold }
        NumberAnimation {
            target: label; property: "x"
            from: -root.travel; to: 0
            duration: Math.max(1, root.travel / root.speed * 1000)
            easing.type: Easing.InOutSine
        }
    }

    onTextChanged: {
        label.x = 0;
        if (scroll.running) scroll.restart();
    }

    onOverflowsChanged: if (!overflows) label.x = 0;
}
