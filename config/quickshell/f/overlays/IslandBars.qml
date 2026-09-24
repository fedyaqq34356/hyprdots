import QtQuick
import QtQuick.Window
import "root:/design"
import "root:/services"

Item {
    id: bars

    property color tint: Colors.accent
    property int count: 5
    property bool live: true
    property int from: 1
    property int to: 9

    readonly property real barW: Math.max(2.5, bars.width / (bars.count * 1.6))
    readonly property real step: bars.count > 1
        ? (bars.width - bars.barW) / (bars.count - 1) : 0

    readonly property bool onScreen:
        bars.live && bars.visible && bars.Window.window !== null
        && bars.Window.window.visible

    property bool holding: false

    function sync() {
        const want = bars.onScreen;
        if (want === bars.holding)
            return;
        bars.holding = want;
        if (want) Cava.hold();
        else Cava.release();
    }

    onOnScreenChanged: bars.sync()
    Component.onCompleted: bars.sync()
    Component.onDestruction: if (bars.holding) Cava.release()

    property var lv: [0, 0, 0, 0, 0, 0, 0, 0]

    Connections {
        target: Cava
        enabled: bars.onScreen
        function onSmoothChanged() {
            const s = Cava.smooth;
            const n = bars.count;
            const out = new Array(n);
            for (let i = 0; i < n; i++) {
                const t = n > 1 ? i / (n - 1) : 0;
                const k = Math.round(bars.from + (bars.to - bars.from) * t);
                const shape = 0.62 + 0.38 * Math.sin(Math.PI * (0.15 + 0.7 * t));
                out[i] = Math.min(1, (s[k] || 0) * 1.35 * shape);
            }
            bars.lv = out;
        }
    }

    property real alive: Media.playing ? 1 : 0
    Behavior on alive { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }

    Repeater {
        model: bars.count

        Rectangle {
            required property int index

            readonly property real v: (bars.lv[index] || 0) * bars.alive

            x: Math.round(index * bars.step)
            width: bars.barW
            height: Math.max(bars.barW, bars.height * (0.14 + 0.86 * v))
            anchors.verticalCenter: parent.verticalCenter
            radius: width / 2
            antialiasing: true

            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.lighter(bars.tint, 1.18) }
                GradientStop { position: 1.0; color: Qt.darker(bars.tint, 1.12) }
            }
        }
    }
}
