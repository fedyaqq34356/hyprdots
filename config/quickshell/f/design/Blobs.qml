import QtQuick
import QtQuick.Effects
import "root:/design"

Item {
    id: field

    property Item host: null

    property real fuse: 6
    property real corner: 12

    property color fillColor: Colors.bg
    property real fillAlpha: 0.8
    property color hoverColor: Colors.bg
    property real hoverAlpha: 0.92
    property color strokeColor: Colors.outline
    property real strokeAlpha: 0.32
    property real stroke: 1

    property Item hoverItem: null
    property real hoverMix: 1

    property bool shadow: true

    readonly property real pad: Math.max(8, fuse * 2 + 6)

    readonly property alias count: shader.count

    anchors.fill: host
    anchors.margins: -pad
    visible: host !== null && count > 0

    onHostChanged: field.requestSync()
    onHoverItemChanged: field.requestSync()
    onFuseChanged: field.requestSync()

    Connections {
        target: field.host
        function onChildrenChanged() { field.requestSync(); }
        function onWidthChanged() { field.requestSync(); }
        function onHeightChanged() { field.requestSync(); }
    }

    property bool pending: false

    function requestSync() {
        if (field.pending)
            return;
        field.pending = true;
        Qt.callLater(field.applySync);
    }

    function applySync() {
        field.pending = false;

        const h = field.host;
        if (!h) {
            shader.count = 0;
            return;
        }

        const kids = h.children;
        const p = field.pad;
        let n = 0;
        let hover = -1;

        for (let i = 0; i < kids.length && n < 12; i++) {
            const it = kids[i];
            if (!it || it.isBlob !== true || !it.visible)
                continue;
            if (it.width <= 0 || it.height <= 0)
                continue;

            const sc = it.scale === undefined ? 1 : it.scale;
            const oy = it.blobOffsetY === undefined ? 0 : it.blobOffsetY;

            field.setRect(n,
                          it.x + it.width / 2 + p,
                          it.y + it.height / 2 + oy + p,
                          it.width * sc / 2,
                          it.height * sc / 2);

            if (it === field.hoverItem)
                hover = n;
            n++;
        }

        shader.count = n;
        shader.hoverIndex = hover;
    }

    function setRect(i, cx, cy, hw, hh) {
        const v = Qt.vector4d(cx, cy, hw, hh);
        switch (i) {
        case 0:  shader.r0  = v; break;
        case 1:  shader.r1  = v; break;
        case 2:  shader.r2  = v; break;
        case 3:  shader.r3  = v; break;
        case 4:  shader.r4  = v; break;
        case 5:  shader.r5  = v; break;
        case 6:  shader.r6  = v; break;
        case 7:  shader.r7  = v; break;
        case 8:  shader.r8  = v; break;
        case 9:  shader.r9  = v; break;
        case 10: shader.r10 = v; break;
        case 11: shader.r11 = v; break;
        }
    }

    ShaderEffect {
        id: shader

        anchors.fill: parent
        fragmentShader: "root:/design/shaders/blob.frag.qsb"
        blending: true

        property vector2d size: Qt.vector2d(width, height)

        property real fuse: field.fuse
        property real corner: field.corner
        property real stroke: field.stroke
        property real hoverMix: field.hoverItem ? field.hoverMix : 0

        property color fillColor: field.fillColor
        property color hoverColor: field.hoverColor
        property color strokeColor: field.strokeColor
        property real fillAlpha: field.fillAlpha
        property real hoverAlpha: field.hoverAlpha
        property real strokeAlpha: field.strokeAlpha

        property int count: 0
        property int hoverIndex: -1

        property vector4d r0
        property vector4d r1
        property vector4d r2
        property vector4d r3
        property vector4d r4
        property vector4d r5
        property vector4d r6
        property vector4d r7
        property vector4d r8
        property vector4d r9
        property vector4d r10
        property vector4d r11

        Behavior on hoverMix {
            NumberAnimation { duration: Motion.base; easing.type: Easing.OutCubic }
        }
        Behavior on fillColor { ColorAnimation { duration: Motion.base } }
        Behavior on strokeColor { ColorAnimation { duration: Motion.base } }

        layer.enabled: field.shadow
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: Qt.rgba(0, 0, 0, 0.32)
            shadowBlur: 0.55
            shadowVerticalOffset: 3
        }
    }
}
