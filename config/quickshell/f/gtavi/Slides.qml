import QtQuick

Item {
    id: deck

    property var sources: ["assets/bg/01.jpg", "assets/bg/02.jpg", "assets/bg/03.jpg",
                           "assets/bg/04.jpg", "assets/bg/05.jpg"]
    property int slideMs: 9000
    property bool running: true
    property real u: 1
    property int index: 0
    property bool front: true

    clip: true

    readonly property var easeInOut: [0.645, 0.045, 0.355, 1, 1, 1]

    component Slide: Image {
        id: sl
        property real life: 0
        property real reveal: 0
        anchors.fill: parent
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        smooth: true
        cache: false
        sourceSize.width: Math.min(2560, deck.width * 1.15)
        scale: 1.10 - 0.04 * reveal + 0.06 * life
        transform: Translate { x: -18 * deck.u * sl.life }

        layer.enabled: reveal < 1
        layer.effect: ShaderEffect {
            property real progress: sl.reveal
            property real softness: 0.28
            property real slant: 0.35
            fragmentShader: Qt.resolvedUrl("shaders/wipe.frag.qsb")
        }

        NumberAnimation on life { id: drift; running: false; from: 0; to: 1
                                  duration: deck.slideMs + 2200; easing.type: Easing.Linear }
        NumberAnimation { id: show; target: sl; property: "reveal"; from: 0; to: 1; duration: 2200
                          easing.type: Easing.BezierSpline; easing.bezierCurve: deck.easeInOut }

        function play(src, instant) {
            source = Qt.resolvedUrl(src);
            life = 0;
            drift.restart();
            if (instant) {
                show.stop();
                reveal = 1;
            } else {
                show.restart();
            }
        }
    }

    Slide { id: a; z: deck.front ? 1 : 0 }
    Slide { id: b; z: deck.front ? 0 : 1 }

    function start(at, instant) {
        index = at % sources.length;
        front = true;
        a.play(sources[index], instant);
    }

    Timer {
        interval: deck.slideMs
        repeat: true
        running: deck.running && deck.sources.length > 1
        onTriggered: {
            deck.index = (deck.index + 1) % deck.sources.length;
            deck.front = !deck.front;
            (deck.front ? a : b).play(deck.sources[deck.index], false);
        }
    }
}
