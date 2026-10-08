import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: bar

    property color tint: Colors.accent
    property bool active: false

    readonly property string query: IslandBus.query
    readonly property int cursor: IslandBus.cursor
    readonly property string mode: IslandBus.mode

    readonly property int fontPx: 15
    readonly property real textX: 42

    ListModel { id: chars }

    onQueryChanged: bar.sync()
    Component.onCompleted: bar.sync()

    function sync() {
        const q = bar.query;
        const have = chars.count;
        let n = 0;
        while (n < have && n < q.length && chars.get(n).c === q.charAt(n))
            n++;
        if (have > n)
            chars.remove(n, have - n);
        for (let i = n; i < q.length; i++)
            chars.append({ c: q.charAt(i) });
        Qt.callLater(bar.follow);
    }

    function follow() {
        const over = line.contentWidth - line.width;
        line.contentX = line.originX + Math.max(0, over + 4);
    }

    Text {
        x: 17
        anchors.verticalCenter: parent.verticalCenter
        text: bar.mode === "run" ? "󰞷" : bar.mode === "calc" ? "󰃬"
            : bar.mode === "wall" ? "󰸉" : "󰍉"
        color: Qt.rgba(1, 1, 1, 0.5)
        font.family: Fonts.glyph
        font.pixelSize: 15
    }

    ListView {
        id: line

        x: bar.textX
        width: Math.max(40, side.x - bar.textX - 12)
        height: parent.height
        orientation: ListView.Horizontal
        interactive: false
        clip: true
        model: chars
        onWidthChanged: bar.follow()

        delegate: Item {
            id: ch
            required property string c

            width: ch.c === " " ? Math.round(bar.fontPx * 0.3) : glyphText.implicitWidth
            height: line.height

            Text {
                id: glyphText
                anchors.verticalCenter: parent.verticalCenter
                text: ch.c
                color: "white"
                font.family: Fonts.display
                font.pixelSize: bar.fontPx
            }
        }

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 260; easing.type: Easing.OutCubic }
        }

        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 200; easing.type: Easing.OutCubic }
        }

        displaced: Transition {
            NumberAnimation { property: "x"; duration: 260; easing.type: Easing.OutCubic }
        }
    }

    Text {
        x: bar.textX + 4
        anchors.verticalCenter: parent.verticalCenter
        text: bar.mode === "wall" ? "Search wallpapers" : "Search"
        color: Qt.rgba(1, 1, 1, 0.32)
        font.family: Fonts.display
        font.pixelSize: bar.fontPx
        opacity: bar.query === "" ? 1 : 0
        visible: opacity > 0.01
        Behavior on opacity { NumberAnimation { duration: 140 } }
    }

    readonly property real caretAt: {
        line.count;
        line.contentX;
        if (bar.cursor <= 0)
            return 0;
        const it = line.itemAtIndex(Math.min(bar.cursor, line.count) - 1);
        return it ? it.x + it.width - line.contentX : 0;
    }

    property bool typing: false
    Timer { id: rest; interval: 700; onTriggered: bar.typing = false }

    Connections {
        target: IslandBus
        function onKeyed(dir) {
            bar.typing = true;
            rest.restart();
        }
    }

    Rectangle {
        id: caret
        x: bar.textX + Math.min(bar.caretAt, line.width) + 1
        anchors.verticalCenter: parent.verticalCenter
        width: 1.5
        height: 18
        radius: 1
        color: bar.tint
        Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }

        property real blink: 1
        opacity: bar.active ? (bar.typing ? 1 : caret.blink) : 0

        SequentialAnimation on blink {
            running: bar.active && !bar.typing
            loops: Animation.Infinite
            onStopped: caret.blink = 1
            NumberAnimation { to: 0.2; duration: 600; easing.type: Easing.InOutSine }
            NumberAnimation { to: 1; duration: 600; easing.type: Easing.InOutSine }
        }
    }

    readonly property string sideText: {
        if (bar.mode === "calc")
            return IslandBus.calc !== "" ? "= " + IslandBus.calc : "";
        if (bar.mode === "run")
            return "Run";
        return IslandBus.hint;
    }

    Text {
        id: side
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.verticalCenter: parent.verticalCenter
        text: bar.sideText
        color: Qt.rgba(1, 1, 1, 0.42)
        font.family: Fonts.display
        font.pixelSize: 12
        opacity: bar.sideText !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
    }
}
