import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import QtQuick
import Quickshell.Wayland

Scope {
    id: root

    property bool shown: false
    property var files: []
    property string current: ""

    readonly property string dir: Quickshell.env("HOME") + "/Pictures/Wallpapers"
    readonly property string thumbDir: Quickshell.env("HOME") + "/.cache/wallpaper-thumbs"

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
            grid.currentIndex = 0;
            search.forceActiveFocus();
        }
    }

    function baseName(p) {
        return p.substring(p.lastIndexOf("/") + 1);
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
            "'scale=300:200:force_original_aspect_ratio=increase,crop=300:200' " +
            "-vframes 1 \"$t\" -y -loglevel quiet 2>/dev/null; done"]
    }

    Process { id: setter }

    function apply(path) {
        if (!path)
            return;
        root.close();
        root.current = path;
        setter.command = [Quickshell.env("HOME") + "/.config/hypr/scripts/set-wallpaper.sh", path];
        setter.running = true;
    }

    function shuffle() {
        if (root.files.length === 0)
            return;
        apply(root.files[Math.floor(Math.random() * root.files.length)]);
    }

    readonly property var results: {
        const q = search.text.toLowerCase().trim();
        if (q === "")
            return root.files;
        return root.files.filter(f => root.baseName(f).toLowerCase().includes(q));
    }

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
            opacity: root.shown ? 0.42 : 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Rectangle {
            id: card
            anchors.centerIn: parent
            width: 940
            height: 640
            radius: 24
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96)
            border.width: 1
            border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                  Colors.accent.b, 0.30)

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 190 } }
            Behavior on scale {
                NumberAnimation { duration: 300; easing.type: Easing.OutBack }
            }

            Column {
                anchors.fill: parent
                anchors.margins: 22
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
                            text: "󰸉"
                            color: Colors.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: search
                            width: parent.width - 160
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.fg
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 14
                            clip: true
                            selectByMouse: true
                            selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                    Colors.accent.b, 0.35)

                            onTextChanged: grid.currentIndex = 0

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: root.results.length + " wallpapers…"
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.5)
                                font: search.font
                            }

                            Keys.onEscapePressed: root.close()
                            Keys.onLeftPressed: grid.moveCurrentIndexLeft()
                            Keys.onRightPressed: grid.moveCurrentIndexRight()
                            Keys.onUpPressed: grid.moveCurrentIndexUp()
                            Keys.onDownPressed: grid.moveCurrentIndexDown()
                            Keys.onReturnPressed: root.apply(root.results[grid.currentIndex])
                            Keys.onEnterPressed: root.apply(root.results[grid.currentIndex])
                        }

                        Rectangle {
                            width: 86
                            height: 26
                            radius: 8
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

                GridView {
                    id: grid
                    width: parent.width
                    height: parent.height - 60
                    clip: true
                    model: root.results
                    cellWidth: Math.floor(width / 4)
                    cellHeight: Math.floor(cellWidth * 0.68)
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: 800

                    delegate: Item {
                        id: cell
                        required property var modelData
                        required property int index

                        width: grid.cellWidth
                        height: grid.cellHeight

                        readonly property bool isCurrent: modelData === root.current

                        Rectangle {
                            id: tile
                            anchors.fill: parent
                            anchors.margins: 6
                            radius: 14
                            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                           Colors.bgAlt.b, 0.35)
                            border.width: cell.isCurrent ? 2
                                        : (index === grid.currentIndex ? 2 : 1)
                            border.color: cell.isCurrent
                                ? Colors.accent
                                : (index === grid.currentIndex
                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                              Colors.accent.b, 0.55)
                                    : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                              Colors.outline.b, 0.25))
                            clip: true

                            scale: tileArea.containsMouse ? 1.05 : 1.0
                            Behavior on scale {
                                NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                            }
                            Behavior on border.color { ColorAnimation { duration: 150 } }

                            Image {
                                anchors.fill: parent
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 400
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
                                height: 24
                                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.82)

                                Text {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 8
                                    verticalAlignment: Text.AlignVCenter
                                    text: root.baseName(cell.modelData)
                                    color: cell.isCurrent ? Colors.accent : Colors.fgDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    elide: Text.ElideMiddle
                                }
                            }

                            Rectangle {
                                visible: cell.isCurrent
                                anchors.top: parent.top
                                anchors.right: parent.right
                                anchors.margins: 6
                                width: 20
                                height: 20
                                radius: 10
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
                }
            }
        }
    }
}
