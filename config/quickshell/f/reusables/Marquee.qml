import QtQuick
import "root:/design"

Item {
    id: root

    property string text: ""
    property color color: "white"
    property string family: Fonts.mono
    property int pixelSize: 11
    property int weight: Font.Normal
    property real letterSpacing: 0

    property int align: Text.AlignLeft

    property real speed: 26
    property int hold: 1400
    property real gap: 42
    property real fade: 16
    property bool running: true

    implicitHeight: metrics.height
    implicitWidth: metrics.width

    TextMetrics {
        id: metrics
        font.family: root.family
        font.pixelSize: root.pixelSize
        font.weight: root.weight
        font.letterSpacing: root.letterSpacing
        text: root.text
    }

    readonly property bool overflows: metrics.width > root.width + 0.5
    readonly property real lap: metrics.width + root.gap

    property real offset: 0

    property real leftFade: root.overflows && root.offset < -0.5 ? 1 : 0
    Behavior on leftFade { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

    Item {
        id: view
        width: root.width
        height: root.height
        clip: !root.overflows

        layer.enabled: root.overflows && root.width > 0
        layer.smooth: true
        layer.effect: ShaderEffect {
            fragmentShader: "root:/design/shaders/edgefade.frag.qsb"
            property real fadeL: root.width > 0 ? root.fade / root.width * root.leftFade : 0
            property real fadeR: root.width > 0 ? root.fade / root.width : 0
        }

        Text {
            id: first
            anchors.verticalCenter: parent.verticalCenter
            x: root.overflows ? root.offset
             : root.align === Text.AlignRight ? root.width - metrics.width
             : root.align === Text.AlignHCenter ? (root.width - metrics.width) / 2
             : 0
            text: root.text
            textFormat: Text.PlainText
            color: root.color
            font.family: root.family
            font.pixelSize: root.pixelSize
            font.weight: root.weight
            font.letterSpacing: root.letterSpacing
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.overflows
            x: root.offset + root.lap
            text: root.text
            textFormat: Text.PlainText
            color: root.color
            font.family: root.family
            font.pixelSize: root.pixelSize
            font.weight: root.weight
            font.letterSpacing: root.letterSpacing
        }
    }

    SequentialAnimation {
        id: scroll
        running: root.overflows && root.visible && root.running
        loops: Animation.Infinite
        onStopped: root.offset = 0

        PauseAnimation { duration: root.hold }
        NumberAnimation {
            target: root; property: "offset"
            from: 0; to: -root.lap
            duration: Math.max(1, root.lap / root.speed * 1000)
            easing.type: Easing.InOutSine
            easing.amplitude: 1
        }
        PropertyAction { target: root; property: "offset"; value: 0 }
    }

    onTextChanged: {
        root.offset = 0;
        if (scroll.running)
            scroll.restart();
    }

    onOverflowsChanged: if (!root.overflows) root.offset = 0
}
