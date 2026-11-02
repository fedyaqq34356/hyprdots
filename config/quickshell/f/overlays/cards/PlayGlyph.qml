import QtQuick
import QtQuick.Shapes as Vec
import "root:/design"

Item {
    id: pg

    property bool playing: false
    property int size: 30
    property color ink: Colors.fg

    width: pg.size
    height: pg.size

    MorphSpring {
        id: pm
        target: pg.playing ? 1 : 0
        response: 0.34
        damping: 1
        springBack: true
        Component.onCompleted: pm.land()
    }

    readonly property var playL:  [[0.24, 0.12], [0.56, 0.31], [0.56, 0.69], [0.24, 0.88]]
    readonly property var playR:  [[0.56, 0.31], [0.88, 0.50], [0.88, 0.50], [0.56, 0.69]]
    readonly property var pauseL: [[0.24, 0.14], [0.42, 0.14], [0.42, 0.86], [0.24, 0.86]]
    readonly property var pauseR: [[0.58, 0.14], [0.76, 0.14], [0.76, 0.86], [0.58, 0.86]]

    function quad(a, b) {
        const t = pm.value;
        const out = [];
        for (let i = 0; i <= 4; i++) {
            const j = i % 4;
            out.push(Qt.point(Motion.mix(a[j][0], b[j][0], t) * pg.size,
                              Motion.mix(a[j][1], b[j][1], t) * pg.size));
        }
        return out;
    }

    Vec.Shape {
        anchors.fill: parent
        preferredRendererType: Vec.Shape.CurveRenderer

        Vec.ShapePath {
            fillColor: pg.ink
            strokeColor: pg.ink
            strokeWidth: pg.size * 0.07
            joinStyle: Vec.ShapePath.RoundJoin
            PathPolyline { path: pg.quad(pg.playL, pg.pauseL) }
        }
        Vec.ShapePath {
            fillColor: pg.ink
            strokeColor: pg.ink
            strokeWidth: pg.size * 0.07
            joinStyle: Vec.ShapePath.RoundJoin
            PathPolyline { path: pg.quad(pg.playR, pg.pauseR) }
        }
    }
}
