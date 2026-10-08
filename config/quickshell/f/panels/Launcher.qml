import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import Quickshell.Wayland
import "root:/design"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    function toggle() {
        root.shown = !root.shown;
    }

    function toggleCalc() {
        if (root.shown && root.calcMode) {
            root.close();
            return;
        }
        root.shown = true;
        search.text = "=";
        search.cursorPosition = search.text.length;
        search.forceActiveFocus();
    }

    function close() {
        root.shown = false;
    }

    onShownChanged: {
        Sfx.panel(root.shown);
        root.winsOpen = false;
        if (shown) {
            root.lastLen = 0;
            root.lastHits = -1;
            search.text = "";
            root.sel = 0;
            search.forceActiveFocus();
        } else {
            Running.query = null;
        }
    }

    property int sel: 0

    function move(step) {
        if (root.winsOpen) {
            root.winSel = Math.max(0, Math.min(root.wins.length - 1, root.winSel + step));
            return;
        }
        if (root.calcMode || root.runMode || root.drip)
            return;
        const n = root.drip ? Math.min(root.results.length, 10) : root.results.length;
        root.sel = Math.max(0, Math.min(n - 1, root.sel + step));
    }

    function setQuery(t) {
        search.text = t;
        search.cursorPosition = t.length;
        search.forceActiveFocus();
    }

    readonly property bool drip: {
        if (!Prefs.apple || !IslandConfig.s("enabled"))
            return false;
        const top = IslandConfig.s("inBar") ? Prefs.barAtTop : IslandConfig.s("edge") === "top";
        if (!top)
            return false;
        if (IslandConfig.s("hideFull")) {
            const m = Hyprland.focusedMonitor;
            const ws = m ? m.activeWorkspace : null;
            if (ws && ws.hasFullscreen)
                return false;
        }
        return true;
    }

    readonly property string mode: root.runMode ? "run" : root.calcMode ? "calc" : "app"

    readonly property string isleHint: {
        if (root.calcMode || root.runMode)
            return "";
        if (search.text.trim() !== "" && root.results.length === 0)
            return "No matches";
        if (!Running.any)
            return "";
        const ws = Running.workspaces;
        return ws.length === 1 ? "Open · desk " + ws[0] : "Open · " + ws.length + " desks";
    }
    readonly property string isleHintGlyph:
        root.isleHint === "No matches" ? "󰅖" : root.isleHint !== "" ? "󰖯" : ""

    property int lastLen: 0
    property int lastHits: -1

    Connections {
        target: search
        function onTextChanged() {
            const n = search.text.length;
            root.winsOpen = false;
            if (root.shown && root.drip && n !== root.lastLen)
                IslandBus.keyed(n > root.lastLen ? 1 : -1);
            root.lastLen = n;
        }
    }

    onResultsChanged: {
        const n = root.results.length;
        if (root.shown && root.drip && !root.calcMode && !root.runMode
            && search.text.trim() !== "" && n === 0 && root.lastHits !== 0)
            IslandBus.nomatch();
        root.lastHits = n;
    }

    Binding { target: IslandBus; property: "searching"; value: (root.shown || drops.holding) && root.drip }
    Binding { target: IslandBus; property: "searchScreen"; value: win.screen ? win.screen.name : ""; when: root.shown || drops.holding }
    Binding { target: IslandBus; property: "query"; value: search.text; when: (root.shown || drops.holding) && root.drip }
    Binding { target: IslandBus; property: "cursor"; value: search.cursorPosition; when: (root.shown || drops.holding) && root.drip }
    Binding { target: IslandBus; property: "mode"; value: root.mode; when: (root.shown || drops.holding) && root.drip }
    Binding { target: IslandBus; property: "calc"; value: root.calcResult; when: (root.shown || drops.holding) && root.drip }
    Binding { target: IslandBus; property: "hint"; value: root.isleHint; when: (root.shown || drops.holding) && root.drip }
    Binding { target: IslandBus; property: "hintGlyph"; value: root.isleHintGlyph; when: (root.shown || drops.holding) && root.drip }
    Binding { target: IslandBus; property: "hue"; value: drops.hue; when: (root.shown || drops.holding) && root.drip }
    Binding { target: IslandBus; property: "hueOn"; value: drops.hueOn; when: (root.shown || drops.holding) && root.drip }

    property bool winsOpen: false
    property int winSel: 0
    onSelChanged: root.winsOpen = false

    readonly property var wins: {
        const e = root.highlighted;
        if (!e || root.calcMode || root.runMode)
            return [];
        const out = [];
        const list = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        for (const t of list) {
            const o = t ? t.lastIpcObject : null;
            if (!o || !o.workspace || !Running.matches(e, o["class"]))
                continue;
            out.push({ title: o.title || t.title || e.name, ws: o.workspace.id, addr: o.address });
        }
        out.sort((a, b) => a.ws - b.ws);
        return out.slice(0, 4);
    }

    function focusWin(w) {
        if (!w)
            return;
        Sfx.tapAlt();
        root.close();
        Hyprland.dispatch("focuswindow address:" + w.addr);
    }

    function openWins() {
        return false;
        root.winSel = 0;
        root.winsOpen = true;
        Sfx.pick();
        return true;
    }

    IpcHandler {
        target: "launcher"
        function open(): void { if (!root.shown) root.toggle(); }
        function close(): void { root.close(); }
        function state(): string {
            return "shown=" + root.shown + " drip=" + root.drip + " living=" + drops.living + " sel=" + root.sel;
        }
        function type(t: string): void { if (!root.shown) root.toggle(); root.setQuery(t); }
        function key(k: string): void {
            if (k === "down") root.move(1);
            else if (k === "up") root.move(-1);
            else if (k === "right") root.openWins();
            else if (k === "left") root.winsOpen = false;
            else if (k === "enter") root.winsOpen ? root.focusWin(root.wins[root.winSel]) : root.accept();
        }
    }

    readonly property var highlighted: {
        if (!root.shown) return null;
        const i = root.sel;
        if (i < 0) return null;
        return root.results[i] || null;
    }

    onHighlightedChanged: Running.query = root.highlighted

    readonly property string home: Quickshell.env("HOME")
    readonly property string calcScript: home + "/.config/hypr/scripts/calc.py"
    readonly property string calcHistPath: home + "/.local/share/rofi-calc-history"

    readonly property bool calcMode: {
        const q = search.text.trim();
        if (q.startsWith("="))
            return true;
        if (q.length < 3)
            return false;
        if (!/^[\d(.]/.test(q))
            return false;
        return /[+\-*\/^%]/.test(q.slice(1));
    }

    readonly property string calcExpr: {
        const q = search.text.trim();
        return q.startsWith("=") ? q.slice(1).trim() : q;
    }

    property string calcResult: ""

    readonly property bool runMode: search.text.startsWith(">")
    readonly property string runCmd: search.text.slice(1).trim()

    function runAccept() {
        if (root.runCmd === "")
            return;
        Quickshell.execDetached(["sh", "-c", root.runCmd]);
        Sfx.tapAlt();
        root.close();
    }

    onCalcExprChanged: {
        if (root.calcMode)
            calcDebounce.restart();
        else
            root.calcResult = "";
    }

    Timer {
        id: calcDebounce
        interval: 90
        onTriggered: root.calcRun()
    }

    Process {
        id: calcProc
        stdout: StdioCollector {
            onStreamFinished: root.calcResult = text.trim()
        }
    }

    function calcRun() {
        root.calcResult = "";
        if (!root.calcMode || root.calcExpr === "")
            return;
        calcProc.running = false;
        calcProc.command = [root.calcScript, root.calcExpr];
        calcProc.running = true;
    }

    FileView {
        id: calcHistFile
        path: root.calcHistPath
        watchChanges: true
        onFileChanged: reload()
    }

    readonly property var calcHistory: {
        let raw = "";
        try {
            raw = calcHistFile.text();
        } catch (e) {
            return [];
        }

        const out = [];
        const seen = ({});
        const lines = raw.split("\n");
        for (let i = lines.length - 1; i >= 0 && out.length < 12; i--) {
            const line = lines[i].trim();
            if (line === "" || seen[line] === true)
                continue;
            seen[line] = true;
            out.push(line);
        }
        return out;
    }

    Process { id: calcCommit }

    function calcAccept() {
        if (root.calcResult === "")
            return;

        calcCommit.running = false;
        calcCommit.command = [
            "sh", "-c",
            'printf %s "$1" | wl-copy; '
            + 'printf "%s = %s\\n" "$2" "$1" >> "$3"; '
            + 'tail -n 200 "$3" > "$3.tmp" && mv "$3.tmp" "$3"; '
            + 'notify-send -a "$4" "$2 = $1" "$5" 2>/dev/null',
            "calc", root.calcResult, root.calcExpr, root.calcHistPath,
            I18n.t("launcher.calc"), I18n.t("clip.copied")
        ];
        calcCommit.running = true;
        root.close();
    }

    function accept() {
        if (root.runMode)
            root.runAccept();
        else if (root.calcMode)
            root.calcAccept();
        else
            root.launch(root.results[root.sel]);
    }

    function useCount(entry) {
        return entry ? Frecency.score(entry.id) : 0;
    }

    readonly property var results: {
        if (root.runMode)
            return [];
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        const q = search.text.toLowerCase().trim();

        if (q === "") {
            return all.slice().sort((a, b) => {
                const d = root.useCount(b) - root.useCount(a);
                return d !== 0 ? d : a.name.localeCompare(b.name);
            }).slice(0, 40);
        }

        const scored = [];
        for (const e of all) {
            const name = (e.name || "").toLowerCase();
            const gen = (e.genericName || "").toLowerCase();
            const cmt = (e.comment || "").toLowerCase();
            let score = -1;
            if (name.startsWith(q)) score = 0;
            else if (name.includes(q)) score = 1;
            else if (gen.includes(q)) score = 2;
            else if (cmt.includes(q)) score = 3;
            if (score >= 0) scored.push({ entry: e, score: score });
        }
        scored.sort((a, b) => a.score - b.score
                              || root.useCount(b.entry) - root.useCount(a.entry)
                              || a.entry.name.localeCompare(b.entry.name));
        return scored.map(s => s.entry).slice(0, 40);
    }

    readonly property var favourites: {
        if (root.calcMode || root.runMode)
            return [];
        const all = DesktopEntries.applications.values.filter(e => !e.noDisplay);
        return all.slice()
            .sort((a, b) => root.useCount(b) - root.useCount(a))
            .filter(e => root.useCount(e) > 0)
            .slice(0, 6);
    }

    readonly property bool showFavourites:
        search.text === "" && root.favourites.length > 2

    function launch(entry) {
        if (!entry) return;
        Sfx.tapAlt();

        if (root.drip && root.shown) {
            const at = root.results.indexOf(entry);
            drops.fly(Math.max(0, at - drops.off), {
                name: entry.name || "",
                icon: drops.iconOf(entry),
                hue: drops.hue,
                id: entry.id || "",
                startupClass: entry.startupClass || "",
                running: Running.query === entry && Running.any
            });
        }
        root.close();

        Frecency.bump(entry.id);

        entry.execute();
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-launcher"
        id: win
        screen: Focus.screen
        visible: root.shown || drops.living
        focusable: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusiveZone: -1
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? (root.drip ? 0.16 : Prefs.apple ? 0.12 : 0.35) : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Emerge {
            id: emerge
            card: card
            win: win
            open: root.shown && !root.drip
            dock: true
            cornerTo: 30
        }

        Item {
            id: inputHost
            width: 200
            height: 20
            opacity: 0
                        TextInput {
                            id: search
                            parent: root.drip ? inputHost : searchSlot
                            anchors.fill: parent
                            verticalAlignment: TextInput.AlignVCenter
                            color: Colors.fg
                            font.family: Fonts.mono
                            font.pixelSize: 14
                            clip: true
                            selectByMouse: true
                            selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                    Colors.accent.b, 0.35)

                            onTextChanged: root.sel = 0

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: I18n.t("launcher.placeholder")
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.5)
                                font: search.font
                            }

                            Keys.onEscapePressed: {
                                if (root.winsOpen)
                                    root.winsOpen = false;
                                else
                                    root.close();
                            }
                            Keys.onDownPressed: root.move(1)
                            Keys.onUpPressed: root.move(-1)
                            Keys.onRightPressed: (event) => {
                                if (root.winsOpen || search.cursorPosition < search.text.length
                                    || !root.openWins())
                                    event.accepted = false;
                            }
                            Keys.onLeftPressed: (event) => {
                                if (root.winsOpen)
                                    root.winsOpen = false;
                                else
                                    event.accepted = false;
                            }
                            Keys.onReturnPressed: root.winsOpen ? root.focusWin(root.wins[root.winSel]) : root.accept()
                            Keys.onEnterPressed: root.winsOpen ? root.focusWin(root.wins[root.winSel]) : root.accept()
                        }

        }

        LauncherDrip {
            id: drops
            anchors.fill: parent
            l: root
            open: root.shown && root.drip
            visible: root.drip
        }

        Item {
            id: card
            visible: !root.drip
            anchors.horizontalCenter: parent.horizontalCenter
            y: Prefs.apple ? (Prefs.barAtTop ? BarConfig.reserved(win.screen ? win.screen.name : "") : 0) + 8
                          : parent.height * 0.15
            width: Prefs.apple ? 560 : 660
            height: Prefs.apple ? 430 : 500

            opacity: emerge.on ? emerge.cardOpacity : (root.shown ? 1 : 0)
            scale: emerge.on ? 1 : (root.shown ? 1 : 0.94)
            transform: Translate {
                x: emerge.dx
                y: emerge.on ? emerge.dy : (root.shown ? 0 : 24)
                Behavior on y {
                    enabled: !emerge.on
                    NumberAnimation {
                        duration: Motion.slow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.expo
                    }
                }
            }

            Behavior on opacity { enabled: !emerge.on; NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                enabled: !emerge.on
                SpringAnimation {
                    spring: Motion.panelSpring
                    damping: Motion.panelDamping
                    mass: Motion.panelMass
                    epsilon: 0.001
                }
            }

            Bloom { target: card }

            Glass {
                z: -1
                anchors.fill: parent
                radius: Prefs.apple ? 30 : Shape.modal
                elevation: 3
                tint: Colors.bg
                tintOpacity: 0.90
                edge: Colors.accent
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Rectangle {
                    width: parent.width
                    height: 50
                    radius: Shape.field
                    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
                    border.width: 1
                    border.color: search.activeFocus
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.55)
                        : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                  Colors.outline.b, 0.14)
                    Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                    Rectangle {
                        z: -1
                        anchors.centerIn: parent
                        width: parent.width + 10
                        height: parent.height + 10
                        radius: parent.radius + 5
                        color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.5)
                        opacity: search.activeFocus ? 0.22 : 0
                        Behavior on opacity { NumberAnimation { duration: Motion.slow } }

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            blurEnabled: true
                            blur: 1.0
                            blurMax: 40
                        }
                    }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Text {
                            text: root.runMode ? "󰞷" : root.calcMode ? "󰃬" : "󰍉"
                            color: Colors.accent
                            font.family: Fonts.mono
                            font.pixelSize: 17
                            anchors.verticalCenter: parent.verticalCenter

                            rotation: root.calcMode ? 360 : 0
                            Behavior on rotation {
                                NumberAnimation {
                                    duration: Motion.slow
                                    easing.type: Easing.Bezier
                                    easing.bezierCurve: Motion.expo
                                }
                            }
                        }

                        Item {
                            id: searchSlot
                            width: parent.width - 130
                            height: 22
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: modeLabel.implicitWidth + 18
                            height: 22
                            radius: Shape.detail
                            antialiasing: true
                            color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                           Colors.accent.b,
                                           root.calcMode || root.runMode ? 0.20 : 0.08)
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            Text {
                                id: modeLabel
                                anchors.centerIn: parent
                                text: root.runMode ? I18n.t("launcher.keyRun")
                                    : root.calcMode ? I18n.t("launcher.keyCalc")
                                    : I18n.t("act.open")
                                color: root.calcMode || root.runMode
                                    ? Colors.accent : Colors.fgDim
                                opacity: root.calcMode || root.runMode ? 1 : 0.7
                                font.family: Fonts.mono
                                font.pixelSize: 9
                                font.letterSpacing: 1
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - 60
                    visible: root.calcMode

                    Column {
                        anchors.fill: parent
                        spacing: 14

                        Rectangle {
                            width: parent.width
                            height: 116
                            radius: Shape.field
                            color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                           Colors.accent.b, 0.10)
                            border.width: 1
                            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                  Colors.accent.b,
                                                  root.calcResult !== "" ? 0.38 : 0.14)
                            Behavior on border.color { ColorAnimation { duration: Motion.base } }

                            Sheen {
                                anchors.fill: parent
                                radius: Shape.field
                                border: false
                                grainOpacity: 0.025
                            }

                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 44
                                spacing: 6

                                Text {
                                    width: parent.width
                                    text: root.calcExpr
                                    color: Colors.fgDim
                                    opacity: 0.7
                                    font.family: Fonts.mono
                                    font.pixelSize: 13
                                    elide: Text.ElideLeft
                                    horizontalAlignment: Text.AlignRight
                                }

                                Text {
                                    id: resultText
                                    width: parent.width
                                    text: root.calcResult !== "" ? root.calcResult : "—"
                                    color: root.calcResult !== "" ? Colors.accent : Colors.fgDim
                                    opacity: root.calcResult !== "" ? 1 : 0.35
                                    font.family: Fonts.mono
                                    font.pixelSize: 34
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideLeft
                                    horizontalAlignment: Text.AlignRight

                                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                                    scale: 1
                                    onTextChanged: if (root.calcResult !== "") pop.restart()
                                    SequentialAnimation {
                                        id: pop
                                        NumberAnimation {
                                            target: resultText; property: "scale"
                                            from: 0.94; to: 1.02
                                            duration: Motion.fast
                                        }
                                        NumberAnimation {
                                            target: resultText; property: "scale"; to: 1
                                            duration: Motion.fast
                                        }
                                    }
                                }

                                Text {
                                    width: parent.width
                                    text: root.calcResult !== ""
                                        ? I18n.t("launcher.copied")
                                        : I18n.t("launcher.incomplete")
                                    color: Colors.fgDim
                                    opacity: 0.45
                                    font.family: Fonts.mono
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }

                        Text {
                            text: I18n.t("notif.history")
                            color: Colors.fgDim
                            opacity: 0.4
                            font.family: Fonts.mono
                            font.pixelSize: 9
                            visible: root.calcHistory.length > 0
                        }

                        ListView {
                            id: histList
                            width: parent.width
                            height: parent.height - 160
                            clip: true
                            spacing: 2
                            model: root.calcHistory
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: histList.width
                                height: 30
                                radius: Shape.chip
                                color: histHover.hovered
                                    ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                              Colors.bgAlt.b, 0.55)
                                    : "transparent"
                                Behavior on color { ColorAnimation { duration: Motion.fast } }

                                HoverHandler { id: histHover }
                                TapHandler {
                                    onTapped: search.text = "=" + String(modelData).split(" = ")[0]
                                }

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 20
                                    text: modelData
                                    color: Colors.fgDim
                                    opacity: histHover.hovered ? 0.9 : 0.55
                                    font.family: Fonts.mono
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - 60
                    visible: root.runMode

                    Column {
                        anchors.top: parent.top
                        anchors.topMargin: 18
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: parent.width - 32
                        spacing: 12

                        Rectangle {
                            width: parent.width
                            height: 54
                            radius: Shape.chip
                            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                           Colors.bgAlt.b, 0.55)
                            border.width: 1
                            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                  Colors.accent.b, 0.35)

                            Text {
                                anchors.left: parent.left
                                anchors.leftMargin: 14
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 28
                                text: root.runCmd === "" ? I18n.t("launcher.runHint") : "$ " + root.runCmd
                                color: root.runCmd === "" ? Colors.fgDim : Colors.fg
                                opacity: root.runCmd === "" ? 0.5 : 1
                                elide: Text.ElideRight
                                font.family: Fonts.mono
                                font.pixelSize: 13
                            }
                        }

                        Text {
                            text: I18n.t("launcher.runKeys")
                            color: Colors.fgDim
                            opacity: 0.45
                            font.family: Fonts.mono
                            font.pixelSize: 10
                        }
                    }
                }

                Item {
                    id: quick

                    width: parent.width
                    height: root.showFavourites ? 66 : 0
                    visible: height > 1
                    clip: true

                    Behavior on height {
                        NumberAnimation {
                            duration: Motion.base
                            easing.type: Easing.Bezier
                            easing.bezierCurve: Motion.decel
                        }
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Repeater {
                            model: root.favourites

                            Rectangle {
                                id: fav

                                required property var modelData
                                required property int index

                                width: 58
                                height: 58
                                radius: Shape.field
                                antialiasing: true

                                color: favArea.containsMouse
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                              Colors.accent.b, 0.20)
                                    : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                              Colors.bgAlt.b, 0.45)
                                border.width: 1
                                border.color: favArea.containsMouse
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                              Colors.accent.b, 0.45)
                                    : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                              Colors.outline.b, 0.12)

                                Behavior on color { ColorAnimation { duration: Motion.fast } }
                                Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                                scale: favArea.pressed ? 0.94
                                     : (favArea.containsMouse ? 1.06 : 1)
                                Behavior on scale {
                                    SpringAnimation {
                                        spring: Motion.tapSpring
                                        damping: Motion.tapDamping
                                        mass: Motion.tapMass
                                        epsilon: 0.001
                                    }
                                }

                                IconImage {
                                    anchors.centerIn: parent
                                    source: Quickshell.iconPath(fav.modelData.icon,
                                                                "application-x-executable")
                                    implicitSize: 30
                                }

                                MouseArea {
                                    id: favArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.launch(fav.modelData)
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - 60 - (quick.visible ? quick.height + 14 : 0)
                            - (foot.visible ? foot.height + 14 : 0)
                    clip: true
                    visible: !root.calcMode && !root.runMode
                    model: root.calcMode || root.runMode ? [] : root.results
                    spacing: 3
                    currentIndex: root.sel
                    onCurrentIndexChanged: if (currentIndex >= 0 && root.sel !== currentIndex) root.sel = currentIndex
                    highlightMoveDuration: 160
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: appRow
                        required property var modelData
                        required property int index

                        width: list.width
                        height: 56
                        radius: Shape.field
                        antialiasing: true
                        color: "transparent"
                        border.width: Prefs.apple ? 0 : 1
                        border.color: index === list.currentIndex
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.32)
                            : "transparent"
                        readonly property bool on: index === list.currentIndex
                        Behavior on color { ColorAnimation { duration: Motion.fast } }
                        Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                        opacity: 0
                        transform: Translate { id: rowSlide; x: 26 }

                        SequentialAnimation {
                            running: true
                            PauseAnimation { duration: Motion.delay(index) }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: rowSlide; property: "x"; to: 0
                                    duration: Motion.slow
                                    easing.type: Easing.Bezier
                                    easing.bezierCurve: Motion.expo
                                }
                                NumberAnimation {
                                    target: appRow; property: "opacity"; to: 1
                                    duration: 240
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            radius: Shape.field
                            antialiasing: true
                            opacity: index === list.currentIndex ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                            Rectangle {
                                anchors.fill: parent
                                visible: Prefs.apple
                                radius: 11
                                antialiasing: true
                                color: Colors.selection
                            }

                            color: "transparent"
                            gradient: Prefs.apple ? null : fadeFill
                            Gradient {
                                id: fadeFill
                                orientation: Gradient.Horizontal
                                GradientStop {
                                    position: 0.0
                                    color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                   Colors.accent.b, 0.26)
                                }
                                GradientStop {
                                    position: 1.0
                                    color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                   Colors.accent.b, 0.05)
                                }
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            radius: 1.5
                            antialiasing: true
                            color: Colors.accent
                            visible: !Prefs.apple
                            height: index === list.currentIndex ? 24 : 0
                            opacity: index === list.currentIndex ? 1 : 0

                            Behavior on height {
                                NumberAnimation {
                                    duration: Motion.base
                                    easing.type: Easing.Bezier
                                    easing.bezierCurve: Motion.snap
                                }
                            }
                            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 12
                            spacing: 13

                            Rectangle {
                                width: 40
                                height: 40
                                radius: Shape.chip
                                antialiasing: true
                                anchors.verticalCenter: parent.verticalCenter
                                color: Prefs.apple ? "transparent"
                                    : index === list.currentIndex
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                              Colors.accent.b, 0.16)
                                    : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                              Colors.fgDim.b, 0.06)
                                Behavior on color { ColorAnimation { duration: 130 } }

                                IconImage {
                                    anchors.centerIn: parent
                                    source: Quickshell.iconPath(modelData.icon,
                                                                "application-x-executable")
                                    implicitSize: 26
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 100
                                spacing: 2

                                Text {
                                    text: modelData.name
                                    color: Prefs.apple && appRow.on ? "white" : Colors.fg
                                    font.family: Fonts.display
                                    font.pixelSize: 14
                                    font.weight: index === list.currentIndex
                                                 ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideRight
                                    width: parent.width
                                }

                                Text {
                                    visible: text !== ""
                                    text: modelData.genericName || modelData.comment || ""
                                    color: Prefs.apple && appRow.on
                                        ? Qt.rgba(1, 1, 1, 0.75)
                                        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                  Colors.fgDim.b, 0.65)
                                    font.family: Fonts.mono
                                    font.pixelSize: Prefs.apple ? 11 : 10
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        Text {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            text: "\u{f0311}"
                            color: Prefs.apple ? "white" : Colors.accent
                            font.family: Fonts.mono
                            font.pixelSize: 13
                            opacity: index === list.currentIndex ? 0.8 : 0
                            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: root.sel = index
                            onClicked: root.launch(modelData)
                        }
                    }
                }

                Item {
                    id: foot
                    width: parent.width
                    height: 16
                    visible: !root.calcMode && !root.runMode

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.results.length + " " + I18n.t("launcher.matches")
                        color: Colors.fgDim
                        opacity: 0.42
                        font.family: Fonts.mono
                        font.pixelSize: 9
                        font.letterSpacing: 1
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Repeater {
                            model: [
                                { k: "\u{f0360}\u{f035d}", v: I18n.t("launcher.keyMove") },
                                { k: "=", v: I18n.t("launcher.keyCalc") },
                                { k: ">", v: I18n.t("launcher.keyRun") }
                            ]

                            Row {
                                required property var modelData
                                spacing: 5

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: keyCap.implicitWidth + 10
                                    height: 15
                                    radius: Shape.detail - 2
                                    antialiasing: true
                                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                   Colors.fgDim.b, 0.08)

                                    Text {
                                        id: keyCap
                                        anchors.centerIn: parent
                                        text: modelData.k
                                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                       Colors.fgDim.b, 0.7)
                                        font.family: Fonts.mono
                                        font.pixelSize: 9
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: modelData.v
                                    color: Colors.fgDim
                                    opacity: 0.4
                                    font.family: Fonts.mono
                                    font.pixelSize: 9
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
