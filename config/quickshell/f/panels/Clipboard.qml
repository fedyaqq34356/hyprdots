import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import Quickshell.Wayland
import "root:/design"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property var entries: []

    readonly property string previewDir:
        Quickshell.env("XDG_RUNTIME_DIR") + "/cliphist-preview"

    function toggle() {
        if (shown) {
            close();
        } else {
            lister.running = true;
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
            list.currentIndex = 0;
            search.forceActiveFocus();
        }
    }

    Process {
        id: lister
        command: ["cliphist", "list"]

        stdout: StdioCollector {
            onStreamFinished: {
                const out = [];
                const imageIds = [];
                for (const line of this.text.split("\n")) {
                    if (line.trim() === "")
                        continue;
                    const tab = line.indexOf("\t");
                    if (tab < 0)
                        continue;
                    const id = line.substring(0, tab);
                    const body = line.substring(tab + 1);
                    const isImage = body.startsWith("[[ binary data");
                    if (isImage)
                        imageIds.push(id);

                    let label = body;
                    let meta = "";
                    if (isImage) {
                        const m = body.match(/binary data (.+?) (\w+) (\d+x\d+)/);
                        if (m) {
                            label = m[2].toUpperCase() + "  " + m[3].replace("x", " × ");
                            meta = m[1];
                        } else {
                            label = "Image";
                        }
                    } else {
                        const oneLine = body.replace(/\s+/g, " ").trim();
                        label = oneLine;
                        meta = oneLine.length > 60 ? oneLine.length + " chars" : "";
                    }

                    out.push({
                        id: id,
                        body: body,
                        isImage: isImage,
                        isLink: !isImage && /^https?:\/\//.test(body.trim()),
                        label: label,
                        meta: meta
                    });
                }
                root.entries = out;
                if (imageIds.length > 0) {
                    decoder.command = ["sh", "-c",
                        "mkdir -p '" + root.previewDir + "'; for i in " +
                        imageIds.slice(0, 30).join(" ") +
                        "; do [ -f '" + root.previewDir + "'/$i ] || " +
                        "cliphist decode $i > '" + root.previewDir + "'/$i 2>/dev/null; done"];
                    decoder.running = true;
                }
            }
        }
    }

    Process { id: decoder }

    Process { id: copier }

    function copyEntry(entry) {
        if (!entry)
            return;
        Sfx.tapAlt();
        root.close();
        copier.command = ["sh", "-c",
                          "cliphist decode " + entry.id + " | wl-copy"];
        copier.running = true;
    }

    function wipe() {
        root.close();
        copier.command = ["cliphist", "wipe"];
        copier.running = true;
        root.entries = [];
    }

    readonly property var results: {
        const q = search.text.toLowerCase().trim();
        if (q === "")
            return root.entries.slice(0, 60);
        return root.entries.filter(e => e.body.toLowerCase().includes(q))
                           .slice(0, 60);
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-clipboard"
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
            y: parent.height * 0.14
            width: 640
            height: 500
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
                spacing: 12

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
                            text: "󰅇"
                            color: Colors.accent
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 17
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        TextInput {
                            id: search
                            width: parent.width - 130
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
                                text: "Search clipboard…"
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.5)
                                font: search.font
                            }

                            Keys.onEscapePressed: root.close()
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onReturnPressed: root.copyEntry(root.results[list.currentIndex])
                            Keys.onEnterPressed: root.copyEntry(root.results[list.currentIndex])
                        }

                        Rectangle {
                            width: 62
                            height: 26
                            radius: 8
                            anchors.verticalCenter: parent.verticalCenter
                            color: wipeArea.containsMouse
                                ? Qt.rgba(Colors.bad.r, Colors.bad.g, Colors.bad.b, 0.22)
                                : "transparent"
                            border.width: 1
                            border.color: Qt.rgba(Colors.bad.r, Colors.bad.g,
                                                  Colors.bad.b, 0.35)
                            Behavior on color { ColorAnimation { duration: 140 } }

                            Text {
                                anchors.centerIn: parent
                                text: "󰩹 wipe"
                                color: Colors.bad
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                            }

                            MouseArea {
                                id: wipeArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.wipe()
                            }
                        }
                    }
                }

                ListView {
                    id: list
                    width: parent.width
                    height: parent.height - 58
                    clip: true
                    model: root.results
                    spacing: 4
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: Rectangle {
                        id: clipRow
                        required property var modelData
                        required property int index

                        readonly property bool selected: index === list.currentIndex

                        width: list.width
                        height: 56
                        radius: 12
                        color: selected
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.16)
                            : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.30)
                        border.width: 1
                        border.color: selected
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.45)
                            : "transparent"
                        Behavior on color { ColorAnimation { duration: 130 } }
                        Behavior on border.color { ColorAnimation { duration: 130 } }

                        opacity: 0
                        transform: Translate { id: rowSlide; x: 26 }

                        SequentialAnimation {
                            running: true
                            PauseAnimation { duration: Math.min(clipRow.index, 12) * 20 }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: rowSlide; property: "x"; to: 0
                                    duration: 300; easing.type: Easing.OutCubic
                                }
                                NumberAnimation {
                                    target: clipRow; property: "opacity"; to: 1
                                    duration: 240
                                }
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 14
                            spacing: 12

                            Item {
                                width: 68
                                height: parent.height
                                anchors.verticalCenter: parent.verticalCenter

                                ClippingRectangle {
                                    visible: clipRow.modelData.isImage
                                    anchors.centerIn: parent
                                    width: 68
                                    height: 40
                                    radius: 8
                                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.6)

                                    Image {
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                        sourceSize.width: 160
                                        source: clipRow.modelData.isImage
                                            ? "file://" + root.previewDir + "/" + clipRow.modelData.id
                                            : ""
                                    }
                                }

                                Rectangle {
                                    visible: !clipRow.modelData.isImage
                                    anchors.centerIn: parent
                                    width: 34
                                    height: 34
                                    radius: 9
                                    color: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                   Colors.accent.b, 0.14)

                                    Text {
                                        anchors.centerIn: parent
                                        text: clipRow.modelData.isLink ? "󰌷" : "󰉿"
                                        color: Colors.accent
                                        font.family: "JetBrainsMono Nerd Font"
                                        font.pixelSize: 14
                                    }
                                }
                            }

                            Column {
                                width: parent.width - 94
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2

                                Text {
                                    width: parent.width
                                    text: clipRow.modelData.label
                                    color: Colors.fg
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Text {
                                    width: parent.width
                                    visible: text !== ""
                                    text: clipRow.modelData.meta
                                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                   Colors.fgDim.b, 0.60)
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 9
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onEntered: list.currentIndex = clipRow.index
                            onClicked: root.copyEntry(clipRow.modelData)
                        }
                    }
                }
            }
        }
    }
}
