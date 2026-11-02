import Quickshell
import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: face

    property string variant: "line"

    readonly property bool stretchy: true
    property real boxWidth: 0
    property real boxHeight: 0
    readonly property real minWidth: 240
    readonly property real minHeight: 48
    property real zoom: 1

    implicitWidth: face.boxWidth > 0 ? face.boxWidth : 820
    implicitHeight: face.boxHeight > 0 ? face.boxHeight : 104

    readonly property real lead: Math.max(12, face.height * 0.48)

    FontLoader {
        id: sans
        source: "file://" + Quickshell.env("HOME") + "/.local/share/fonts/onest/Onest.ttf"
    }

    readonly property font type: Qt.font({
        family: sans.status === FontLoader.Ready ? sans.name : "Onest",
        pixelSize: face.lead,
        weight: Font.Bold,
        letterSpacing: -0.6,
        variableAxes: { "wght": 700 }
    })

    readonly property bool live: Media.playing && Lyrics.current !== ""

    opacity: face.live ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow; easing.type: Easing.InOutCubic } }

    Component.onCompleted: Lyrics.watchers++
    Component.onDestruction: Lyrics.watchers--

    property bool flip: false

    Connections {
        target: Lyrics
        function onLineChanged() {
            const l = Lyrics.line;
            if (!l)
                return;
            const incoming = face.flip ? b : a;
            const outgoing = face.flip ? a : b;
            if (outgoing.on && outgoing.line === l)
                return;
            incoming.anim = false;
            incoming.shift = 10;
            incoming.line = l;
            incoming.anim = true;
            outgoing.shift = -22;
            face.flip = !face.flip;
        }
    }

    component Slot: Item {
        id: slot

        property bool on: false
        property bool anim: true
        property real shift: 10
        property var line: null

        readonly property bool singing: slot.on && Lyrics.line === slot.line

        width: face.width
        height: row.implicitHeight
        y: (face.height - slot.height) / 2 + (slot.on ? 0 : slot.shift)

        Behavior on y { enabled: slot.anim; NumberAnimation { duration: Motion.slow * 1.6; easing.type: Easing.OutCubic } }

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Math.round(face.lead * 0.3)
            scale: Math.min(1, face.width / Math.max(1, row.implicitWidth))

            Repeater {
                model: slot.line ? slot.line.words : []

                Item {
                    id: word

                    required property var modelData
                    required property int index

                    readonly property bool past: !slot.singing || word.index < Lyrics.word
                    readonly property bool now: slot.singing && word.index === Lyrics.word

                    property real fill: 0

                    function follow() {
                        if (word.now) {
                            const left = word.modelData.e - Lyrics.now();
                            const span = Math.max(0.05, word.modelData.e - word.modelData.t);
                            sweep.stop();
                            word.fill = Math.max(word.fill, Math.min(1, 1 - left / span));
                            sweep.duration = Math.max(0, left * 1000);
                            sweep.start();
                        } else if (word.past) {
                            sweep.stop();
                            settle.start();
                        } else {
                            sweep.stop();
                            settle.stop();
                            word.fill = 0;
                        }
                    }

                    onNowChanged: word.follow()
                    onPastChanged: word.follow()
                    Component.onCompleted: word.follow()

                    NumberAnimation {
                        id: sweep
                        target: word
                        property: "fill"
                        to: 1
                        paused: running && !Media.playing
                    }

                    NumberAnimation {
                        id: settle
                        target: word
                        property: "fill"
                        to: 1
                        duration: 140
                        easing.type: Easing.OutCubic
                    }

                    property real inT: slot.on ? 1 : 0
                    Behavior on inT {
                        SequentialAnimation {
                            PauseAnimation { duration: word.index * (slot.on ? 55 : 28) }
                            NumberAnimation {
                                duration: slot.on ? 760 : 520
                                easing.type: slot.on ? Easing.OutCubic : Easing.InCubic
                            }
                        }
                    }

                    property real lift: word.now ? 1 : 0
                    Behavior on lift { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }

                    implicitWidth: base.implicitWidth
                    implicitHeight: base.implicitHeight

                    opacity: word.inT
                    transform: Translate {
                        y: (1 - word.inT) * (slot.on ? 18 : -18) - 3 * word.lift
                    }

                    Text {
                        x: 0
                        y: 2
                        text: word.modelData.text
                        font: face.type
                        color: Colors.shadowTone
                        opacity: 0.38
                    }

                    Text {
                        id: base
                        text: word.modelData.text
                        font: face.type
                        color: "#ffffff"
                        opacity: 0.45
                    }

                    Item {
                        width: Math.round(base.implicitWidth * word.fill)
                        height: base.implicitHeight
                        clip: true

                        Text {
                            text: word.modelData.text
                            font: face.type
                            color: "#ffffff"
                            opacity: 0.96
                        }
                    }
                }
            }
        }
    }

    Slot { id: a; on: face.flip }
    Slot { id: b; on: !face.flip }
}
