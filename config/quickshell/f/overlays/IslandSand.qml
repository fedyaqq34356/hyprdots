import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/services"

Item {
    id: sand

    property real level: 0
    property bool hot: false
    property color tint: Colors.accentAlt
    property bool live: true

    property real heat: sand.hot ? 1 : 0
    Behavior on heat { NumberAnimation { duration: 900; easing.type: Easing.InOutSine } }

    property real shown: sand.level
    Behavior on shown { NumberAnimation { duration: 1200; easing.type: Easing.InOutSine } }

    readonly property real surfaceY: sand.height * (1 - Math.max(0, Math.min(1, sand.shown)))

    Rectangle {
        x: 0
        y: sand.surfaceY
        width: sand.width
        height: sand.height - sand.surfaceY
        gradient: Gradient {
            GradientStop { position: 0.0; color: Colors.alpha(Qt.lighter(sand.tint, 1.2), 0.16 + 0.22 * sand.heat) }
            GradientStop { position: 1.0; color: Colors.alpha(sand.tint, 0.04 + 0.10 * sand.heat) }
        }
    }

    Rectangle {
        x: 0
        y: sand.surfaceY - 0.5
        width: sand.width
        height: 1.2
        visible: sand.shown > 0.01
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Colors.alpha(Qt.lighter(sand.tint, 1.5), 0.55 + 0.4 * sand.heat) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    Repeater {
        model: 12

        Rectangle {
            id: grain

            required property int index

            readonly property real seed: (grain.index * 0.6180339) % 1
            width: 1.6 + 1.2 * ((grain.index * 0.37) % 1)
            height: width
            radius: width / 2
            color: Qt.lighter(sand.tint, 1.4 + 0.3 * sand.heat)
            x: sand.width * (0.06 + 0.88 * ((grain.seed + grain.drift) % 1))

            property real fall: 0
            property real drift: 0
            y: -4 + (sand.surfaceY + 4) * grain.fall
            opacity: (grain.fall < 0.15 ? grain.fall / 0.15 : grain.fall > 0.85 ? (1 - grain.fall) / 0.15 : 1)
                     * (0.45 + 0.5 * sand.heat)
            visible: sand.live && sand.surfaceY > 3

            SequentialAnimation {
                running: grain.visible
                loops: Animation.Infinite
                PauseAnimation { duration: grain.index * 270 }
                ScriptAction { script: grain.drift = Math.random() * 0.3 }
                NumberAnimation {
                    target: grain; property: "fall"
                    from: 0; to: 1
                    duration: 2600 + 900 * grain.seed - 900 * sand.heat
                    easing.type: Easing.InQuad
                }
            }
        }
    }
}
