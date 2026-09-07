import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property var files: []
    property string current: ""
    property string filter: "All"

    property var tones: ({})
    property var history: []

    readonly property string mono: Fonts.mono

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
        Sfx.panel(root.shown);
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

    function prettyName(p) {
        const b = root.baseName(p);
        const cut = b.lastIndexOf(".");
        const stem = cut > 0 ? b.substring(0, cut) : b;
        return stem.replace(/[-_]+/g, " ");
    }

    function toneOf(p) {
        const hex = root.tones[root.baseName(p)];
        return hex ? hex : "";
    }

    function thumbFor(path) {
        return path === "" ? "" : "file://" + root.thumbDir + "/" + root.baseName(path);
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
            opacity: root.shown ? 0.62 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Bloom {
            target: card
            amount: root.shown ? 0.22 : 0
            inset: 48
            blurMax: 64
        }

        ClippingRectangle {
            id: card

            anchors.centerIn: parent
            width: Math.min(1320, parent.width - 72)
            height: Math.min(820, parent.height - 72)
            radius: Shape.modal
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.97)

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.95
            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                SpringAnimation {
                    spring: Motion.panelSpring
                    damping: Motion.panelDamping
                    mass: Motion.panelMass
                    epsilon: 0.001
                }
            }

            Item {
                id: backdrop

                anchors.fill: parent

                property bool onA: true
                readonly property string want: root.thumbFor(root.focused)

                onWantChanged: {
                    if (backdrop.want === "")
                        return;
                    if (backdrop.onA)
                        layerB.source = backdrop.want;
                    else
                        layerA.source = backdrop.want;
                }

                Image {
                    id: layerA
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: 1600
                    opacity: backdrop.onA ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.slow } }
                    onStatusChanged: if (status === Image.Ready && !backdrop.onA) backdrop.onA = true
                }

                Image {
                    id: layerB
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: 1600
                    opacity: backdrop.onA ? 0 : 1
                    Behavior on opacity { NumberAnimation { duration: Motion.slow } }
                    onStatusChanged: if (status === Image.Ready && backdrop.onA) backdrop.onA = false
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.97)
                    }
                    GradientStop {
                        position: 0.34
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.88)
                    }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.74)
                    }
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop {
                        position: 0.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.32)
                    }
                    GradientStop { position: 0.5; color: "transparent" }
                    GradientStop {
                        position: 1.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)
                    }
                }
            }

            Sheen {
                anchors.fill: parent
                radius: Shape.modal
                edge: Colors.accent
                edgeOpacity: 0.28
                grainOpacity: 0.022
            }

            Item {
                id: side

                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 32
                width: 372

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    spacing: 22

                    Row {
                        width: parent.width
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰸉"
                            color: Colors.accent
                            font.family: root.mono
                            font.pixelSize: 17
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "wallpapers"
                            color: Colors.fg
                            font.family: Fonts.display
                            font.pixelSize: Fonts.titleSize
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: shownCount.implicitWidth + 16
                            height: 20
                            radius: Shape.detail
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.10)

                            Text {
                                id: shownCount
                                anchors.centerIn: parent
                                text: root.results.length + " / " + root.files.length
                                color: Colors.fgDim
                                opacity: 0.75
                                font.family: root.mono
                                font.pixelSize: 10
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 10

                        Text {
                            width: parent.width
                            text: root.focused !== ""
                                ? root.prettyName(root.focused)
                                : I18n.t("wall.nothing")
                            color: Colors.fg
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                            font.family: Fonts.display
                            font.pixelSize: 30
                            font.weight: Font.DemiBold
                        }

                        Row {
                            spacing: 8
                            visible: root.focused !== ""

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.toneOf(root.focused) !== ""
                                width: 18
                                height: 18
                                radius: 9
                                antialiasing: true
                                color: root.toneOf(root.focused) !== ""
                                    ? root.toneOf(root.focused) : "transparent"
                                border.width: 1
                                border.color: Qt.rgba(0, 0, 0, 0.35)
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.bucket(root.focused) !== ""
                                width: bucketLabel.implicitWidth + 16
                                height: 20
                                radius: Shape.detail
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.10)

                                Text {
                                    id: bucketLabel
                                    anchors.centerIn: parent
                                    text: root.bucket(root.focused).toLowerCase()
                                    color: Colors.fgDim
                                    opacity: 0.8
                                    font.family: root.mono
                                    font.pixelSize: 9
                                    font.letterSpacing: 1
                                }
                            }

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: root.focused === root.current
                                width: liveLabel.implicitWidth + 18
                                height: 20
                                radius: Shape.detail
                                color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                               Colors.accent.b, 0.22)

                                Text {
                                    id: liveLabel
                                    anchors.centerIn: parent
                                    text: "󰄬  on screen"
                                    color: Colors.accent
                                    font.family: root.mono
                                    font.pixelSize: 9
                                    font.letterSpacing: 1
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: 48
                        radius: Shape.field
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
                        border.width: 1
                        border.color: search.activeFocus
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.55)
                            : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                      Colors.outline.b, 0.16)
                        Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                        Rectangle {
                            z: -1
                            anchors.centerIn: parent
                            width: parent.width + 10
                            height: parent.height + 10
                            radius: parent.radius + 5
                            color: Colors.accent
                            opacity: search.activeFocus ? 0.20 : 0
                            Behavior on opacity { NumberAnimation { duration: Motion.slow } }

                            layer.enabled: true
                            layer.effect: MultiEffect {
                                blurEnabled: true
                                blur: 1.0
                                blurMax: 36
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 12

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "󰍉"
                                color: Colors.accent
                                opacity: search.activeFocus ? 1 : 0.7
                                font.family: root.mono
                                font.pixelSize: 16
                            }

                            TextInput {
                                id: search
                                width: parent.width - 44
                                anchors.verticalCenter: parent.verticalCenter
                                color: Colors.fg
                                font.family: root.mono
                                font.pixelSize: 14
                                clip: true
                                selectByMouse: true
                                selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                        Colors.accent.b, 0.35)

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: search.text === ""
                                    text: I18n.t("act.search")
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
                        }
                    }

                    Flow {
                        width: parent.width
                        spacing: 8

                        Repeater {
                            model: root.filters

                            Rectangle {
                                id: pill

                                required property var modelData

                                readonly property bool active: root.filter === modelData.name
                                readonly property bool tinted: modelData.hex !== ""

                                width: tinted ? 36 : label.implicitWidth + 26
                                height: 36
                                radius: Shape.chip
                                antialiasing: true

                                color: active
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                              Colors.accent.b, 0.24)
                                    : pillArea.containsMouse
                                        ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                                  Colors.bgAlt.b, 0.7)
                                        : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                                  Colors.bgAlt.b, 0.4)
                                border.width: 1
                                border.color: active
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                              Colors.accent.b, 0.6)
                                    : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                              Colors.outline.b, 0.12)

                                Behavior on color { ColorAnimation { duration: Motion.fast } }
                                Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                                scale: active ? 1.06 : (pillArea.containsMouse ? 1.03 : 1.0)
                                Behavior on scale {
                                    SpringAnimation {
                                        spring: Motion.tapSpring
                                        damping: Motion.tapDamping
                                        mass: Motion.tapMass
                                        epsilon: 0.001
                                    }
                                }

                                Rectangle {
                                    visible: pill.tinted
                                    anchors.centerIn: parent
                                    width: 16
                                    height: 16
                                    radius: 8
                                    antialiasing: true
                                    color: pill.modelData.hex
                                    border.width: 1
                                    border.color: Qt.rgba(0, 0, 0, 0.35)
                                }

                                Text {
                                    id: label
                                    visible: !pill.tinted
                                    anchors.centerIn: parent
                                    text: pill.modelData.name.toLowerCase()
                                    color: pill.active ? Colors.accent : Colors.fgDim
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    id: pillArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        Sfx.pick();
                                        root.filter = pill.modelData.name;
                                        search.forceActiveFocus();
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    spacing: 14

                    Row {
                        width: parent.width
                        spacing: 10

                        Rectangle {
                            width: parent.width - 130
                            height: 46
                            radius: Shape.field
                            antialiasing: true
                            opacity: root.focused !== "" ? 1 : 0.4

                            color: applyArea.containsMouse
                                ? Colors.accent
                                : Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.22)
                            border.width: 1
                            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                  Colors.accent.b, 0.55)
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            scale: applyArea.pressed ? 0.97 : 1
                            Behavior on scale { NumberAnimation { duration: Motion.fast } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 10

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰸉"
                                    color: applyArea.containsMouse
                                        ? Colors.accentText : Colors.accent
                                    font.family: root.mono
                                    font.pixelSize: 15
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: I18n.t("act.open")
                                    color: applyArea.containsMouse
                                        ? Colors.accentText : Colors.fg
                                    font.family: Fonts.display
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                }
                            }

                            MouseArea {
                                id: applyArea
                                anchors.fill: parent
                                enabled: root.focused !== ""
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Sfx.fill();
                                    root.apply(root.focused);
                                }
                            }
                        }

                        Rectangle {
                            width: 120
                            height: 46
                            radius: Shape.field
                            antialiasing: true
                            color: shuffleArea.containsMouse
                                ? Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                          Colors.accentAlt.b, 0.22)
                                : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                          Colors.bgAlt.b, 0.5)
                            border.width: 1
                            border.color: Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                                  Colors.accentAlt.b, 0.35)
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            scale: shuffleArea.pressed ? 0.97 : 1
                            Behavior on scale { NumberAnimation { duration: Motion.fast } }

                            Row {
                                anchors.centerIn: parent
                                spacing: 8

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰑓"
                                    color: Colors.accentAlt
                                    font.family: root.mono
                                    font.pixelSize: 14
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "random"
                                    color: Colors.fgDim
                                    opacity: 0.9
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }
                            }

                            MouseArea {
                                id: shuffleArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    Sfx.tapAlt();
                                    root.shuffle();
                                }
                            }
                        }
                    }

                    Text {
                        width: parent.width
                        text: I18n.t("wall.keys")
                        color: Colors.fgDim
                        opacity: 0.45
                        font.family: root.mono
                        font.pixelSize: 10
                    }
                }
            }

            GridView {
                id: grid

                anchors.left: side.right
                anchors.leftMargin: 26
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.topMargin: 26
                anchors.bottomMargin: 26
                anchors.rightMargin: 26

                clip: true
                model: root.results
                cellWidth: Math.floor(width / 3)
                cellHeight: Math.floor(cellWidth * 0.62)
                currentIndex: 0
                boundsBehavior: Flickable.StopAtBounds
                cacheBuffer: 1400
                highlightMoveDuration: 160

                delegate: Item {
                    id: cell

                    required property var modelData
                    required property int index

                    width: grid.cellWidth
                    height: grid.cellHeight

                    readonly property bool isCurrent: modelData === root.current
                    readonly property bool isFocused: index === grid.currentIndex

                    opacity: 0
                    transform: Scale {
                        id: cellPop
                        origin.x: cell.width / 2
                        origin.y: cell.height / 2
                        xScale: 0.92
                        yScale: 0.92
                    }

                    SequentialAnimation {
                        running: true
                        PauseAnimation { duration: Motion.delay(cell.index) }
                        ParallelAnimation {
                            NumberAnimation {
                                target: cell; property: "opacity"; to: 1
                                duration: Motion.base
                            }
                            NumberAnimation {
                                target: cellPop; property: "xScale"; to: 1
                                duration: Motion.slow
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.snap
                            }
                            NumberAnimation {
                                target: cellPop; property: "yScale"; to: 1
                                duration: Motion.slow
                                easing.type: Easing.Bezier
                                easing.bezierCurve: Motion.snap
                            }
                        }
                    }

                    Rectangle {
                        z: -1
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: parent.height - 8
                        radius: Shape.field + 6
                        color: Colors.accent
                        opacity: cell.isCurrent ? 0.36
                               : (cell.isFocused ? 0.28
                               : (tileArea.containsMouse ? 0.18 : 0))
                        Behavior on opacity { NumberAnimation { duration: Motion.base } }

                        layer.enabled: opacity > 0.01
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: 1.0
                            blurMax: 34
                        }
                    }

                    ClippingRectangle {
                        id: tile

                        anchors.fill: parent
                        anchors.margins: 9
                        radius: Shape.field + 2
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.35)
                        border.width: cell.isCurrent || cell.isFocused ? 2 : 1
                        border.color: cell.isCurrent
                            ? Colors.accent
                            : (cell.isFocused
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.6)
                                : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                          Colors.outline.b, 0.22))

                        scale: tileArea.containsMouse ? 1.05 : (cell.isFocused ? 1.02 : 1.0)
                        Behavior on scale {
                            SpringAnimation {
                                spring: Motion.tapSpring
                                damping: Motion.tapDamping
                                mass: Motion.tapMass
                                epsilon: 0.001
                            }
                        }
                        Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                        Image {
                            anchors.fill: parent
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            sourceSize.width: 560
                            source: root.thumbFor(cell.modelData)
                            onStatusChanged: {
                                if (status === Image.Error)
                                    source = "file://" + cell.modelData;
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            height: 34
                            opacity: tileArea.containsMouse || cell.isFocused ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Motion.fast } }

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
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                verticalAlignment: Text.AlignBottom
                                bottomPadding: 7
                                text: root.prettyName(cell.modelData)
                                color: cell.isCurrent ? Colors.accent : Colors.fg
                                font.family: Fonts.display
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                        }

                        Rectangle {
                            visible: cell.isCurrent
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 9
                            width: 26
                            height: 26
                            radius: width / 2
                            antialiasing: true
                            color: Colors.accent
                            border.width: 2
                            border.color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)

                            Text {
                                anchors.centerIn: parent
                                text: "󰄬"
                                color: Colors.accentText
                                font.family: root.mono
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }
                    }

                    MouseArea {
                        id: tileArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: grid.currentIndex = cell.index
                        onClicked: {
                            Sfx.fill();
                            root.apply(cell.modelData);
                        }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: root.results.length === 0
                    text: I18n.t("state.empty")
                    color: Colors.fgDim
                    opacity: 0.5
                    font.family: root.mono
                    font.pixelSize: 13
                }
            }
        }
    }
}
