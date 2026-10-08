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
            root.pick = Math.max(0, root.results.indexOf(root.current));
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

    function step(d) {
        const n = root.results.length;
        if (n === 0)
            return;
        root.pick = (root.pick + d + n) % n;
        Sfx.tick();
    }

    function apply(path) {
        if (!path)
            return;
        root.close();
        root.current = path;
        applyLater.path = path;
        applyLater.restart();
    }

    Timer {
        id: applyLater
        property string path: ""
        interval: 280
        onTriggered: {
            const path = applyLater.path;
            const scr = win.screen;
            let pos = "0.5,0.985";
            if (scr && IslandBus.isleW > 0) {
                const px = (IslandBus.isleX + IslandBus.isleW / 2) / scr.width;
                const py = 1 - (IslandBus.isleY + IslandBus.isleH / 2) / scr.height;
                pos = px.toFixed(4) + "," + py.toFixed(4);
            }
            const tone = root.toneOf(path);
            IslandBus.wallApplied(path, tone !== "" ? tone : Colors.accent);
            setter.command = ["env", "WALL_POS=" + pos,
                              Quickshell.env("HOME") + "/.config/hypr/scripts/set-wallpaper.sh", path];
            setter.running = true;

            historyWriter.command = ["sh", "-c",
                "printf '%s\\n' \"$1\" >> '" + root.historyPath + "'; " +
                "tail -n 60 '" + root.historyPath + "' > '" + root.historyPath + ".tmp' && " +
                "mv '" + root.historyPath + ".tmp' '" + root.historyPath + "'",
                "sh", path];
            historyWriter.running = true;
        }
    }

    function shuffle() {
        const pool = root.results.length > 0 ? root.results : root.files;
        if (pool.length === 0)
            return;
        root.pick = Math.max(0, root.results.indexOf(pool[Math.floor(Math.random() * pool.length)]));
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

    property int pick: 0
    onResultsChanged: root.pick = 0

    readonly property string focused:
        root.pick >= 0 && root.pick < results.length ? results[root.pick] : ""

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    readonly property bool isle: {
        if (!Prefs.apple || !IslandConfig.s("enabled"))
            return false;
        return IslandConfig.s("inBar") ? Prefs.barAtTop : IslandConfig.s("edge") === "top";
    }
    readonly property bool talk: root.shown && root.isle

    readonly property color tone: root.toneOf(root.focused) !== "" ? root.toneOf(root.focused) : Colors.accent
    property color glow: root.tone
    Behavior on glow { ColorAnimation { duration: 1000; easing.type: Easing.InOutCubic } }

    Binding { target: IslandBus; property: "searching"; value: root.talk }
    Binding { target: IslandBus; property: "searchScreen"; value: win.screen ? win.screen.name : ""; when: root.talk }
    Binding { target: IslandBus; property: "query"; value: search.text; when: root.talk }
    Binding { target: IslandBus; property: "cursor"; value: search.cursorPosition; when: root.talk }
    Binding { target: IslandBus; property: "mode"; value: "wall"; when: root.talk }
    Binding { target: IslandBus; property: "calc"; value: ""; when: root.talk }
    Binding {
        target: IslandBus; property: "hint"; when: root.talk
        value: root.results.length === 0 ? "No wallpapers"
             : (root.pick + 1) + " of " + root.results.length
    }
    Binding { target: IslandBus; property: "hintGlyph"; value: ""; when: root.talk }
    Binding { target: IslandBus; property: "hue"; value: root.glow; when: root.talk }
    Binding { target: IslandBus; property: "hueOn"; value: true; when: root.talk }

    property int lastLen: 0
    Connections {
        target: search
        function onTextChanged() {
            const n = search.text.length;
            if (root.talk && n !== root.lastLen)
                IslandBus.keyed(n > root.lastLen ? 1 : -1);
            root.lastLen = n;
        }
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-wallpapers"
        id: win
        screen: Focus.screen
        visible: root.shown || stage.opacity > 0.01
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"

        Item {
            id: stage
            anchors.fill: parent

            opacity: root.shown ? 1 : 0
            Behavior on opacity {
                NumberAnimation { duration: root.shown ? 360 : 260; easing.type: Easing.OutCubic }
            }

            Rectangle {
                anchors.fill: parent
                color: "black"
            }

            Item {
                id: backdrop
                anchors.fill: parent

                SequentialAnimation on scale {
                    running: root.shown
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 1.06; duration: 24000; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.06; to: 1.0; duration: 24000; easing.type: Easing.InOutSine }
                }

                property bool onA: true
                readonly property string want: root.focused !== "" ? "file://" + root.focused : ""

                onWantChanged: wantLater.restart()

                Timer {
                    id: wantLater
                    interval: 140
                    onTriggered: {
                        if (backdrop.want === "")
                            return;
                        if (backdrop.onA)
                            layerB.source = backdrop.want;
                        else
                            layerA.source = backdrop.want;
                    }
                }

                Image {
                    id: layerA
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: 1920
                    opacity: backdrop.onA ? 1 : 0
                    scale: backdrop.onA ? 1 : 1.04
                    Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutCubic } }
                    Behavior on scale { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }
                    onStatusChanged: if (status === Image.Ready && !backdrop.onA) backdrop.onA = true
                }

                Image {
                    id: layerB
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: false
                    sourceSize.width: 1920
                    opacity: backdrop.onA ? 0 : 1
                    scale: backdrop.onA ? 1.04 : 1
                    Behavior on opacity { NumberAnimation { duration: 700; easing.type: Easing.InOutCubic } }
                    Behavior on scale { NumberAnimation { duration: 1400; easing.type: Easing.OutCubic } }
                    onStatusChanged: if (status === Image.Ready && backdrop.onA) backdrop.onA = false
                }
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.42) }
                    GradientStop { position: 0.45; color: Qt.rgba(0, 0, 0, 0.30) }
                    GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.78) }
                }
            }

            RectangularShadow {
                x: stage.width / 2 - 340
                y: carousel.cy - 160
                width: 680
                height: 360
                radius: 120
                blur: 140
                color: Colors.alpha(root.glow, 0.30)
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }

            property real lookX: 0
            property real lookY: 0
            Behavior on lookX { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }
            Behavior on lookY { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

            HoverHandler {
                onPointChanged: {
                    stage.lookX = Math.max(-1, Math.min(1, (point.position.x - stage.width / 2) / (stage.width / 2)));
                    stage.lookY = Math.max(-1, Math.min(1, (point.position.y - carousel.cy) / (stage.height / 2)));
                }
                onHoveredChanged: if (!hovered) { stage.lookX = 0; stage.lookY = 0; }
            }

            property real t: 0
            NumberAnimation on t {
                running: root.shown
                loops: Animation.Infinite
                from: 0; to: Math.PI * 2
                duration: 7000
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                property real acc: 0
                onWheel: (ev) => {
                    const d = Math.abs(ev.angleDelta.x) > Math.abs(ev.angleDelta.y)
                        ? ev.angleDelta.x : ev.angleDelta.y;
                    acc += d;
                    while (acc >= 120) { acc -= 120; root.step(-1); }
                    while (acc <= -120) { acc += 120; root.step(1); }
                }
            }

            Item {
                id: carousel
                anchors.fill: parent

                readonly property real cy: stage.height * 0.44
                readonly property real span: stage.width

                opacity: root.shown ? 1 : 0
                transform: Translate {
                    y: root.shown ? 0 : 36
                    Behavior on y { NumberAnimation { duration: 560; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: 460; easing.type: Easing.OutCubic } }

                PathView {
                    id: path

                    anchors.fill: parent
                    model: root.results
                    pathItemCount: Math.min(9, root.results.length)
                    preferredHighlightBegin: 0.5
                    preferredHighlightEnd: 0.5
                    highlightRangeMode: PathView.StrictlyEnforceRange
                    highlightMoveDuration: 720
                    snapMode: PathView.SnapOneItem
                    cacheItemCount: 4
                    currentIndex: root.pick
                    onCurrentIndexChanged: if (currentIndex >= 0 && currentIndex !== root.pick) root.pick = currentIndex

                    path: Path {
                        startX: -0.04 * carousel.span
                        startY: carousel.cy - 74
                        PathAttribute { name: "s"; value: 0.46 }
                        PathAttribute { name: "ry"; value: 46 }
                        PathAttribute { name: "dim"; value: 0.66 }
                        PathAttribute { name: "zz"; value: 0 }

                        PathQuad {
                            x: 0.25 * carousel.span; y: carousel.cy - 14
                            controlX: 0.08 * carousel.span; controlY: carousel.cy - 30
                        }
                        PathPercent { value: 0.36 }
                        PathAttribute { name: "s"; value: 0.70 }
                        PathAttribute { name: "ry"; value: 30 }
                        PathAttribute { name: "dim"; value: 0.38 }
                        PathAttribute { name: "zz"; value: 50 }

                        PathQuad {
                            x: 0.5 * carousel.span; y: carousel.cy
                            controlX: 0.38 * carousel.span; controlY: carousel.cy
                        }
                        PathPercent { value: 0.5 }
                        PathAttribute { name: "s"; value: 1.0 }
                        PathAttribute { name: "ry"; value: 0 }
                        PathAttribute { name: "dim"; value: 0 }
                        PathAttribute { name: "zz"; value: 100 }

                        PathQuad {
                            x: 0.75 * carousel.span; y: carousel.cy - 14
                            controlX: 0.62 * carousel.span; controlY: carousel.cy
                        }
                        PathPercent { value: 0.64 }
                        PathAttribute { name: "s"; value: 0.70 }
                        PathAttribute { name: "ry"; value: -30 }
                        PathAttribute { name: "dim"; value: 0.38 }
                        PathAttribute { name: "zz"; value: 50 }

                        PathQuad {
                            x: 1.04 * carousel.span; y: carousel.cy - 74
                            controlX: 0.92 * carousel.span; controlY: carousel.cy - 30
                        }
                        PathPercent { value: 1.0 }
                        PathAttribute { name: "s"; value: 0.46 }
                        PathAttribute { name: "ry"; value: -46 }
                        PathAttribute { name: "dim"; value: 0.66 }
                        PathAttribute { name: "zz"; value: 0 }
                    }

                    delegate: Item {
                        id: cell

                        required property var modelData
                        required property int index

                        readonly property bool isCur: PathView.isCurrentItem
                        readonly property bool onScreen: cell.modelData === root.current
                        readonly property color hue: root.toneOf(cell.modelData) !== ""
                            ? root.toneOf(cell.modelData) : Colors.accent

                        width: 540
                        height: 338
                        z: cell.PathView.zz
                        scale: cell.PathView.s

                        property real live: cell.isCur ? 1 : 0
                        Behavior on live { NumberAnimation { duration: 600; easing.type: Easing.InOutCubic } }

                        transform: [
                            Rotation {
                                origin.x: cell.width / 2
                                origin.y: cell.height / 2
                                axis { x: 0; y: 1; z: 0 }
                                angle: cell.PathView.ry + 7 * stage.lookX * cell.live
                            },
                            Rotation {
                                origin.x: cell.width / 2
                                origin.y: cell.height / 2
                                axis { x: 1; y: 0; z: 0 }
                                angle: -5 * stage.lookY * cell.live
                            },
                            Translate { y: Math.sin(stage.t) * 5 * cell.live }
                        ]

                        Item {
                            visible: cell.live > 0.01
                            opacity: 0.14 * cell.live
                            y: cell.height + 10
                            width: cell.width
                            height: cell.height * 0.45
                            clip: true

                            Image {
                                width: cell.width
                                height: cell.height
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 600
                                source: cell.live > 0.01 ? root.thumbFor(cell.modelData) : ""
                                transform: Scale { origin.y: cell.height / 2; yScale: -1 }
                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    blurEnabled: true
                                    blur: 0.4
                                    blurMax: 24
                                    maskEnabled: true
                                    maskSource: reflMask
                                }
                            }
                        }

                        Rectangle {
                            id: reflMask
                            visible: false
                            layer.enabled: true
                            width: cell.width
                            height: cell.height
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "transparent" }
                                GradientStop { position: 0.62; color: "transparent" }
                                GradientStop { position: 1.0; color: "white" }
                            }
                        }

                        RectangularShadow {
                            anchors.fill: parent
                            radius: 26
                            blur: cell.isCur ? 56 : 30
                            offset.y: cell.isCur ? 22 : 12
                            spread: -4
                            color: cell.isCur ? Colors.alpha(cell.hue, 0.55) : Qt.rgba(0, 0, 0, 0.6)
                            Behavior on color { ColorAnimation { duration: 500 } }
                        }

                        ClippingRectangle {
                            anchors.fill: parent
                            radius: 26
                            color: "#0d0d0d"

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 600
                                source: root.thumbFor(cell.modelData)
                                onStatusChanged: if (status === Image.Error) source = "file://" + cell.modelData
                            }

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 1100
                                source: cell.isCur ? "file://" + cell.modelData : ""
                                opacity: status === Image.Ready ? 1 : 0
                                Behavior on opacity { NumberAnimation { duration: 400 } }
                            }

                            Rectangle {
                                anchors.fill: parent
                                gradient: Gradient {
                                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
                                    GradientStop { position: 0.35; color: "transparent" }
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                color: "black"
                                opacity: cell.PathView.dim
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: 26
                            color: "transparent"
                            antialiasing: true
                            border.width: 1
                            border.color: cell.isCur ? Qt.rgba(1, 1, 1, 0.28) : Qt.rgba(1, 1, 1, 0.10)
                        }

                        Rectangle {
                            visible: cell.onScreen
                            anchors.top: parent.top
                            anchors.right: parent.right
                            anchors.margins: 16
                            width: 30
                            height: 30
                            radius: 15
                            color: Qt.rgba(0, 0, 0, 0.55)
                            border.width: 1
                            border.color: Qt.rgba(1, 1, 1, 0.3)

                            Text {
                                anchors.centerIn: parent
                                text: "󰄬"
                                color: "white"
                                font.family: Fonts.glyph
                                font.pixelSize: 14
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (cell.isCur) {
                                    Sfx.fill();
                                    root.apply(cell.modelData);
                                } else {
                                    root.pick = cell.index;
                                    Sfx.tick();
                                }
                            }
                        }
                    }
                }
            }

            Item {
                id: caption
                anchors.horizontalCenter: parent.horizontalCenter
                y: carousel.cy + 338 / 2 + 40
                width: 700
                height: 80

                property string name: ""
                property string sub: ""
                property real lift: 0

                readonly property string wantName: root.focused !== "" ? root.prettyName(root.focused) : ""
                onWantNameChanged: capSwap.restart()

                SequentialAnimation {
                    id: capSwap
                    ParallelAnimation {
                        NumberAnimation { target: capBody; property: "opacity"; to: 0; duration: 200; easing.type: Easing.InOutCubic }
                        NumberAnimation { target: caption; property: "lift"; to: -6; duration: 200; easing.type: Easing.InOutCubic }
                    }
                    ScriptAction { script: caption.name = caption.wantName }
                    ParallelAnimation {
                        NumberAnimation { target: capBody; property: "opacity"; to: 1; duration: 520; easing.type: Easing.OutCubic }
                        NumberAnimation { target: caption; property: "lift"; from: 8; to: 0; duration: 600; easing.type: Easing.OutCubic }
                    }
                }

                Column {
                    id: capBody
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 10
                    transform: Translate { y: caption.lift }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Math.min(implicitWidth, 700)
                        horizontalAlignment: Text.AlignHCenter
                        text: caption.name
                        color: "white"
                        font.family: Fonts.display
                        font.pixelSize: 26
                        font.weight: Font.DemiBold
                        elide: Text.ElideRight
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 10

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 10
                            height: 10
                            radius: 5
                            color: root.glow
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: root.focused === root.current ? "On screen" : "↵  Apply"
                            color: Qt.rgba(1, 1, 1, 0.55)
                            font.family: Fonts.display
                            font.pixelSize: 13
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 54
                spacing: 14

                Repeater {
                    model: root.filters

                    Item {
                        id: dotItem
                        required property var modelData
                        readonly property bool on: root.filter === dotItem.modelData.name
                        readonly property bool tinted: dotItem.modelData.hex !== ""

                        width: dotItem.tinted ? 22 : wordText.implicitWidth + 18
                        height: 22

                        Rectangle {
                            anchors.centerIn: parent
                            width: parent.width + (dotItem.on ? 8 : 0)
                            height: parent.height + (dotItem.on ? 8 : 0)
                            radius: height / 2
                            color: "transparent"
                            border.width: 1.5
                            border.color: Qt.rgba(1, 1, 1, dotItem.on ? 0.75 : 0)
                            Behavior on width { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            Behavior on height { NumberAnimation { duration: 260; easing.type: Easing.OutCubic } }
                            Behavior on border.color { ColorAnimation { duration: 260 } }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: dotItem.tinted ? dotItem.modelData.hex : Qt.rgba(1, 1, 1, dotItem.on ? 0.16 : 0.08)
                            Behavior on color { ColorAnimation { duration: 200 } }
                        }

                        Text {
                            id: wordText
                            visible: !dotItem.tinted
                            anchors.centerIn: parent
                            text: dotItem.modelData.name.toLowerCase()
                            color: Qt.rgba(1, 1, 1, dotItem.on ? 0.95 : 0.6)
                            font.family: Fonts.display
                            font.pixelSize: 11
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -4
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                Sfx.pick();
                                root.filter = dotItem.modelData.name;
                                search.forceActiveFocus();
                            }
                        }
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 22
                text: "←→ browse     ↵ apply     tab colour     type to search"
                color: Qt.rgba(1, 1, 1, 0.32)
                font.family: Fonts.display
                font.pixelSize: 11
            }

            Text {
                visible: !root.isle
                anchors.horizontalCenter: parent.horizontalCenter
                y: 60
                text: search.text !== "" ? search.text : "Type to search"
                color: Qt.rgba(1, 1, 1, search.text !== "" ? 0.9 : 0.35)
                font.family: Fonts.display
                font.pixelSize: 16
            }

            Text {
                anchors.centerIn: parent
                visible: root.results.length === 0
                text: "No wallpapers"
                color: Qt.rgba(1, 1, 1, 0.5)
                font.family: Fonts.display
                font.pixelSize: 16
            }
        }

        TextInput {
            id: search
            width: 10
            height: 10
            opacity: 0

            Keys.onEscapePressed: root.close()
            Keys.onLeftPressed: root.step(-1)
            Keys.onRightPressed: root.step(1)
            Keys.onUpPressed: root.cycleFilter(-1)
            Keys.onDownPressed: root.cycleFilter(1)
            Keys.onTabPressed: root.cycleFilter(1)
            Keys.onBacktabPressed: root.cycleFilter(-1)
            Keys.onReturnPressed: root.apply(root.focused)
            Keys.onEnterPressed: root.apply(root.focused)
        }
    }

    IpcHandler {
        target: "wallpapers"
        function open(): void { if (!root.shown) root.toggle(); }
        function close(): void { root.close(); }
        function step(d: int): void { root.step(d); }
        function type(t: string): void { search.text = t; }
        function apply(): void { root.apply(root.focused); }
    }
}
