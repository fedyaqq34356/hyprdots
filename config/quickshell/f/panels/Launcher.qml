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
        if (shown) {
            search.text = "";
            list.currentIndex = 0;
            search.forceActiveFocus();
        } else {
            Running.query = null;
        }
    }

    readonly property var highlighted: {
        if (!root.shown) return null;
        const i = list.currentIndex;
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
            root.launch(root.results[list.currentIndex]);
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

    function launch(entry) {
        if (!entry) return;
        Sfx.tapAlt();
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
        visible: root.shown
        focusable: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.35 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.16
            width: 620
            height: 460
            radius: 22
            color: "transparent"

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            transform: Translate { y: root.shown ? 0 : 24
                Behavior on y {
                    NumberAnimation {
                        duration: Motion.slow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.expo
                    }
                }
            }

            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                SpringAnimation {
                    spring: Motion.panelSpring
                    damping: Motion.panelDamping
                    mass: Motion.panelMass
                    epsilon: 0.001
                }
            }

            Glass {
                z: -1
                anchors.fill: parent
                radius: 22
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
                    height: 46
                    radius: 13
                    color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
                    border.width: 1
                    border.color: search.activeFocus
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.55)
                        : "transparent"
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
                            font.family: "JetBrainsMono Nerd Font"
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

                        TextInput {
                            id: search
                            width: parent.width - 50
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            clip: true
                            selectByMouse: true
                            selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                    Colors.accent.b, 0.35)

                            onTextChanged: list.currentIndex = 0

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: I18n.t("launcher.placeholder")
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.5)
                                font: search.font
                            }

                            Keys.onEscapePressed: root.close()
                            Keys.onDownPressed: if (!root.calcMode) list.incrementCurrentIndex()
                            Keys.onUpPressed: if (!root.calcMode) list.decrementCurrentIndex()
                            Keys.onReturnPressed: root.accept()
                            Keys.onEnterPressed: root.accept()
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
                            radius: 18
                            color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                           Colors.accent.b, 0.10)
                            border.width: 1
                            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                  Colors.accent.b,
                                                  root.calcResult !== "" ? 0.38 : 0.14)
                            Behavior on border.color { ColorAnimation { duration: Motion.base } }

                            Sheen {
                                anchors.fill: parent
                                radius: 18
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
                                    font.family: "JetBrainsMono Nerd Font"
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
                                    font.family: "JetBrainsMono Nerd Font"
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
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    horizontalAlignment: Text.AlignRight
                                }
                            }
                        }

                        Text {
                            text: I18n.t("notif.history")
                            color: Colors.fgDim
                            opacity: 0.4
                            font.family: "JetBrainsMono Nerd Font"
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
                                radius: 10
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
                                    font.family: "JetBrainsMono Nerd Font"
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
                            radius: 14
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
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                            }
                        }

                        Text {
                            text: I18n.t("launcher.runKeys")
                            color: Colors.fgDim
                            opacity: 0.45
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 10
                        }
                    }
                }

                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - 60
                    clip: true
                    visible: !root.calcMode && !root.runMode
                    model: root.calcMode || root.runMode ? [] : root.results
                    spacing: 3
                    currentIndex: 0
                    highlightMoveDuration: 160
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: appRow
                        required property var modelData
                        required property int index

                        width: list.width
                        height: 50
                        radius: 12
                        color: index === list.currentIndex
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 130 } }

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

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 13

                            IconImage {
                                source: Quickshell.iconPath(modelData.icon,
                                                            "application-x-executable")
                                implicitSize: 30
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 60
                                spacing: 1

                                Text {
                                    text: modelData.name
                                    color: Colors.fg
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
                                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                   Colors.fgDim.b, 0.65)
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    elide: Text.ElideRight
                                    width: parent.width
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                            onEntered: list.currentIndex = index
                            onClicked: root.launch(modelData)
                        }
                    }
                }
            }
        }
    }
}
