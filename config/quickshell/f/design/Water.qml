import QtQuick

ShaderEffect {
    id: water

    fragmentShader: "root:/design/shaders/water.frag.qsb"
    blending: true

    property vector2d size: Qt.vector2d(water.width, water.height)
    property real axis: 0
    property real level: 0

    property real phase1: 0
    property real amp1: 1.3
    property real waves1: 1.2
    property real phase2: 0
    property real amp2: 0
    property real waves2: 2.0

    property color nearColor: "white"
    property real nearAlpha: 0.3
    property color farColor: "white"
    property real farAlpha: 0.2
    property color crestColor: "white"
    property real crestAlpha: 0.6
    property real crestWidth: 1.3
}
