import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import Quickshell.Wayland

Scope {
    id: root

    property bool shown: false

    function toggle() {
        root.shown = !root.shown;
    }

    function close() {
        root.shown = false;
    }

    onShownChanged: {
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

    FileView {
        id: usageFile
        path: Quickshell.statePath("launcher-usage.json")
        blockLoading: true
        watchChanges: false

        onLoadFailed: function () {
            usage.counts = {};
            usageFile.writeAdapter();
        }

        JsonAdapter {
            id: usage
            property var counts: ({})
        }
    }

    function useCount(entry) {
        const c = usage.counts;
        if (!c || !entry) return 0;
        return c[entry.id] || 0;
    }

    readonly property var results: {
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
        root.close();

        const next = Object.assign({}, usage.counts);
        next[entry.id] = (next[entry.id] || 0) + 1;
        usage.counts = next;
        usageFile.writeAdapter();

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
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.95)
            border.width: 1
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                  Colors.accent.b, 0.30)

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 190 } }
            Behavior on scale {
                NumberAnimation { duration: 280; easing.type: Easing.OutBack }
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
                    Behavior on border.color { ColorAnimation { duration: 160 } }

                    Row {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        Text {
                            text: "󰍉"
                            color: Colors.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                            anchors.verticalCenter: parent.verticalCenter
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
                                text: "Search apps…"
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.5)
                                font: search.font
                            }

                            Keys.onEscapePressed: root.close()
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onReturnPressed: root.launch(root.results[list.currentIndex])
                            Keys.onEnterPressed: root.launch(root.results[list.currentIndex])
                        }
                    }
                }

                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - 60
                    clip: true
                    model: root.results
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
                            PauseAnimation { duration: Math.min(index, 12) * 22 }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: rowSlide; property: "x"; to: 0
                                    duration: 300; easing.type: Easing.OutCubic
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
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 13
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
