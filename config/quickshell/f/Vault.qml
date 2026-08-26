import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

// Bitwarden vault picker, backed by the rbw client.
//
// Passwords are never rendered. The panel lists entry names and usernames,
// and the only thing it does with a secret is hand it to wl-copy, which then
// wipes itself after a delay. That keeps the panel safe to open on a shared
// screen and keeps the secret out of the QML scene graph entirely.
//
// Like SysRings, everything lives inside an inactive Loader: closed means no
// window, no process, no vault data in memory.
Scope {
    id: root

    property bool shown: false

    // Seconds before the clipboard is cleared after a copy.
    readonly property int clearAfter: 30

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    Loader {
        active: root.shown

        sourceComponent: Component {
            PanelWindow {
                id: win
                WlrLayershell.namespace: "qs-vault"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
                screen: Focus.screen

                anchors { top: true; bottom: true; left: true; right: true }
                exclusiveZone: 0
                color: "transparent"

                // --- state ---------------------------------------------------

                property bool locked: true
                property bool busy: false
                property string status: ""
                property var entries: []
                property int selected: 0

                readonly property var filtered: {
                    const q = search.text.trim().toLowerCase();
                    if (q === "") return win.entries;
                    return win.entries.filter(function (e) {
                        return e.name.toLowerCase().indexOf(q) !== -1
                            || e.user.toLowerCase().indexOf(q) !== -1
                            || e.folder.toLowerCase().indexOf(q) !== -1;
                    });
                }

                onFilteredChanged: win.selected = 0

                // --- rbw -----------------------------------------------------

                Process {
                    id: unlockedCheck
                    command: ["rbw", "unlocked"]
                    onExited: function (code) {
                        win.locked = code !== 0;
                        if (!win.locked)
                            listProc.running = true;
                        else
                            win.status = "хранилище заперто";
                    }
                }

                Process {
                    id: unlockProc
                    command: ["rbw", "unlock"]
                    onExited: function (code) {
                        win.busy = false;
                        if (code === 0) {
                            win.locked = false;
                            win.status = "";
                            listProc.running = true;
                        } else {
                            win.status = "разблокировать не вышло";
                        }
                    }
                }

                Process {
                    id: listProc
                    // Tab separated: entry names routinely contain spaces.
                    command: ["rbw", "list", "--fields", "folder,name,user"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            const out = [];
                            for (const line of text.split("\n")) {
                                if (line.trim() === "") continue;
                                const parts = line.split("\t");
                                out.push({
                                    folder: parts[0] || "",
                                    name:   parts[1] || "",
                                    user:   parts[2] || ""
                                });
                            }
                            win.entries = out;
                            win.status = out.length === 0
                                ? "хранилище пусто" : "";
                        }
                    }

                    onExited: function (code) {
                        if (code !== 0)
                            win.status = "rbw list вернул ошибку";
                    }
                }

                // Copy is a shell pipeline so the secret goes straight from rbw
                // into wl-copy and never passes through this process.
                Process { id: copyProc }
                Process { id: clearProc }

                function copyEntry(entry) {
                    if (!entry) return;

                    const name = entry.name.replace(/'/g, "'\\''");
                    const user = entry.user.replace(/'/g, "'\\''");
                    const target = user === ""
                        ? "rbw get -- '" + name + "'"
                        : "rbw get -- '" + name + "' '" + user + "'";

                    copyProc.running = false;
                    copyProc.command = ["sh", "-c", target + " | wl-copy -n"];
                    copyProc.running = true;

                    // Wipe it again shortly afterwards. wl-copy --clear rather
                    // than copying an empty string, so no stray entry is left
                    // in the clipboard history.
                    clearProc.running = false;
                    clearProc.command = ["sh", "-c",
                        "sleep " + root.clearAfter + "; wl-copy --clear"];
                    clearProc.running = true;

                    root.close();
                }

                Component.onCompleted: {
                    unlockedCheck.running = true;
                    search.forceActiveFocus();
                }

                // --- chrome ---------------------------------------------------

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: 0.35
                }

                Rectangle {
                    id: card
                    anchors.centerIn: parent
                    width: 520
                    height: 440
                    radius: 22

                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96)
                    border.width: 1
                    border.color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.30)

                    MouseArea { anchors.fill: parent }

                    opacity: root.shown ? 1 : 0
                    scale: root.shown ? 1 : 0.94
                    Behavior on opacity { NumberAnimation { duration: 180 } }
                    Behavior on scale {
                        NumberAnimation { duration: 300; easing.type: Easing.OutBack }
                    }

                    Column {
                        anchors.fill: parent
                        anchors.margins: 20
                        spacing: 14

                        Row {
                            width: parent.width
                            spacing: 10

                            Text {
                                text: "󰌾"
                                color: Colors.accent
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 16
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: "Bitwarden"
                                color: Colors.fg
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: win.status
                                color: Colors.warn
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // Search box
                        Rectangle {
                            width: parent.width
                            height: 38
                            radius: 12
                            color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                           Colors.bgAlt.b, 0.55)
                            border.width: 1
                            border.color: search.activeFocus
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.55)
                                : "transparent"
                            Behavior on border.color { ColorAnimation { duration: 160 } }

                            TextInput {
                                id: search
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                verticalAlignment: TextInput.AlignVCenter
                                color: Colors.fg
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                clip: true
                                enabled: !win.locked

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: search.text === ""
                                    text: win.locked ? "Enter — разблокировать"
                                                     : "поиск по записям"
                                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                   Colors.fgDim.b, 0.45)
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                }

                                Keys.onEscapePressed: root.close()

                                Keys.onDownPressed:
                                    win.selected = Math.min(win.filtered.length - 1,
                                                            win.selected + 1)
                                Keys.onUpPressed:
                                    win.selected = Math.max(0, win.selected - 1)

                                Keys.onReturnPressed: {
                                    if (win.locked) {
                                        win.busy = true;
                                        win.status = "жду pinentry…";
                                        unlockProc.running = true;
                                        return;
                                    }
                                    win.copyEntry(win.filtered[win.selected]);
                                }
                            }
                        }

                        // Entry list
                        ListView {
                            id: list
                            width: parent.width
                            height: parent.height - 110
                            clip: true
                            model: win.filtered
                            currentIndex: win.selected
                            highlightMoveDuration: 140
                            boundsBehavior: Flickable.StopAtBounds

                            delegate: Rectangle {
                                required property var modelData
                                required property int index

                                width: list.width
                                height: 46
                                radius: 10
                                color: index === win.selected
                                    ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                              Colors.bgAlt.b, 0.7)
                                    : "transparent"
                                Behavior on color { ColorAnimation { duration: 120 } }

                                Column {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: modelData.name
                                        color: Colors.fg
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    Text {
                                        visible: text !== ""
                                        text: modelData.user
                                            + (modelData.folder === "" ? ""
                                               : "   ·   " + modelData.folder)
                                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                       Colors.fgDim.b, 0.6)
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 10
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: index === win.selected
                                    text: "копировать ⏎"
                                    color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                   Colors.accent.b, 0.75)
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        win.selected = index;
                                        win.copyEntry(modelData);
                                    }
                                }
                            }
                        }

                        Text {
                            width: parent.width
                            horizontalAlignment: Text.AlignHCenter
                            text: "пароль уходит прямо в буфер и стирается через "
                                  + root.clearAfter + " с"
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.45)
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 9
                        }
                    }
                }
            }
        }
    }
}
