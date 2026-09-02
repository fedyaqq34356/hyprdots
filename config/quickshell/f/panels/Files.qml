import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property string home: Quickshell.env("HOME")
    readonly property string lister: home + "/.config/hypr/scripts/files-list.sh"

    property string dir: home + "/Pictures"
    property string parentDir: home
    property var entries: []
    property bool loading: false

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (shown) {
            root.load(root.dir);
            grid.forceActiveFocus();
        }
    }

    Process {
        id: lsProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                let payload;
                try {
                    payload = JSON.parse(text);
                } catch (e) {
                    root.entries = [];
                    return;
                }
                root.dir = payload.dir;
                root.parentDir = payload.parent;
                root.entries = payload.entries || [];
                grid.currentIndex = 0;
                grid.positionViewAtBeginning();
            }
        }
    }

    function load(path) {
        root.loading = true;
        lsProc.running = false;
        lsProc.command = [root.lister, path];
        lsProc.running = true;
    }

    Process { id: opener }

    function open(entry) {
        if (!entry)
            return;

        if (entry.type === "dir") {
            root.load(entry.path);
            return;
        }

        opener.running = false;
        opener.command = ["setsid", "-f", "xdg-open", entry.path];
        opener.running = true;
        root.close();
    }

    function goUp() {
        if (root.dir !== "/")
            root.load(root.parentDir);
    }

    readonly property string prettyDir: {
        const d = root.dir;
        return d.startsWith(root.home) ? "~" + d.slice(root.home.length) : d;
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win
        WlrLayershell.namespace: "qs-files"
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.45 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        FocusScope {
            id: shell
            anchors.centerIn: parent
            width: 940
            height: 640
            focus: true

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.95
            transform: Translate { y: root.shown ? 0 : 22
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

            Item {
                anchors.fill: parent
                z: -1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowVerticalOffset: 10
                    shadowOpacity: 0.5
                    shadowColor: "#000000"
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 28
                    color: Colors.bg
                }
            }

            Rectangle {
                id: card
                anchors.fill: parent
                radius: 28
                clip: true

                gradient: Gradient {
                    GradientStop { position: 0.0; color: root.alpha(Colors.bgAlt, 0.96) }
                    GradientStop { position: 0.5; color: root.alpha(Colors.bg, 0.985) }
                    GradientStop { position: 1.0; color: root.alpha(Colors.bg, 0.99) }
                }

                Sheen {
                    anchors.fill: parent
                    radius: 28
                    edge: Colors.accent
                    edgeOpacity: 0.26
                }

                Item {
                    id: header
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    anchors.margins: 20
                    height: 40

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        IconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: "󰁭"
                            tint: Colors.accent
                            mono: root.mono
                            tip: I18n.t("files.up")
                            opacity: root.dir === "/" ? 0.3 : 1
                            onActivated: root.goUp()
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: root.prettyDir
                                color: Colors.fg
                                font.family: root.mono
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: {
                                    if (root.loading)
                                        return I18n.t("state.reading");
                                    const dirs = root.entries.filter(e => e.type === "dir").length;
                                    const files = root.entries.length - dirs;
                                    return dirs + I18n.t("files.dirs") + files + I18n.t("files.files");
                                }
                                color: Colors.fgDim
                                opacity: 0.65
                                font.family: root.mono
                                font.pixelSize: 10
                            }
                        }
                    }

                    IconButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "󰋜"
                        tint: Colors.accent
                        mono: root.mono
                        tip: I18n.t("wall.inPictures")
                        onActivated: root.load(root.home + "/Pictures")
                    }
                }

                GridView {
                    id: grid
                    anchors {
                        top: header.bottom
                        left: parent.left
                        right: parent.right
                        bottom: footer.top
                    }
                    anchors.topMargin: 14
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.bottomMargin: 8

                    clip: true
                    focus: true
                    cellWidth: 172
                    cellHeight: 158
                    model: root.entries
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: 400

                    Keys.onEscapePressed: root.close()
                    Keys.onReturnPressed: root.open(root.entries[grid.currentIndex])
                    Keys.onEnterPressed: root.open(root.entries[grid.currentIndex])
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Backspace) {
                            root.goUp();
                            event.accepted = true;
                        }
                    }

                    delegate: Item {
                        id: tile

                        required property var modelData
                        required property int index

                        readonly property bool isDir: modelData.type === "dir"
                        readonly property bool current: grid.currentIndex === index

                        width: grid.cellWidth - 10
                        height: grid.cellHeight - 10

                        scale: current ? 1.04 : (tileHover.hovered ? 1.02 : 1)
                        Behavior on scale { Spring {} }

                        HoverHandler {
                            id: tileHover
                            onHoveredChanged: if (hovered) grid.currentIndex = tile.index
                        }
                        TapHandler {
                            onTapped: {
                                Sfx.tapAlt();
                                root.open(tile.modelData);
                            }
                        }

                        Rectangle {
                            id: frame
                            anchors.fill: parent
                            radius: 16
                            color: tile.current
                                ? root.alpha(Colors.accent, 0.14)
                                : root.alpha(Colors.bgAlt, 0.45)
                            border.width: 1
                            border.color: tile.current
                                ? root.alpha(Colors.accent, 0.55)
                                : root.alpha(Colors.outline, 0.14)

                            Behavior on color { ColorAnimation { duration: Motion.fast } }
                            Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                            Item {
                                id: shot
                                anchors {
                                    top: parent.top
                                    left: parent.left
                                    right: parent.right
                                }
                                anchors.margins: 8
                                height: parent.height - 40
                                clip: true

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 10
                                    color: root.alpha(Colors.bg, 0.55)
                                    visible: tile.isDir || thumb.status !== Image.Ready
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: tile.isDir
                                    text: "󰉋"
                                    color: Colors.accent
                                    opacity: 0.85
                                    font.family: root.mono
                                    font.pixelSize: 40
                                }

                                Image {
                                    id: thumb
                                    anchors.fill: parent
                                    visible: !tile.isDir && status === Image.Ready
                                    source: tile.isDir ? "" : "file://" + tile.modelData.thumb
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    sourceSize.width: 320
                                    sourceSize.height: 320

                                    opacity: status === Image.Ready ? 1 : 0
                                    Behavior on opacity {
                                        NumberAnimation { duration: Motion.base }
                                    }

                                    layer.enabled: true
                                    layer.effect: MultiEffect {
                                        maskEnabled: true
                                        maskSource: thumbMask
                                    }
                                }

                                Rectangle {
                                    id: thumbMask
                                    anchors.fill: parent
                                    radius: 10
                                    color: "black"
                                    visible: false
                                    layer.enabled: true
                                }
                            }

                            Text {
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    bottom: parent.bottom
                                }
                                anchors.margins: 10
                                anchors.bottomMargin: 9
                                text: tile.modelData.name
                                color: tile.current ? Colors.fg : Colors.fgDim
                                opacity: tile.current ? 1 : 0.75
                                font.family: root.mono
                                font.pixelSize: 9
                                font.weight: tile.current ? Font.DemiBold : Font.Normal
                                elide: Text.ElideMiddle
                                horizontalAlignment: Text.AlignHCenter
                            }
                        }
                    }
                }

                Column {
                    anchors.centerIn: grid
                    spacing: 10
                    visible: !root.loading && root.entries.length === 0

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "󰉖"
                        color: Colors.fgDim
                        opacity: 0.3
                        font.family: root.mono
                        font.pixelSize: 48
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: I18n.t("wall.nothing")
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: root.mono
                        font.pixelSize: 12
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: I18n.t("files.empty")
                        color: Colors.fgDim
                        opacity: 0.45
                        font.family: root.mono
                        font.pixelSize: 9
                    }
                }

                Item {
                    id: footer
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    anchors.margins: 14
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: {
                            const e = root.entries[grid.currentIndex];
                            return e ? e.name : "";
                        }
                        color: Colors.fgDim
                        opacity: 0.5
                        font.family: root.mono
                        font.pixelSize: 9
                        elide: Text.ElideMiddle
                        width: parent.width - 240
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.t("files.keys")
                        color: Colors.fgDim
                        opacity: 0.45
                        font.family: root.mono
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}
