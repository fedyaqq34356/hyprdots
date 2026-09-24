import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: opt

    property string name: ""
    property string label: opt.name
    property var valueLabel: (v) => v
    property var spec: null
    property var value: null

    signal commit(var v)

    implicitHeight: 28
    height: implicitHeight

    Text {
        id: optName
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: opt.label
        color: Colors.fgDim
        opacity: 0.75
        width: Math.max(60, opt.width - 170)
        elide: Text.ElideRight
        font.family: Fonts.display
        font.pixelSize: 11
    }

    Rectangle {
        visible: opt.spec && opt.spec.type === "bool"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 38
        height: 20
        radius: 10
        antialiasing: true
        color: opt.value
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.85)
            : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g, Colors.fgDim.b, 0.18)
        Behavior on color { ColorAnimation { duration: Motion.fast } }

        Rectangle {
            width: 14
            height: 14
            radius: 7
            antialiasing: true
            anchors.verticalCenter: parent.verticalCenter
            x: opt.value ? parent.width - width - 3 : 3
            color: opt.value ? Colors.accentText : Colors.fgDim
            Behavior on x {
                NumberAnimation {
                    duration: Motion.fast
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.snap
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                opt.commit(!opt.value);
                Sfx.tick();
            }
        }
    }

    Row {
        visible: opt.spec && opt.spec.type === "int"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 8

        Slider {
            id: dial
            anchors.verticalCenter: parent.verticalCenter
            width: 110
            value: {
                if (!opt.spec || opt.spec.type !== "int") return 0;
                const span = opt.spec.max - opt.spec.min;
                return span > 0 ? (opt.value - opt.spec.min) / span : 0;
            }
            onMoved: v => {
                const span = opt.spec.max - opt.spec.min;
                opt.commit(Math.round(opt.spec.min + v * span));
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 34
            horizontalAlignment: Text.AlignRight
            text: opt.value
            color: Colors.fg
            font.family: Fonts.mono
            font.pixelSize: 11
        }
    }

    Row {
        visible: opt.spec && opt.spec.type === "pick"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4

        Repeater {
            model: opt.spec && opt.spec.values ? opt.spec.values : []

            Rectangle {
                required property var modelData

                readonly property bool chosen: opt.value === modelData

                width: segText.implicitWidth + 16
                height: 22
                radius: Shape.detail
                antialiasing: true

                color: chosen
                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                              Colors.accent.b, 0.85)
                    : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                              Colors.fgDim.b, 0.14)
                Behavior on color { ColorAnimation { duration: Motion.fast } }

                Text {
                    id: segText
                    anchors.centerIn: parent
                    text: opt.valueLabel(modelData)
                    color: parent.chosen ? Colors.accentText : Colors.fgDim
                    font.family: Fonts.mono
                    font.pixelSize: 10
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        opt.commit(modelData);
                        Sfx.tick();
                    }
                }
            }
        }
    }

    Rectangle {
        visible: opt.spec && opt.spec.type === "text"
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 150
        height: 24
        radius: Shape.detail
        antialiasing: true
        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
        border.width: 1
        border.color: field.activeFocus
            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.6)
            : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)

        TextInput {
            id: field
            anchors.fill: parent
            anchors.leftMargin: 8
            anchors.rightMargin: 8
            verticalAlignment: TextInput.AlignVCenter
            color: Colors.fg
            font.family: Fonts.mono
            font.pixelSize: 11
            clip: true

            Binding on text {
                when: !field.activeFocus
                value: opt.value === undefined ? "" : String(opt.value)
                restoreMode: Binding.RestoreNone
            }

            onEditingFinished: opt.commit(text)
            Keys.onReturnPressed: {
                opt.commit(text);
                focus = false;
            }
        }
    }
}
