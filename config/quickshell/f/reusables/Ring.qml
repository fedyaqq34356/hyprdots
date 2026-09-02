import QtQuick
import "root:/design"

Item {
    id: gauge

    property real value: 0
    property string label: ""
    property string caption: ""

    property real thickness: 6
    property int animationDuration: 600

    readonly property bool available: value >= 0

    implicitWidth: 96
    implicitHeight: 96

    property real shown: 0
    onValueChanged: shown = available ? value : 0

    Behavior on shown {
        NumberAnimation {
            duration: gauge.animationDuration
            easing.type: Easing.OutCubic
        }
    }

    readonly property color arcColor: {
        const v = gauge.shown;
        if (v < 0.5)
            return Qt.tint(Colors.accent, Qt.rgba(Colors.warn.r, Colors.warn.g,
                                                  Colors.warn.b, v * 0.6));
        if (v < 0.8)
            return Qt.tint(Colors.warn, Qt.rgba(Colors.bad.r, Colors.bad.g,
                                                Colors.bad.b, (v - 0.5) * 1.6));
        return Colors.bad;
    }

    onShownChanged: gauge.maybePaint()

    property real paintedAt: -1

    function maybePaint() {
        const span = Math.PI * Math.max(width, height);
        if (gauge.paintedAt >= 0
            && Math.abs(gauge.shown - gauge.paintedAt) * span < 0.5)
            return;
        gauge.paintedAt = gauge.shown;
        canvas.requestPaint();
    }

    onArcColorChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        renderStrategy: Canvas.Cooperative

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();

            const cx = width / 2;
            const cy = height / 2;
            const r = Math.min(cx, cy) - gauge.thickness;
            const start = -Math.PI / 2;

            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.strokeStyle = Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                      Colors.fgDim.b, 0.14);
            ctx.lineWidth = gauge.thickness;
            ctx.stroke();

            if (!gauge.available || gauge.shown <= 0.001)
                return;

            ctx.beginPath();
            ctx.arc(cx, cy, r, start, start + Math.PI * 2 * gauge.shown);
            ctx.strokeStyle = gauge.arcColor;
            ctx.lineWidth = gauge.thickness;
            ctx.lineCap = "round";
            ctx.stroke();

            const angle = start + Math.PI * 2 * gauge.shown;
            ctx.beginPath();
            ctx.arc(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r,
                    gauge.thickness * 0.62, 0, Math.PI * 2);
            ctx.fillStyle = gauge.arcColor;
            ctx.fill();
        }
    }

    Column {
        anchors.centerIn: parent
        spacing: 1

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: gauge.available ? gauge.label : "n/a"
            color: gauge.available ? Colors.fg
                                   : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                             Colors.fgDim.b, 0.4)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: gauge.available ? 17 : 11
            font.weight: Font.DemiBold
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: gauge.caption
            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.6)
            font.family: "JetBrainsMono Nerd Font"
            font.pixelSize: 8
            font.weight: Font.Medium
        }
    }
}
