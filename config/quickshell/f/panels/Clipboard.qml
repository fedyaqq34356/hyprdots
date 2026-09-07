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
    property var entries: []

    readonly property string previewDir:
        Quickshell.env("XDG_RUNTIME_DIR") + "/cliphist-preview"

    readonly property string mono: Fonts.mono

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
                    let kind = "text";
                    if (isImage) {
                        kind = "image";
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
                        if (/^https?:\/\//.test(oneLine)) {
                            kind = "link";
                            const host = oneLine.match(/^https?:\/\/([^\/]+)/);
                            meta = host ? host[1] : "";
                        } else if (oneLine.indexOf("/") === 0 && oneLine.indexOf(" ") < 0) {
                            kind = "path";
                            meta = oneLine.substring(0, oneLine.lastIndexOf("/") + 1);
                        } else {
                            meta = oneLine.length > 60 ? oneLine.length + " chars" : "";
                        }
                    }

                    out.push({
                        id: id,
                        body: body,
                        isImage: isImage,
                        kind: kind,
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

    function glyphFor(kind) {
        if (kind === "image") return "󰋩";
        if (kind === "link")  return "󰌷";
        if (kind === "path")  return "󰉋";
        return "󰉿";
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
            opacity: root.shown ? 0.42 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }
            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Item {
            id: card

            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.13
            width: 660
            height: 540

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            transform: Translate {
                y: root.shown ? 0 : 24
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

            Bloom { target: card }

            Glass {
                z: -1
                anchors.fill: parent
                radius: Shape.modal
                elevation: 3
                tint: Colors.bg
                tintOpacity: 0.90
                edge: Colors.accent
            }

            Column {
                anchors.fill: parent
                anchors.margins: 22
                spacing: 14

                Row {
                    width: parent.width
                    height: 30

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰅇"
                            color: Colors.accent
                            font.family: root.mono
                            font.pixelSize: 16
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "clipboard"
                            color: Colors.fg
                            font.family: Fonts.display
                            font.pixelSize: Fonts.titleSize
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: countLabel.implicitWidth + 16
                            height: 20
                            radius: Shape.detail
                            color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                           Colors.fgDim.b, 0.10)

                            Text {
                                id: countLabel
                                anchors.centerIn: parent
                                text: root.results.length
                                color: Colors.fgDim
                                opacity: 0.75
                                font.family: root.mono
                                font.pixelSize: 10
                            }
                        }
                    }

                    Item { width: parent.width - 320; height: 1 }

                    HoldButton {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 30
                        height: 30
                        glyph: "󰩹"
                        tip: I18n.t("act.clearAll")
                        onConfirmed: root.wipe()
                    }
                }

                Rectangle {
                    id: field

                    width: parent.width
                    height: 46
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
                            width: parent.width - 60
                            anchors.verticalCenter: parent.verticalCenter
                            color: Colors.fg
                            font.family: root.mono
                            font.pixelSize: 14
                            clip: true
                            selectByMouse: true
                            selectionColor: Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                    Colors.accent.b, 0.35)

                            onTextChanged: list.currentIndex = 0

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: search.text === ""
                                text: I18n.t("act.search")
                                color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.5)
                                font: search.font
                            }

                            Keys.onEscapePressed: root.close()
                            Keys.onDownPressed: list.incrementCurrentIndex()
                            Keys.onUpPressed: list.decrementCurrentIndex()
                            Keys.onReturnPressed: root.copyEntry(root.results[list.currentIndex])
                            Keys.onEnterPressed: root.copyEntry(root.results[list.currentIndex])

                            Keys.onPressed: (event) => {
                                if (!(event.modifiers & Qt.AltModifier))
                                    return;
                                if (event.key < Qt.Key_1 || event.key > Qt.Key_9)
                                    return;
                                const i = event.key - Qt.Key_1;
                                if (i < root.results.length) {
                                    root.copyEntry(root.results[i]);
                                    event.accepted = true;
                                }
                            }
                        }
                    }
                }

                ListView {
                    id: list

                    width: parent.width
                    height: parent.height - 30 - 46 - 28 - 16
                    clip: true
                    model: root.results
                    spacing: 5
                    currentIndex: 0
                    boundsBehavior: Flickable.StopAtBounds
                    cacheBuffer: 400

                    delegate: Item {
                        id: clipRow

                        required property var modelData
                        required property int index

                        readonly property bool selected: index === list.currentIndex

                        width: list.width
                        height: 62

                        opacity: 0
                        transform: Translate { id: rowSlide; x: 22 }

                        SequentialAnimation {
                            running: true
                            PauseAnimation { duration: Motion.delay(clipRow.index) }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: rowSlide; property: "x"; to: 0
                                    duration: Motion.slow
                                    easing.type: Easing.Bezier
                                    easing.bezierCurve: Motion.expo
                                }
                                NumberAnimation {
                                    target: clipRow; property: "opacity"; to: 1
                                    duration: Motion.base
                                }
                            }
                        }

                        Rectangle {
                            id: body

                            anchors.fill: parent
                            radius: Shape.field
                            antialiasing: true
                            color: clipRow.selected
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.16)
                                : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                          Colors.bgAlt.b, 0.30)
                            border.width: 1
                            border.color: clipRow.selected
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.45)
                                : "transparent"

                            Behavior on color { ColorAnimation { duration: Motion.fast } }
                            Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                            scale: clipRow.selected ? 1.008 : 1
                            Behavior on scale {
                                NumberAnimation {
                                    duration: Motion.base
                                    easing.type: Easing.Bezier
                                    easing.bezierCurve: Motion.snap
                                }
                            }
                        }

                        Rectangle {
                            anchors.left: parent.left
                            anchors.leftMargin: 5
                            anchors.verticalCenter: parent.verticalCenter
                            width: 3
                            radius: 1.5
                            antialiasing: true
                            color: Colors.accent
                            height: clipRow.selected ? 30 : 0
                            opacity: clipRow.selected ? 1 : 0

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
                            anchors.rightMargin: 14
                            spacing: 13

                            Item {
                                width: 76
                                height: parent.height
                                anchors.verticalCenter: parent.verticalCenter

                                ClippingRectangle {
                                    visible: clipRow.modelData.isImage
                                    anchors.centerIn: parent
                                    width: 76
                                    height: 44
                                    radius: Shape.chip
                                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.6)

                                    Image {
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                        sourceSize.width: 200
                                        source: clipRow.modelData.isImage
                                            ? "file://" + root.previewDir + "/" + clipRow.modelData.id
                                            : ""
                                    }

                                    Sheen {
                                        anchors.fill: parent
                                        radius: Shape.chip
                                        grain: false
                                        depth: false
                                        edgeOpacity: 0.25
                                    }
                                }

                                Rectangle {
                                    visible: !clipRow.modelData.isImage
                                    anchors.centerIn: parent
                                    width: 38
                                    height: 38
                                    radius: Shape.chip
                                    antialiasing: true
                                    color: clipRow.selected
                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                  Colors.accent.b, 0.20)
                                        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                  Colors.fgDim.b, 0.08)
                                    Behavior on color { ColorAnimation { duration: Motion.fast } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.glyphFor(clipRow.modelData.kind)
                                        color: Colors.accent
                                        font.family: root.mono
                                        font.pixelSize: 15
                                    }
                                }
                            }

                            Column {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width - 76 - 13 - 34
                                spacing: 3

                                Text {
                                    width: parent.width
                                    text: clipRow.modelData.label
                                    color: Colors.fg
                                    opacity: clipRow.selected ? 1 : 0.9
                                    font.family: root.mono
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    maximumLineCount: 1
                                }

                                Row {
                                    spacing: 8
                                    visible: clipRow.modelData.meta !== ""

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: kindLabel.implicitWidth + 12
                                        height: 15
                                        radius: Shape.detail - 2
                                        antialiasing: true
                                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                       Colors.fgDim.b, 0.10)

                                        Text {
                                            id: kindLabel
                                            anchors.centerIn: parent
                                            text: clipRow.modelData.kind
                                            color: Colors.fgDim
                                            opacity: 0.7
                                            font.family: root.mono
                                            font.pixelSize: 8
                                            font.letterSpacing: 1
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: clipRow.width - 220
                                        text: clipRow.modelData.meta
                                        color: Colors.fgDim
                                        opacity: 0.55
                                        font.family: root.mono
                                        font.pixelSize: 9
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.rightMargin: 14
                            anchors.verticalCenter: parent.verticalCenter
                            visible: clipRow.index < 9
                            width: 18
                            height: 18
                            radius: Shape.detail - 2
                            antialiasing: true
                            color: clipRow.selected
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.22)
                                : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                          Colors.fgDim.b, 0.08)
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            Text {
                                anchors.centerIn: parent
                                text: clipRow.index + 1
                                color: clipRow.selected ? Colors.accent : Colors.fgDim
                                opacity: clipRow.selected ? 1 : 0.6
                                font.family: root.mono
                                font.pixelSize: 9
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

                Item {
                    width: parent.width
                    height: 16

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Repeater {
                            model: [
                                { k: "\u{f0360}\u{f035d}", v: I18n.t("launcher.keyMove") },
                                { k: "alt 1-9", v: I18n.t("act.copy") },
                                { k: "esc", v: I18n.t("act.close") }
                            ]

                            Row {
                                id: hint

                                required property var modelData
                                spacing: 5

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: cap.implicitWidth + 10
                                    height: 15
                                    radius: Shape.detail - 2
                                    antialiasing: true
                                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                   Colors.fgDim.b, 0.08)

                                    Text {
                                        id: cap
                                        anchors.centerIn: parent
                                        text: hint.modelData.k
                                        color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                       Colors.fgDim.b, 0.7)
                                        font.family: root.mono
                                        font.pixelSize: 9
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: hint.modelData.v
                                    color: Colors.fgDim
                                    opacity: 0.4
                                    font.family: root.mono
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
