import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: wave

    property real level: 0
    property string channel: "sink"
    property bool muted: false
    property int way: 0
    property color tint: Colors.accent
    property real size: 20
    property bool live: false

    implicitWidth: wave.size
    implicitHeight: wave.size

    readonly property bool mic: wave.channel === "source"

    readonly property int step:
        wave.level < 0.01 ? 0 : (wave.level < 0.34 ? 1
                                : (wave.level < 0.67 ? 2 : 3))

    readonly property string glyph: {
        if (wave.mic)
            return wave.muted ? "󰍭" : "󰍬";
        if (wave.channel === "light")
            return wave.step <= 1 ? "󰃞" : (wave.step === 2 ? "󰃟" : "󰃠");
        if (wave.muted)
            return "󰝟";
        switch (wave.step) {
        case 0:  return "󰸈";
        case 1:  return "󰕿";
        case 2:  return "󰖀";
        }
        return "󰕾";
    }

    readonly property bool listening: wave.mic && wave.live && !wave.muted

    onListeningChanged: {
        if (wave.listening)
            MicLevel.hold();
        else
            MicLevel.release();
    }

    Component.onCompleted: if (wave.listening) MicLevel.hold()
    Component.onDestruction: if (wave.listening) MicLevel.release()

    Rectangle {
        id: breath

        anchors.centerIn: parent
        width: wave.size * (1.02 + 0.5 * MicLevel.level)
        height: width
        radius: height / 2
        antialiasing: true
        color: "transparent"
        border.width: 1.5
        border.color: Colors.alpha(wave.tint, 0.20 + 0.55 * MicLevel.level)
        opacity: 0
        visible: false

        Behavior on opacity {
            NumberAnimation { duration: Motion.isleRevealMs }
        }
    }

    Repeater {
        model: 0

        Rectangle {
            id: ring

            required property int index

            anchors.centerIn: parent
            width: wave.size
            height: wave.size
            radius: height / 2
            antialiasing: true
            color: "transparent"
            border.width: 1.5
            border.color: wave.tint
            opacity: 0
            visible: opacity > 0.01
            scale: 0.55

            transform: Translate { id: drift; y: 0 }

            SequentialAnimation {
                id: pulse

                PauseAnimation { duration: ring.index * 110 }
                ParallelAnimation {
                    NumberAnimation {
                        target: ring; property: "scale"
                        from: 0.55; to: 1.45
                        duration: 520
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: drift; property: "y"
                        from: 0; to: -wave.way * wave.size * 0.42
                        duration: 520
                        easing.type: Easing.OutCubic
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: ring; property: "opacity"
                            to: 0.55 - ring.index * 0.2
                            duration: 90
                        }
                        NumberAnimation {
                            target: ring; property: "opacity"
                            to: 0
                            duration: 430
                            easing.type: Easing.InCubic
                        }
                    }
                }
            }

            Connections {
                target: wave
                function onRipple() {
                    if (wave.way !== 0)
                        pulse.restart();
                }
            }
        }
    }

    signal ripple()

    Item {
        id: face

        anchors.centerIn: parent
        width: wave.size
        height: wave.size

        Text {
            id: sign

            anchors.centerIn: parent
            text: wave.glyph
            color: wave.tint
            font.family: Fonts.glyph
            font.pixelSize: Math.max(11, Math.round(wave.size * 0.72))

            Behavior on color { ColorAnimation { duration: Motion.base } }
        }

        transform: Translate { id: nudge; y: 0 }

        SequentialAnimation {
            id: shove
            NumberAnimation {
                target: nudge; property: "y"
                to: -wave.way * 2.4
                duration: 90
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                target: nudge; property: "y"
                to: 0
                duration: 260
                easing.type: Easing.OutBack
                easing.overshoot: 2.0
            }
        }

        Connections {
            target: wave
            function onRipple() {
                if (wave.way !== 0)
                    shove.restart();
            }
        }
    }
}
