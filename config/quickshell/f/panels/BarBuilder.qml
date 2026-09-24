import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Controls
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property string tab: "layout"

    property string target: ""

    readonly property var screenNames: {
        const out = [];
        const list = Quickshell.screens;
        for (let i = 0; i < list.length; i++)
            out.push(list[i].name);
        return out;
    }

    function retarget() {
        if (!BarConfig.perScreen) {
            root.target = "";
        } else if (root.target === ""
                   || root.screenNames.indexOf(root.target) < 0) {
            root.target = root.screenNames.length > 0
                ? root.screenNames[0] : "";
        }
    }

    Connections {
        target: BarConfig
        function onPerScreenChanged() { root.retarget(); }
    }

    Component.onCompleted: root.retarget()

    property int expanded: -1

    property string pickZone: ""
    property int pickIsland: -1

    function toggle() { root.shown = !root.shown; }
    function close() {
        root.shown = false;
        root.pickIsland = -1;
        root.expanded = -1;
        BarConfig.writeNow();
    }

    onShownChanged: Sfx.panel(root.shown)

    readonly property var zoneTitles: ({
        left: I18n.t("barc.zoneLeft"),
        center: I18n.t("barc.zoneCenter"),
        right: I18n.t("barc.zoneRight")
    })

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-barbuilder"
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
            opacity: root.shown ? 0.55 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Emerge {
            id: emerge
            card: card
            win: win
            open: root.shown
        }

        FocusScope {
            id: card
            anchors.centerIn: parent
            width: Math.min(parent.width - 80, 1080)
            height: Math.min(parent.height - 90, 720)
            focus: true

            Keys.onEscapePressed: root.close()

            Glass {
                anchors.fill: parent
                radius: Shape.modal
                elevation: 3
                tintOpacity: 0.96
            }

            opacity: emerge.on ? emerge.cardOpacity : (root.shown ? 1 : 0)
            scale: emerge.on ? 1 : (root.shown ? 1 : 0.96)
            transform: Translate { x: emerge.dx; y: emerge.dy }
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

            Item {
                id: head
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Shape.padLoose
                height: 40

                Text {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    text: I18n.t("barc.title")
                    color: Colors.fg
                    font.family: Fonts.display
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                }

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    component Tab: Rectangle {
                        property string key: ""
                        property string label: ""

                        width: tabText.implicitWidth + 26
                        height: 28
                        radius: Shape.chip
                        antialiasing: true
                        color: root.tab === key
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                      Colors.accent.b, 0.20)
                            : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                      Colors.fgDim.b, 0.07)
                        Behavior on color { ColorAnimation { duration: Motion.fast } }

                        Text {
                            id: tabText
                            anchors.centerIn: parent
                            text: parent.label
                            color: root.tab === parent.key ? Colors.accent : Colors.fgDim
                            font.family: Fonts.display
                            font.pixelSize: 12
                            font.weight: root.tab === parent.key ? Font.DemiBold : Font.Normal
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.tab = parent.key;
                                Sfx.tapAlt();
                            }
                        }
                    }

                    Tab { key: "layout"; label: I18n.t("barc.layoutTab") }
                    Tab { key: "style";  label: I18n.t("barc.style") }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    IconButton {
                        width: 30; height: 30
                        glyph: "󰑐"
                        tip: I18n.t("barc.reset")
                        tint: Colors.bad
                        onActivated: BarConfig.reset(root.target)
                    }

                    IconButton {
                        width: 30; height: 30
                        glyph: "󰅖"
                        tip: I18n.t("act.done")
                        tint: Colors.good
                        onActivated: root.close()
                    }
                }
            }

            Rectangle {
                id: headLine
                anchors.top: head.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: Shape.padLoose
                anchors.topMargin: 6
                height: 1
                color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                               Colors.outline.b, 0.18)
            }

            Item {
                id: whichBar
                anchors.top: headLine.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: Shape.padLoose
                anchors.rightMargin: Shape.padLoose
                anchors.topMargin: 12
                height: root.screenNames.length > 1 ? 30 : 0
                visible: height > 0

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: splitText.implicitWidth + 40
                        height: 26
                        radius: Shape.chip
                        antialiasing: true
                        color: BarConfig.perScreen
                            ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                      Colors.accent.b, 0.20)
                            : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                      Colors.fgDim.b, 0.07)
                        Behavior on color { ColorAnimation { duration: Motion.fast } }

                        Row {
                            anchors.centerIn: parent
                            spacing: 7

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: BarConfig.perScreen ? "󰍺" : "󰕮"
                                color: BarConfig.perScreen ? Colors.accent : Colors.fgDim
                                font.family: Fonts.glyph
                                font.pixelSize: 12
                            }

                            Text {
                                id: splitText
                                anchors.verticalCenter: parent.verticalCenter
                                text: I18n.t("barc.perScreen")
                                color: BarConfig.perScreen ? Colors.accent : Colors.fgDim
                                font.family: Fonts.display
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                BarConfig.setPerScreen(!BarConfig.perScreen,
                                                       root.screenNames);
                                Sfx.tick();
                            }
                        }
                    }

                    Repeater {
                        model: BarConfig.perScreen ? root.screenNames : []

                        Rectangle {
                            required property string modelData

                            readonly property bool chosen: root.target === modelData

                            anchors.verticalCenter: parent.verticalCenter
                            width: scrText.implicitWidth + 22
                            height: 26
                            radius: Shape.chip
                            antialiasing: true
                            color: chosen
                                ? Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                          Colors.accentAlt.b, 0.22)
                                : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                          Colors.fgDim.b, 0.07)
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            Text {
                                id: scrText
                                anchors.centerIn: parent
                                text: parent.modelData
                                color: parent.chosen ? Colors.accentAlt : Colors.fgDim
                                font.family: Fonts.mono
                                font.pixelSize: 10
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.target = parent.modelData;
                                    root.expanded = -1;
                                    Sfx.tapAlt();
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: BarConfig.perScreen && root.screenNames.length > 1
                    width: copyText.implicitWidth + 24
                    height: 26
                    radius: Shape.chip
                    antialiasing: true
                    color: "transparent"
                    border.width: 1
                    border.color: Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                          Colors.accentAlt.b, 0.32)

                    readonly property string other: {
                        for (let i = 0; i < root.screenNames.length; i++) {
                            if (root.screenNames[i] !== root.target)
                                return root.screenNames[i];
                        }
                        return "";
                    }

                    Text {
                        id: copyText
                        anchors.centerIn: parent
                        text: I18n.t("barc.copyFrom") + " " + parent.other
                        color: Colors.accentAlt
                        opacity: 0.85
                        font.family: Fonts.mono
                        font.pixelSize: 10
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            BarConfig.copyCfg(parent.other, root.target);
                            Sfx.tapAlt();
                        }
                    }
                }
            }

            Row {
                id: zones
                visible: root.tab === "layout"
                anchors.top: whichBar.visible ? whichBar.bottom : headLine.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Shape.padLoose
                anchors.topMargin: 14
                spacing: 14

                Repeater {
                    model: BarConfig.zoneNames

                    Item {
                        id: zoneCol
                        required property string modelData

                        readonly property string nextZone: {
                            const order = BarConfig.zoneNames;
                            const i = order.indexOf(zoneCol.modelData);
                            return order[(i + 1) % order.length];
                        }

                        width: (zones.width - zones.spacing * 2) / 3
                        height: zones.height

                        Text {
                            id: zoneTitle
                            anchors.top: parent.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.zoneTitles[zoneCol.modelData]
                            color: Colors.fgDim
                            opacity: 0.6
                            font.family: Fonts.mono
                            font.pixelSize: 10
                            font.letterSpacing: 2
                        }

                        ScrollView {
                            anchors.top: zoneTitle.bottom
                            anchors.topMargin: 10
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: addIsle.top
                            anchors.bottomMargin: 8
                            clip: true

                            Column {
                                width: zoneCol.width
                                spacing: 10

                                Repeater {
                                    model: BarConfig.islands(zoneCol.modelData, root.target)

                                    Rectangle {
                                        id: isleBox
                                        required property var modelData
                                        required property int index

                                        width: zoneCol.width
                                        height: isleCol.implicitHeight + 20
                                        radius: Shape.field
                                        antialiasing: true
                                        color: Qt.rgba(Colors.bg.r, Colors.bg.g,
                                                       Colors.bg.b, 0.45)
                                        border.width: 1
                                        border.color: Qt.rgba(Colors.outline.r,
                                                              Colors.outline.g,
                                                              Colors.outline.b, 0.18)

                                        Column {
                                            id: isleCol
                                            anchors.centerIn: parent
                                            width: parent.width - 20
                                            spacing: 6

                                            Row {
                                                width: isleCol.width
                                                spacing: 4

                                                Text {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    text: "#" + (isleBox.index + 1)
                                                    color: Colors.fgDim
                                                    opacity: 0.45
                                                    font.family: Fonts.mono
                                                    font.pixelSize: 10
                                                }

                                                Item {
                                                    width: isleCol.width - 132
                                                    height: 1
                                                }

                                                IconButton {
                                                    width: 22; height: 22
                                                    glyph: "󰁝"
                                                    tint: Colors.accent
                                                    onActivated: BarConfig.moveIsland(
                                                        zoneCol.modelData, isleBox.modelData.key, -1, root.target)
                                                }

                                                IconButton {
                                                    width: 22; height: 22
                                                    glyph: "󰁅"
                                                    tint: Colors.accent
                                                    onActivated: BarConfig.moveIsland(
                                                        zoneCol.modelData, isleBox.modelData.key, 1, root.target)
                                                }

                                                IconButton {
                                                    width: 22; height: 22
                                                    glyph: "󰁔"
                                                    tip: root.zoneTitles[zoneCol.nextZone]
                                                    tint: Colors.accentAlt
                                                    onActivated: BarConfig.islandToZone(
                                                        zoneCol.modelData,
                                                        isleBox.modelData.key,
                                                        zoneCol.nextZone, root.target)
                                                }

                                                IconButton {
                                                    width: 22; height: 22
                                                    glyph: "󰩹"
                                                    tint: Colors.bad
                                                    onActivated: {
                                                        root.expanded = -1;
                                                        if (root.pickIsland === isleBox.modelData.key)
                                                            root.pickIsland = -1;
                                                        BarConfig.removeIsland(
                                                            zoneCol.modelData,
                                                            isleBox.modelData.key, root.target);
                                                    }
                                                }
                                            }

                                            Text {
                                                visible: isleBox.modelData.items.length === 0
                                                text: I18n.t("barc.empty")
                                                color: Colors.fgDim
                                                opacity: 0.35
                                                font.family: Fonts.mono
                                                font.pixelSize: 10
                                            }

                                            Repeater {
                                                model: isleBox.modelData.items

                                                Column {
                                                    id: modRow
                                                    required property var modelData
                                                    required property int index

                                                    width: isleCol.width
                                                    spacing: 4

                                                    readonly property var spec:
                                                        BarConfig.registry[modelData.type]
                                                    readonly property bool open:
                                                        root.expanded === modelData.key

                                                    Rectangle {
                                                        width: modRow.width
                                                        height: 30
                                                        radius: Shape.chip
                                                        antialiasing: true
                                                        color: modRow.open
                                                            ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                                      Colors.accent.b, 0.14)
                                                            : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                                      Colors.fgDim.b, 0.06)
                                                        Behavior on color {
                                                            ColorAnimation { duration: Motion.fast }
                                                        }

                                                        Row {
                                                            anchors.left: parent.left
                                                            anchors.leftMargin: 9
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            spacing: 8

                                                            Text {
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modRow.spec ? modRow.spec.glyph : "󰘨"
                                                                color: Colors.accent
                                                                font.family: Fonts.glyph
                                                                font.pixelSize: 13
                                                            }

                                                            Text {
                                                                anchors.verticalCenter: parent.verticalCenter
                                                                text: modRow.spec ? modRow.spec.title
                                                                                  : modRow.modelData.type
                                                                color: Colors.fg
                                                                font.family: Fonts.display
                                                                font.pixelSize: 12
                                                                elide: Text.ElideRight
                                                                width: Math.min(implicitWidth,
                                                                                modRow.width - 130)
                                                            }
                                                        }

                                                        Row {
                                                            anchors.right: parent.right
                                                            anchors.rightMargin: 5
                                                            anchors.verticalCenter: parent.verticalCenter
                                                            spacing: 2

                                                            IconButton {
                                                                width: 20; height: 20
                                                                glyph: "󰁝"
                                                                tint: Colors.accent
                                                                onActivated: BarConfig.moveItem(
                                                                    zoneCol.modelData,
                                                                    isleBox.modelData.key,
                                                                    modRow.modelData.key, -1, root.target)
                                                            }

                                                            IconButton {
                                                                width: 20; height: 20
                                                                glyph: "󰁅"
                                                                tint: Colors.accent
                                                                onActivated: BarConfig.moveItem(
                                                                    zoneCol.modelData,
                                                                    isleBox.modelData.key,
                                                                    modRow.modelData.key, 1, root.target)
                                                            }

                                                            IconButton {
                                                                width: 20; height: 20
                                                                visible: modRow.spec
                                                                    && Object.keys(modRow.spec.opts).length > 0
                                                                glyph: "󰒓"
                                                                tint: Colors.accentAlt
                                                                onActivated: root.expanded =
                                                                    modRow.open ? -1 : modRow.modelData.key
                                                            }

                                                            IconButton {
                                                                width: 20; height: 20
                                                                glyph: "󰩹"
                                                                tint: Colors.bad
                                                                onActivated: {
                                                                    if (modRow.open)
                                                                        root.expanded = -1;
                                                                    BarConfig.removeItem(
                                                                        zoneCol.modelData,
                                                                        isleBox.modelData.key,
                                                                        modRow.modelData.key, root.target);
                                                                }
                                                            }
                                                        }
                                                    }

                                                    Column {
                                                        visible: modRow.open
                                                        width: modRow.width
                                                        spacing: 5
                                                        leftPadding: 10

                                                        Repeater {
                                                            model: modRow.spec
                                                                ? Object.keys(modRow.spec.opts) : []

                                                            OptionRow {
                                                                required property string modelData
                                                                width: modRow.width - 10
                                                                name: modelData
                                                                label: BarConfig.optTitle(modelData)
                                                                valueLabel: v => BarConfig.valueTitle(v)
                                                                spec: modRow.spec.opts[modelData]
                                                                value: BarConfig.opt(modRow.modelData,
                                                                                     modelData)
                                                                onCommit: v => BarConfig.setItemOpt(
                                                                    zoneCol.modelData,
                                                                    isleBox.modelData.key,
                                                                    modRow.modelData.key,
                                                                    modelData, v, root.target)
                                                            }
                                                        }
                                                    }
                                                }
                                            }

                                            Rectangle {
                                                width: isleCol.width
                                                height: 26
                                                radius: Shape.chip
                                                antialiasing: true
                                                color: "transparent"
                                                border.width: 1
                                                border.color: Qt.rgba(Colors.accent.r,
                                                                      Colors.accent.g,
                                                                      Colors.accent.b, 0.3)

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: "+  " + I18n.t("barc.addModule")
                                                    color: Colors.accent
                                                    opacity: 0.85
                                                    font.family: Fonts.mono
                                                    font.pixelSize: 10
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: {
                                                        root.pickZone = zoneCol.modelData;
                                                        root.pickIsland = isleBox.modelData.key;
                                                        Sfx.tapAlt();
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            id: addIsle
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: 30
                            radius: Shape.chip
                            antialiasing: true
                            color: Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                           Colors.accentAlt.b, 0.14)

                            Text {
                                anchors.centerIn: parent
                                text: "+  " + I18n.t("barc.addIsland")
                                color: Colors.accentAlt
                                font.family: Fonts.mono
                                font.pixelSize: 10
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    BarConfig.addIsland(zoneCol.modelData, root.target);
                                    Sfx.tapAlt();
                                }
                            }
                        }
                    }
                }
            }

            ScrollView {
                visible: root.tab === "style"
                anchors.top: whichBar.visible ? whichBar.bottom : headLine.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: Shape.padLoose
                anchors.topMargin: 14
                clip: true

                Column {
                    id: styleCol
                    width: card.width - Shape.padLoose * 2
                    spacing: 18

                    readonly property real colWidth: (styleCol.width - 26) / 2

                    Repeater {
                        model: BarConfig.styleGroups

                        Column {
                            id: styleSection
                            required property var modelData
                            width: styleCol.width
                            spacing: 8

                            visible: !styleSection.modelData.when
                                || BarConfig.s("barStyle", root.target) === styleSection.modelData.when

                            Text {
                                text: BarConfig.styleGroupTitle(parent.modelData.key)
                                color: Colors.fgDim
                                opacity: 0.5
                                font.family: Fonts.mono
                                font.pixelSize: 9
                                font.letterSpacing: 2
                            }

                            Grid {
                                columns: 2
                                columnSpacing: 26
                                rowSpacing: 10
                                width: styleCol.width

                                Repeater {
                                    model: parent.parent.modelData.names

                                    OptionRow {
                                        required property string modelData
                                        width: styleCol.colWidth
                                        name: modelData
                                        label: BarConfig.optTitle(modelData)
                                        valueLabel: v => BarConfig.valueTitle(v)
                                        spec: BarConfig.styleSpec[modelData]
                                        value: BarConfig.s(modelData, root.target)
                                        onCommit: v => BarConfig.setStyle(modelData, v, root.target)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            visible: root.pickIsland >= 0
            onClicked: {
                root.pickIsland = -1;
                Sfx.tapAlt();
            }
        }

        Rectangle {
            id: picker
            visible: root.pickIsland >= 0
            anchors.centerIn: card
            width: 420
            height: Math.min(win.height - 140, pickCol.implicitHeight + 60)
            radius: Shape.modal
            antialiasing: true
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.97)
            border.width: 1
            border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                  Colors.outline.b, 0.3)

            MouseArea { anchors.fill: parent }

            Text {
                id: pickTitle
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.topMargin: 16
                text: I18n.t("barc.pickModule")
                color: Colors.fg
                font.family: Fonts.display
                font.pixelSize: 14
                font.weight: Font.DemiBold
            }

            ScrollView {
                anchors.top: pickTitle.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 16
                anchors.topMargin: 12
                clip: true

                Column {
                    id: pickCol
                    width: picker.width - 32
                    spacing: 10

                    Repeater {
                        model: BarConfig.groups

                        Column {
                            required property string modelData
                            width: pickCol.width
                            spacing: 5

                            Text {
                                text: BarConfig.groupTitle(parent.modelData)
                                color: Colors.fgDim
                                opacity: 0.5
                                font.family: Fonts.mono
                                font.pixelSize: 9
                                font.letterSpacing: 2
                            }

                            Flow {
                                width: pickCol.width
                                spacing: 6

                                Repeater {
                                    model: BarConfig.types.filter(
                                        t => BarConfig.registry[t].group === parent.parent.modelData)

                                    Rectangle {
                                        required property string modelData

                                        width: chipRow.implicitWidth + 18
                                        height: 28
                                        radius: Shape.chip
                                        antialiasing: true
                                        color: hover.hovered
                                            ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                      Colors.accent.b, 0.22)
                                            : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                      Colors.fgDim.b, 0.07)
                                        Behavior on color {
                                            ColorAnimation { duration: Motion.fast }
                                        }

                                        HoverHandler { id: hover }

                                        Row {
                                            id: chipRow
                                            anchors.centerIn: parent
                                            spacing: 7

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: BarConfig.registry[parent.parent.modelData].glyph
                                                color: Colors.accent
                                                font.family: Fonts.glyph
                                                font.pixelSize: 13
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: BarConfig.registry[parent.parent.modelData].title
                                                color: Colors.fg
                                                font.family: Fonts.display
                                                font.pixelSize: 11
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                BarConfig.addItem(root.pickZone,
                                                                  root.pickIsland,
                                                                  parent.modelData, root.target);
                                                root.pickIsland = -1;
                                                Sfx.tapAlt();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

    }
}
