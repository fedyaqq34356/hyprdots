import Quickshell
import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: face

    property string variant: "list"

    readonly property int limit: 6
    readonly property real lineW: 320

    implicitWidth: face.lineW
    implicitHeight: head.height + 10 + list.contentHeight

    opacity: rows.count > 0 ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    ListModel { id: rows }

    Connections {
        target: Notes
        function onItemsChanged() { face.sync(); }
    }
    Component.onCompleted: face.sync()

    function sync() {
        const want = Notes.open.slice(-face.limit).reverse();
        const ids = want.map(n => n.id);

        for (let i = 0; i < rows.count; i++) {
            const r = rows.get(i);
            if (!r.leaving && ids.indexOf(r.nid) < 0)
                rows.setProperty(i, "leaving", true);
        }

        const have = [];
        for (let i = 0; i < rows.count; i++)
            have.push(rows.get(i).nid);

        let at = 0;
        for (const n of want) {
            if (have.indexOf(n.id) < 0)
                rows.insert(at, { nid: n.id, text: n.text, leaving: false });
            at++;
        }
    }

    function drop(nid) {
        for (let i = 0; i < rows.count; i++) {
            if (rows.get(i).nid === nid) {
                rows.remove(i);
                return;
            }
        }
    }

    Row {
        id: head
        spacing: 8

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰎚"
            color: Colors.accent
            font.family: Fonts.glyph
            font.pixelSize: 15
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: I18n.t("desk.notes")
            color: Qt.rgba(1, 1, 1, 0.62)
            font.family: Fonts.display
            font.pixelSize: 13
            font.weight: Font.DemiBold
            font.letterSpacing: 0.4
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Notes.count > 0 ? String(Notes.count) : ""
            color: Qt.rgba(1, 1, 1, 0.38)
            font.family: Fonts.display
            font.pixelSize: 13
            font.features: { "tnum": 1 }
        }
    }

    ListView {
        id: list

        y: head.height + 10
        width: face.lineW
        height: contentHeight
        interactive: false
        model: rows
        spacing: 2

        delegate: Item {
            id: row

            required property int index
            required property int nid
            required property string text
            required property bool leaving

            property real strike: 0
            property real collapse: 0

            width: list.width
            height: (line.implicitHeight + 8) * (1 - row.collapse)
            clip: row.collapse > 0

            onLeavingChanged: if (row.leaving) out.start()

            SequentialAnimation {
                id: out
                NumberAnimation { target: row; property: "strike"; to: 1; duration: 520; easing.type: Easing.OutCubic }
                PauseAnimation { duration: 380 }
                ParallelAnimation {
                    NumberAnimation { target: row; property: "opacity"; to: 0; duration: 520; easing.type: Easing.InOutCubic }
                    NumberAnimation { target: row; property: "collapse"; to: 1; duration: 620; easing.type: Easing.InOutCubic }
                }
                ScriptAction { script: face.drop(row.nid) }
            }

            Rectangle {
                id: dot
                x: 3
                y: 4 + line.font.pixelSize * 0.62 - height / 2
                width: 6
                height: 6
                radius: 3
                color: Colors.accent
                opacity: 0.85 - 0.5 * row.strike
            }

            Text {
                x: line.x + 1
                y: line.y + 1
                width: line.width
                text: line.text
                wrapMode: line.wrapMode
                maximumLineCount: line.maximumLineCount
                elide: line.elide
                color: Qt.rgba(0, 0, 0, 0.35)
                font: line.font
            }

            Text {
                id: line
                x: 20
                y: 4
                width: parent.width - 20
                text: row.text
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
                color: Qt.rgba(1, 1, 1, 0.94 - 0.4 * row.strike)
                font.family: Fonts.display
                font.pixelSize: 16
                font.weight: Font.Medium
            }

            Rectangle {
                x: line.x - 2
                y: line.y + line.font.pixelSize * 0.62
                width: (Math.min(line.contentWidth, line.width) + 4) * row.strike
                height: 1.6
                radius: 0.8
                color: "white"
                opacity: 0.9
                visible: row.strike > 0
            }
        }

        add: Transition {
            ParallelAnimation {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 560; easing.type: Easing.OutCubic }
                NumberAnimation { property: "x"; from: 16; to: 0; duration: 640; easing.type: Easing.OutCubic }
            }
        }

        displaced: Transition {
            NumberAnimation { property: "y"; duration: 460; easing.type: Easing.OutCubic }
        }
    }
}
