import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import Quickshell.Wayland

Scope {
    id: root

    property bool shown: false
    property var files: []
    property string current: ""
    property string filter: "All"

    property var tones: ({})
    property var history: []

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/wallpaper-thumbs"
    readonly property string historyPath: Quickshell.env("HOME") + "/.cache/wallpaper-history"

    readonly property var filters: [
        { name: "All",        hex: "" },
        { name: "Recent",     hex: "" },
        { name: "Red",        hex: "#ff5555" },
        { name: "Orange",     hex: "#ffa64d" },
        { name: "Yellow",     hex: "#ffd93b" },
        { name: "Green",      hex: "#4fd35f" },
        { name: "Blue",       hex: "#4d9cff" },
        { name: "Purple",     hex: "#a06cff" },
        { name: "Pink",       hex: "#ff6cc0" },
        { name: "Mono",       hex: "#9a9a9a" }
    ]

    function toggle() {
        if (shown) {
            close();
        } else {
            lister.running = true;
            currentReader.running = true;
            shown = true;
        }
    }

    function close() {
        root.shown = false;
    }

    onShownChanged: {
        if (shown) {
            search.text = "";
            root.filter = "All";
            grid.currentIndex = 0;
            grid.positionViewAtBeginning();
            search.forceActiveFocus();
        }
    }

    function baseName(p) {
        return p.substring(p.lastIndexOf("/") + 1);
    }

    function bucket(path) {
        const hex = root.tones[root.baseName(path)];
        if (!hex)
            return "";

        const c = Qt.color(hex);
        if (c.hslSaturation < 0.14 || c.hslLightness < 0.06 || c.hslLightness > 0.94)
            return "Mono";

        const h = c.hslHue * 360;
        if (h < 16 || h >= 345) return "Red";
        if (h < 45)  return "Orange";
        if (h < 70)  return "Yellow";
        if (h < 165) return "Green";
        if (h < 255) return "Blue";
        if (h < 292) return "Purple";
        return "Pink";
    }

    Process {
        id: lister
        command: ["sh", "-c",
            "find '" + root.dir + "' -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) | sort"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.files = this.text.split("\n").filter(l => l.trim() !== "");
                thumber.running = true;
            }
        }
    }

    Process {
        id: currentReader
        command: ["cat", Quickshell.env("HOME") + "/.config/hypr/current-wallpaper"]
        stdout: StdioCollector {
            onStreamFinished: root.current = this.text.trim()
        }
    }

    Process {
        id: thumber
        command: ["sh", "-c",
            "mkdir -p '" + root.thumbDir + "'; " +
            "find '" + root.dir + "' -maxdepth 1 -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) " +
            "| while IFS= read -r wp; do t='" + root.thumbDir + "'/$(basename \"$wp\"); " +
            "[ -f \"$t\" ] && continue; " +
            "nice -n 19 ffmpeg -i \"$wp\" -vf " +
            "'scale=600:400:force_original_aspect_ratio=increase,crop=600:400' " +
            "-vframes 1 \"$t\" -y -loglevel quiet </dev/null 2>/dev/null; done; " +
            "'" + Quickshell.env("HOME") + "/.config/hypr/scripts/wallpaper-index.sh' '" + root.dir + "'"]
        onExited: toneFile.reload()
    }

    FileView {
        id: toneFile
        path: root.thumbDir + "/colors.tsv"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const map = {};
            for (const line of toneFile.text().split("\n")) {
                const parts = line.split("\t");
                if (parts.length === 2 && parts[0] !== "")
                    map[parts[0]] = parts[1].trim();
            }
            root.tones = map;
        }
    }

    FileView {
        id: historyFile
        path: root.historyPath
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const seen = {};
            const out = [];
            const lines = historyFile.text().split("\n");
            for (let i = lines.length - 1; i >= 0; i--) {
                const p = lines[i].trim();
                if (p === "" || seen[p])
                    continue;
                seen[p] = true;
                out.push(p);
            }
            root.history = out;
        }
    }

    Process { id: setter }
    Process { id: historyWriter }

    function apply(path) {
        if (!path)
            return;
        root.close();
        root.current = path;

        setter.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/set-wallpaper.sh", path];
        setter.running = true;

        historyWriter.command = ["sh", "-c",
            "printf '%s\\n' \"$1\" >> '" + root.historyPath + "'; " +
            "tail -n 60 '" + root.historyPath + "' > '" + root.historyPath + ".tmp' && " +
            "mv '" + root.historyPath + ".tmp' '" + root.historyPath + "'",
            "sh", path];
        historyWriter.running = true;
    }

    function shuffle() {
        const pool = root.results.length > 0 ? root.results : root.files;
        if (pool.length === 0)
            return;
        apply(pool[Math.floor(Math.random() * pool.length)]);
    }

    function cycleFilter(step) {
        const names = root.filters.map(f => f.name);
        const i = names.indexOf(root.filter);
        root.filter = names[(i + step + names.length) % names.length];
    }

    readonly property var results: {
        const q = search.text.toLowerCase().trim();
        let out = root.files;

        if (root.filter === "Recent") {
            const alive = {};
            for (const f of root.files) alive[f] = true;
            out = root.history.filter(p => alive[p]);
        } else if (root.filter !== "All") {
            out = out.filter(f => root.bucket(f) === root.filter);
        }

        if (q !== "")
            out = out.filter(f => root.baseName(f).toLowerCase().includes(q));

        return out;
    }

    onResultsChanged: grid.currentIndex = 0

    readonly property string focused:
        grid.currentIndex >= 0 && grid.currentIndex < results.length
            ? results[grid.currentIndex] : ""

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-wallpapers"
        id: win
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.5 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: Math.min(1180, parent.width - 80)
            height: Math.min(760, parent.height - 80)
            radius: 26
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96)
            border.width: 1
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                  Colors.accent.b, 0.30)
            clip: true

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 190 } }
            Behavior on scale {
                NumberAnimation { duration: 300; easing.type: Easing.OutBack }
            }

            Item {
                anchors.fill: parent
                opacity: 0.22

                Image {
                    id: preview
                    anchors.fill: parent
                    source: root.focused !== ""
                        ? "file://" + root.thumbDir + "/" + root.baseName(root.focused)
                        : ""
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    visible: false
                    onStatusChanged: {
                        if (status === Image.Error && root.focused !== "")
                            source = "file://" + root.focused;
                    }
                }

                MultiEffect {
                    anchors.fill: parent
                    source: preview
                    blurEnabled: true
                    blur: 1.0
                    blurMax: 64
                    saturation: 0.2
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.80)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.97)
                    }
                }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                Rectangle {
                    width: parent.width
                    height: 46
                    radius: 14
                    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
                    border.width: 1
                    border.color: search.activeFocus
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.55)
                        : "transparent"
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 12
                        spacing: 12

                        Text {
                            text: "󰸉"
                            color: Colors.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: search
                            width: parent.width - 200
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            clip: true
                            selectByMouse: true
                            selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                    Colors.accent.b, 0.35)

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: root.results.length + " обоев…"
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.5)
                                font: search.font
                            }

                            Keys.onEscapePressed: root.close()
                            Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                            Keys.onRightPressed: grid.moveCurrentIndexRight()
                            Keys.onUpPressed: grid.moveCurrentIndexUp()
                            Keys.onDownPressed: grid.moveCurrentIndexDown()
                            Keys.onTabPressed: root.cycleFilter(1)
                            Keys.onBacktabPressed: root.cycleFilter(-1)
                            Keys.onReturnPressed: root.apply(root.focused)
                            Keys.onEnterPressed: root.apply(root.focused)
                        }

                        Rectangle {
                            width: 92
                            height: 28
                            radius: 9
                            anchors.verticalCenter: parent.verticalCenter
                            color: shuffleArea.containsMouse
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.22)
                                : "transparent"
                            border.width: 1
                            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                  Colors.accent.b, 0.35)
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰑓 random"
                                color: Colors.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: shuffleArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.shuffle()
                            }
                        }
                    }
                }

                Row {
                    id: filterRow
                    height: 34
                    spacing: 8

                    Repeater {
                        model: root.filters

                        Rectangle {
                            id: pill
                            required property var modelData

                            readonly property bool active: root.filter === modelData.name
                            readonly property bool tinted: modelData.hex !== ""

                            width: tinted ? 34 : label.implicitWidth + 24
                            height: 34
                            radius: 11
                            anchors.verticalCenter: parent.verticalCenter

                            color: active
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.24)
                                : pillArea.containsMouse
                                    ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
                                    : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.30)
                            border.width: 1
                            border.color: active
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.6)
                                : "transparent"

                            scale: active ? 1.05 : (pillArea.containsMouse ? 1.03 : 1.0)
                            Behavior on scale {
                                NumberAnimation { duration: 170; easing.type: Easing.OutBack }
                            }
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Rectangle {
                                visible: pill.tinted
                                anchors.centerIn: parent
                                width: 15
                                height: 15
                                radius: 7.5
                                color: pill.modelData.hex
                                border.width: 1
                                border.color: Qt.rgba(0, 0, 0, 0.35)
                            }

                            Text {
                                id: label
                                visible: !pill.tinted
                                anchors.centerIn: parent
                                text: pill.modelData.name
                                color: pill.active ? Colors.accent : Colors.fgDim
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                            }

                            MouseArea {
                                id: pillArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.filter = pill.modelData.name;
                                    search.forceActiveFocus();
                                }
                            }
                        }
                    }
                }

                GridView {
                    id: grid
                    width: parent.width
                    height: parent.height - 136
                    clip: true
                    model: root.results
                    cellWidth: Math.floor(width / 4)
                    cellHeight: Math.floor(cellWidth * 0.64)
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: 1200
                    highlightMoveDuration: 160

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index

                        width: grid.cellWidth
                        height: grid.cellHeight

                        readonly property bool isCurrent: modelData === root.current
                        readonly property bool isFocused: index === grid.currentIndex

                        ClippingRectangle {
                            id: tile
                            anchors.fill: parent
                            anchors.margins: 7
                            radius: 16
                            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                           Colors.bgAlt.b, 0.35)
                            border.width: cell.isCurrent || cell.isFocused ? 2 : 1
                            border.color: cell.isCurrent
                                ? Colors.accent
                                : (cell.isFocused
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                              Colors.accent.b, 0.55)
                                    : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                              Colors.outline.b, 0.25))

                            scale: tileArea.containsMouse ? 1.05 : (cell.isFocused ? 1.02 : 1.0)
                            Behavior on scale {
                                NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                            }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 520
                                source: "file://" + root.thumbDir + "/"
                                        + root.baseName(cell.modelData)
                                onStatusChanged: {
                                    if (status === Image.Error)
                                        source = "file://" + cell.modelData;
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 30
                                opacity: tileArea.containsMouse || cell.isFocused ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 160 } }

                                gradient: Gradient {
                                    GradientStop {
                                        position: 0.0
                                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.0)
                                    }
                                    GradientStop {
                                        position: 1.0
                                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.92)
                                    }
                                }

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    verticalAlignment: Text.AlignBottom
                                    bottomPadding: 5
                                    text: root.baseName(cell.modelData)
                                    color: cell.isCurrent ? Colors.accent : Colors.fg
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    elide: Text.ElideMiddle
                                }
                            }

                            Rectangle {
                                visible: cell.isCurrent
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 8
                                width: 22
                                height: 22
                                radius: 11
                                color: Colors.accent

                                Text {
                                    anchors.centerIn: parent
                                    text: "󰄬"
                                    color: Colors.bg
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                }
                            }
                        }

                        MouseArea {
                            id: tileArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: grid.currentIndex = cell.index
                            onClicked: root.apply(cell.modelData)
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: root.results.length === 0
                        text: "пусто"
                        color: Colors.fgDim
                        opacity: 0.5
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 13
                    }
                }

                Item {
                    width: parent.width
                    height: 14

                    Text {
                        anchors.left: parent.left
                        text: root.focused !== "" ? root.baseName(root.focused) : ""
                        color: Colors.fgDim
                        opacity: 0.45
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        elide: Text.ElideMiddle
                        width: parent.width - 260
                    }

                    Text {
                        anchors.right: parent.right
                        text: "tab фильтр · ↵ применить · esc закрыть"
                        color: Colors.fgDim
                        opacity: 0.45
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
