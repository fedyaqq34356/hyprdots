import QtQuick

ShaderEffect {
    property var source
    property color c0: "#ffdf80"
    property color c1: "#f4717c"
    property color c2: "#e963c7"
    property point radius: Qt.point(0.6279, 1.0)
    property point center: Qt.point(0.5, 0.0)
    property real shift: 0
    fragmentShader: Qt.resolvedUrl("shaders/sunset.frag.qsb")
}
