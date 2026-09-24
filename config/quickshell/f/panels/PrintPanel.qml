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

    readonly property string mono: Fonts.mono
    readonly property string home: Quickshell.env("HOME")
    readonly property string lister: home + "/.config/hypr/scripts/print-browse.sh"

    property string dir: home
    property string parentDir: "/"
    property var entries: []
    property bool loading: false

    property bool deep: false

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    function open(path) {
        root.shown = true;
        Printing.prepare(path);
    }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (root.shown) {
            Printing.acquire();
            root.deep = false;
            root.load(root.dir);
            browser.forceActiveFocus();
        } else {
            Printing.release();
        }
    }

    Component.onDestruction: if (root.shown) Printing.release()

    Process {
        id: lsProc
        stdout: StdioCollector {
            onStreamFinished: {
                root.loading = false;
                let p;
                try {
                    p = JSON.parse(this.text);
                } catch (e) {
                    root.entries = [];
                    return;
                }
                root.dir = p.dir;
                root.parentDir = p.parent;
                root.entries = p.entries || [];
                browser.currentIndex = 0;
                browser.positionViewAtBeginning();
            }
        }
    }

    function load(path) {
        root.loading = true;
        lsProc.running = false;
        lsProc.command = [root.lister, path];
        lsProc.running = true;
    }

    function activate(entry) {
        if (!entry)
            return;
        if (entry.type === "dir") {
            root.load(entry.path);
            return;
        }
        Printing.prepare(entry.path);
    }

    function goUp() {
        if (root.dir !== "/")
            root.load(root.parentDir);
    }

    readonly property string prettyDir: {
        const d = root.dir;
        return d.startsWith(root.home) ? "~" + d.slice(root.home.length) : d;
    }

    readonly property string healthText: {
        const code = Printing.alert.code;
        if (code !== "") {
            const key = "print.capt." + code;
            const said = I18n.t(key);
            if (said !== key)
                return said;
            if (Printing.alert.text !== "")
                return Printing.alert.text.toLowerCase();
        }
        return I18n.t("print.state." + Printing.health);
    }

    readonly property color healthColor: {
        switch (Printing.health) {
        case "ready":
        case "busy":   return Colors.good;
        case "sleep":  return Colors.fgDim;
        case "stale":  return Colors.warn;
        default:       return Colors.bad;
        }
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win
        WlrLayershell.namespace: "qs-print"
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
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

        Emerge {
            id: emerge
            card: shell
            win: win
            open: root.shown
        }

        FocusScope {
            id: shell

            anchors.centerIn: parent
            width: 1060
            height: 700
            focus: true

            opacity: emerge.on ? emerge.cardOpacity : (root.shown ? 1 : 0)
            scale: emerge.on ? 1 : (root.shown ? 1 : 0.95)
            transform: Translate {
                x: emerge.dx
                y: emerge.on ? emerge.dy : (root.shown ? 0 : 22)
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

            Keys.onEscapePressed: root.close()

            Item {
                anchors.fill: parent
                z: -1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowVerticalOffset: 12
                    shadowOpacity: 0.5
                    shadowColor: Colors.shadow(0.9)
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Shape.modal
                    color: Colors.bg
                }
            }

            Rectangle {
                id: card

                anchors.fill: parent
                radius: Shape.modal
                clip: true

                gradient: Gradient {
                    GradientStop { position: 0.0; color: Colors.alpha(Colors.bgAlt, 0.96) }
                    GradientStop { position: 0.5; color: Colors.alpha(Colors.bg, 0.985) }
                    GradientStop { position: 1.0; color: Colors.alpha(Colors.bg, 0.99) }
                }

                Sheen {
                    anchors.fill: parent
                    radius: Shape.modal
                    edge: Colors.accent
                    edgeOpacity: 0.26
                }

                Item {
                    id: header

                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    anchors.margins: Shape.padLoose
                    anchors.bottomMargin: 0
                    height: 44

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "󰐪"
                            color: Colors.accent
                            font.family: root.mono
                            font.pixelSize: 22
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 3

                            Text {
                                text: I18n.t("print.title")
                                color: Colors.fg
                                font.family: Fonts.display
                                font.pixelSize: Fonts.titleSize
                                font.weight: Font.DemiBold
                            }

                            Row {
                                spacing: 7

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 7
                                    height: 7
                                    radius: 4
                                    color: root.healthColor
                                    Behavior on color { ColorAnimation { duration: Motion.base } }

                                    SequentialAnimation on opacity {
                                        running: Printing.health === "busy"
                                        loops: Animation.Infinite
                                        NumberAnimation { to: 0.35; duration: 700 }
                                        NumberAnimation { to: 1.0; duration: 700 }
                                    }
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: (Printing.selected || "—") + "  ·  " + root.healthText
                                    color: Colors.fgDim
                                    opacity: 0.7
                                    font.family: root.mono
                                    font.pixelSize: Fonts.smallSize
                                }
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        IconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: "󰑓"
                            tint: Colors.accent
                            mono: root.mono
                            tip: I18n.t("print.tip.repair")
                            spinning: Printing.repairing
                            onActivated: Printing.doctor()
                        }

                        IconButton {
                            anchors.verticalCenter: parent.verticalCenter
                            glyph: "󰅖"
                            tint: Colors.fgDim
                            mono: root.mono
                            tip: I18n.t("print.tip.close")
                            onActivated: root.close()
                        }
                    }
                }

                Item {
                    id: left

                    anchors {
                        top: header.bottom
                        left: parent.left
                        bottom: footer.top
                    }
                    anchors.topMargin: 18
                    anchors.leftMargin: Shape.padLoose
                    anchors.bottomMargin: 10
                    width: 600

                    Item {
                        anchors.fill: parent
                        visible: !Printing.doc && !Printing.preparing
                        opacity: visible ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Motion.base } }

                        Item {
                            id: crumbs

                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: 34

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                IconButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    glyph: "󰁭"
                                    tint: Colors.accent
                                    mono: root.mono
                                    tip: I18n.t("print.tip.up")
                                    opacity: root.dir === "/" ? 0.3 : 1
                                    onActivated: root.goUp()
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: root.prettyDir
                                    color: Colors.fg
                                    font.family: root.mono
                                    font.pixelSize: Fonts.bodySize
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideMiddle
                                    width: Math.min(implicitWidth, 300)
                                }
                            }

                            Row {
                                anchors.right: parent.right
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 6

                                Repeater {
                                    model: [
                                        { glyph: "󰋜", path: root.home,                key: "home" },
                                        { glyph: "󰉍", path: root.home + "/Downloads", key: "downloads" },
                                        { glyph: "󰈙", path: root.home + "/Documents", key: "documents" }
                                    ]

                                    IconButton {
                                        required property var modelData

                                        anchors.verticalCenter: parent.verticalCenter
                                        glyph: modelData.glyph
                                        tint: Colors.accent
                                        mono: root.mono
                                        tip: I18n.t("print.tip." + modelData.key)
                                        onActivated: root.load(modelData.path)
                                    }
                                }
                            }
                        }

                        ListView {
                            id: browser

                            anchors {
                                top: crumbs.bottom
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            anchors.topMargin: 10

                            clip: true
                            focus: true
                            spacing: 4
                            model: root.entries
                            boundsBehavior: Flickable.StopAtBounds
                            cacheBuffer: 320

                            Keys.onEscapePressed: root.close()
                            Keys.onReturnPressed: root.activate(root.entries[browser.currentIndex])
                            Keys.onEnterPressed: root.activate(root.entries[browser.currentIndex])
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Backspace) {
                                    root.goUp();
                                    event.accepted = true;
                                }
                            }

                            delegate: Rectangle {
                                id: row

                                required property var modelData
                                required property int index

                                readonly property bool isDir: modelData.type === "dir"
                                readonly property bool active: browser.currentIndex === index

                                width: browser.width
                                height: 46
                                radius: Shape.chip

                                color: row.active
                                    ? Colors.alpha(Colors.accent, 0.13)
                                    : rowHover.hovered
                                        ? Colors.alpha(Colors.bgAlt, 0.5)
                                        : "transparent"
                                Behavior on color { ColorAnimation { duration: Motion.fast } }

                                border.width: 1
                                border.color: row.active
                                    ? Colors.alpha(Colors.accent, 0.4)
                                    : "transparent"
                                Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                                HoverHandler {
                                    id: rowHover
                                    onHoveredChanged: if (hovered) browser.currentIndex = row.index
                                }

                                TapHandler {
                                    onTapped: {
                                        Sfx.tapAlt();
                                        root.activate(row.modelData);
                                    }
                                }

                                Text {
                                    id: rowGlyph

                                    anchors.left: parent.left
                                    anchors.leftMargin: 14
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Printing.glyphFor(row.modelData.kind)
                                    color: row.isDir ? Colors.accentAlt : Colors.accent
                                    opacity: row.active ? 1 : 0.75
                                    font.family: root.mono
                                    font.pixelSize: 17
                                }

                                Text {
                                    anchors.left: rowGlyph.right
                                    anchors.leftMargin: 14
                                    anchors.right: rowSize.left
                                    anchors.rightMargin: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.name
                                    color: row.active ? Colors.fg : Colors.fgDim
                                    opacity: row.active ? 1 : 0.85
                                    font.family: Fonts.display
                                    font.pixelSize: Fonts.bodySize
                                    font.weight: row.active ? Font.DemiBold : Font.Normal
                                    elide: Text.ElideMiddle
                                }

                                Text {
                                    id: rowSize

                                    anchors.right: parent.right
                                    anchors.rightMargin: 16
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: row.modelData.size
                                    color: Colors.fgDim
                                    opacity: 0.45
                                    font.family: root.mono
                                    font.pixelSize: Fonts.smallSize
                                }
                            }
                        }

                        LivingShape {
                            anchors.centerIn: browser
                            width: 52
                            height: 52
                            tint: Colors.accent
                            running: root.loading
                        }

                        Column {
                            anchors.centerIn: browser
                            spacing: 10
                            visible: !root.loading && root.entries.length === 0

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰧮"
                                color: Colors.fgDim
                                opacity: 0.25
                                font.family: root.mono
                                font.pixelSize: 44
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: I18n.t("print.empty")
                                color: Colors.fgDim
                                opacity: 0.6
                                font.family: root.mono
                                font.pixelSize: Fonts.bodySize
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 16
                        visible: Printing.preparing

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰈦"
                            color: Colors.accent
                            font.family: root.mono
                            font.pixelSize: 40

                            RotationAnimation on rotation {
                                running: Printing.preparing
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: 2400
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: I18n.t("print.preparing")
                            color: Colors.fgDim
                            opacity: 0.7
                            font.family: root.mono
                            font.pixelSize: Fonts.bodySize
                        }
                    }

                    Item {
                        anchors.fill: parent
                        visible: !!Printing.doc && !Printing.preparing

                        Item {
                            id: docHead

                            anchors { top: parent.top; left: parent.left; right: parent.right }
                            height: 34

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                IconButton {
                                    anchors.verticalCenter: parent.verticalCenter
                                    glyph: "󰁭"
                                    tint: Colors.accent
                                    mono: root.mono
                                    tip: I18n.t("print.tip.another")
                                    onActivated: Printing.drop()
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 2

                                    Text {
                                        text: Printing.doc ? Printing.doc.name : ""
                                        color: Colors.fg
                                        font.family: Fonts.display
                                        font.pixelSize: Fonts.headingSize
                                        font.weight: Font.DemiBold
                                        elide: Text.ElideMiddle
                                        width: Math.min(implicitWidth, 420)
                                    }

                                    Text {
                                        text: {
                                            if (!Printing.doc)
                                                return "";
                                            return I18n.count("plural.page", Printing.doc.pages)
                                                 + (Printing.doc.paper ? "  ·  " + Printing.doc.paper : "");
                                        }
                                        color: Colors.fgDim
                                        opacity: 0.6
                                        font.family: root.mono
                                        font.pixelSize: Fonts.smallSize
                                    }
                                }
                            }
                        }

                        GridView {
                            id: pages

                            anchors {
                                top: docHead.bottom
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                            }
                            anchors.topMargin: 12

                            clip: true
                            cellWidth: 146
                            cellHeight: 200
                            model: Printing.doc ? Printing.doc.thumbs : []
                            boundsBehavior: Flickable.StopAtBounds
                            cacheBuffer: 600

                            delegate: Item {
                                id: page

                                required property string modelData
                                required property int index

                                readonly property bool included: root.inRange(page.index + 1)

                                width: pages.cellWidth - 12
                                height: pages.cellHeight - 12

                                opacity: page.included ? 1 : 0.28
                                Behavior on opacity { NumberAnimation { duration: Motion.base } }

                                scale: pageHover.hovered ? 1.03 : 1
                                Behavior on scale { Spring {} }

                                HoverHandler { id: pageHover }

                                Rectangle {
                                    id: sheet

                                    anchors.fill: parent
                                    anchors.bottomMargin: 20
                                    radius: Shape.detail
                                    color: "#ffffff"
                                    antialiasing: true

                                    border.width: 1
                                    border.color: Colors.alpha(Colors.outline, 0.25)

                                    Image {
                                        id: shot

                                        anchors.fill: parent
                                        anchors.margins: 1
                                        source: "file://" + page.modelData
                                        fillMode: Image.PreserveAspectFit
                                        asynchronous: true
                                        cache: true
                                        sourceSize.width: 260

                                        opacity: status === Image.Ready ? 1 : 0
                                        Behavior on opacity {
                                            NumberAnimation { duration: Motion.base }
                                        }
                                    }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.bottom: parent.bottom
                                    text: String(page.index + 1)
                                    color: page.included ? Colors.fgDim : Colors.fgDim
                                    opacity: 0.6
                                    font.family: root.mono
                                    font.pixelSize: Fonts.smallSize
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: pages.horizontalCenter
                            anchors.bottom: parent.bottom
                            visible: Printing.doc
                                     && Printing.doc.thumbs.length < Printing.doc.pages
                            text: I18n.t("print.shownFirst")
                                  + (Printing.doc ? Printing.doc.thumbs.length : 0)
                                  + I18n.t("print.allPrint")
                            color: Colors.fgDim
                            opacity: 0.45
                            font.family: root.mono
                            font.pixelSize: Fonts.smallSize
                        }
                    }
                }

                Rectangle {
                    id: right

                    anchors {
                        top: header.bottom
                        left: left.right
                        right: parent.right
                        bottom: footer.top
                    }
                    anchors.topMargin: 18
                    anchors.leftMargin: 20
                    anchors.rightMargin: Shape.padLoose
                    anchors.bottomMargin: 10

                    radius: Shape.card
                    color: Colors.alpha(Colors.bgAlt, 0.3)
                    border.width: 1
                    border.color: Colors.alpha(Colors.outline, 0.12)

                    Sheen {
                        anchors.fill: parent
                        radius: Shape.card
                        strength: 0.6
                        border: false
                    }

                    Flickable {
                        id: opts

                        anchors.fill: parent
                        anchors.margins: 18
                        anchors.bottomMargin: 8
                        clip: true
                        contentHeight: optsColumn.implicitHeight
                        boundsBehavior: Flickable.StopAtBounds

                        Column {
                            id: optsColumn

                            width: opts.width
                            spacing: 18

                            Column {
                                width: parent.width
                                spacing: 8
                                visible: Printing.printers.length > 1

                                Text {
                                    text: I18n.t("print.printer")
                                    color: Colors.fgDim
                                    opacity: 0.6
                                    font.family: root.mono
                                    font.pixelSize: Fonts.smallSize
                                    font.letterSpacing: 2
                                }

                                Segment {
                                    mono: root.mono
                                    auto: false
                                    current: Printing.selected
                                    options: Printing.printers.map(p => ({
                                        value: p.name, label: p.name.toLowerCase()
                                    }))
                                    onPicked: value => Printing.selected = value
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 8
                                visible: Printing.liveKnobs.length > 0

                                Text {
                                    text: I18n.t("print.quality")
                                    color: Colors.fgDim
                                    opacity: 0.6
                                    font.family: root.mono
                                    font.pixelSize: Fonts.smallSize
                                    font.letterSpacing: 2
                                }

                                Segment {
                                    mono: root.mono
                                    auto: false
                                    options: Printing.qualityChoices
                                    current: Printing.quality
                                    onPicked: value => Printing.applyQuality(value)
                                }
                            }

                            Item {
                                width: parent.width
                                height: 30

                                Text {
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: I18n.t("print.copies")
                                    color: Colors.fgDim
                                    opacity: 0.7
                                    font.family: root.mono
                                    font.pixelSize: 11
                                }

                                Row {
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 10

                                    IconButton {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 28
                                        height: 28
                                        glyph: "󰍴"
                                        tint: Colors.accent
                                        mono: root.mono
                                        opacity: Printing.copies > 1 ? 1 : 0.3
                                        onActivated: Printing.copies = Math.max(1, Printing.copies - 1)
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 24
                                        horizontalAlignment: Text.AlignHCenter
                                        text: String(Printing.copies)
                                        color: Colors.fg
                                        font.family: root.mono
                                        font.pixelSize: Fonts.bodySize
                                        font.weight: Font.DemiBold
                                    }

                                    IconButton {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 28
                                        height: 28
                                        glyph: "󰐕"
                                        tint: Colors.accent
                                        mono: root.mono
                                        opacity: Printing.copies < 99 ? 1 : 0.3
                                        onActivated: Printing.copies = Math.min(99, Printing.copies + 1)
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 8

                                Text {
                                    text: I18n.t("print.pages")
                                    color: Colors.fgDim
                                    opacity: 0.6
                                    font.family: root.mono
                                    font.pixelSize: Fonts.smallSize
                                    font.letterSpacing: 2
                                }

                                Field {
                                    width: parent.width
                                    mono: root.mono
                                    placeholder: I18n.t("print.rangeHint")
                                    tint: Printing.rangeValid ? Colors.accent : Colors.bad
                                    text: Printing.range
                                    onTextChanged: Printing.range = text
                                }
                            }

                            SettingsChoice {
                                width: parent.width
                                mono: root.mono
                                label: I18n.t("print.nup")
                                options: Printing.nupChoices
                                current: String(Printing.nup)
                                onPicked: value => Printing.nup = parseInt(value, 10)
                            }

                            Repeater {
                                model: Printing.plainKnobs
                                delegate: knobRow
                            }

                            Column {
                                width: parent.width
                                spacing: 12
                                visible: Printing.deepKnobs.length > 0

                                Item {
                                    width: parent.width
                                    height: 20

                                    Text {
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: (root.deep ? "󰅀  " : "󰅂  ")
                                              + I18n.t("print.tuning")
                                        color: root.deep ? Colors.accent : Colors.fgDim
                                        opacity: deepHover.hovered || root.deep ? 1 : 0.55
                                        font.family: root.mono
                                        font.pixelSize: Fonts.smallSize
                                        font.letterSpacing: 2

                                        Behavior on color { ColorAnimation { duration: Motion.fast } }
                                    }

                                    HoverHandler { id: deepHover }
                                    TapHandler {
                                        onTapped: {
                                            Sfx.pick();
                                            root.deep = !root.deep;
                                        }
                                    }
                                }

                                Column {
                                    width: parent.width
                                    spacing: 18
                                    visible: root.deep
                                    height: visible ? implicitHeight : 0

                                    Repeater {
                                        model: root.deep ? Printing.deepKnobs : []
                                        delegate: knobRow
                                    }
                                }
                            }

                            Component {
                                id: knobRow

                                Item {
                                    id: knob

                                    required property var modelData

                                    width: optsColumn.width
                                    height: body.implicitHeight

                                    Column {
                                        id: body

                                        width: parent.width
                                        spacing: 8

                                        SettingsChoice {
                                            width: parent.width
                                            visible: knob.modelData.kind === "choice"
                                            height: visible ? implicitHeight : 0
                                            mono: root.mono
                                            label: knob.modelData.label
                                            options: knob.modelData.options || []
                                            current: Printing.optionOf(knob.modelData.id)
                                            onPicked: value =>
                                                Printing.setOption(knob.modelData.id, value)
                                        }

                                        Item {
                                            width: parent.width
                                            visible: knob.modelData.kind === "toggle"
                                            height: visible ? 30 : 0

                                            Text {
                                                anchors.left: parent.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: knob.modelData.label
                                                color: Colors.fgDim
                                                opacity: 0.7
                                                font.family: root.mono
                                                font.pixelSize: 11
                                            }

                                            Switch {
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                checked: Printing.isOn(knob.modelData.id)
                                                onToggled: value =>
                                                    Printing.setOption(knob.modelData.id,
                                                                       value ? "True" : "False")
                                            }
                                        }

                                        Item {
                                            width: parent.width
                                            visible: knob.modelData.kind === "slider"
                                            height: visible ? 44 : 0

                                            readonly property int lo: knob.modelData.min || 1
                                            readonly property int hi: knob.modelData.max || 16
                                            readonly property int span: Math.max(1, hi - lo)
                                            readonly property int now:
                                                parseInt(Printing.optionOf(knob.modelData.id), 10) || lo

                                            Text {
                                                id: knobName

                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                text: knob.modelData.label
                                                color: Colors.fgDim
                                                opacity: 0.7
                                                font.family: root.mono
                                                font.pixelSize: 11
                                            }

                                            Text {
                                                anchors.right: parent.right
                                                anchors.top: parent.top
                                                text: parent.now + " / " + parent.hi
                                                color: Colors.fg
                                                font.family: root.mono
                                                font.pixelSize: 11
                                                font.weight: Font.DemiBold
                                            }

                                            Slider {
                                                id: dial

                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.top: knobName.bottom
                                                anchors.topMargin: 12

                                                step: 1 / dial.parent.span
                                                value: (dial.parent.now - dial.parent.lo)
                                                       / dial.parent.span
                                                onMoved: v => {
                                                    const n = Math.round(dial.parent.lo
                                                                         + v * dial.parent.span);
                                                    Printing.setOption(knob.modelData.id, String(n));
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            Column {
                                width: parent.width
                                spacing: 8
                                visible: Printing.jobs.length > 0

                                Item {
                                    width: parent.width
                                    height: 16

                                    Text {
                                        anchors.left: parent.left
                                        text: I18n.t("print.queue")
                                        color: Colors.fgDim
                                        opacity: 0.6
                                        font.family: root.mono
                                        font.pixelSize: Fonts.smallSize
                                        font.letterSpacing: 2
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        text: I18n.t("print.cancelAll")
                                        color: Colors.bad
                                        opacity: clearHover.hovered ? 1 : 0.6
                                        font.family: root.mono
                                        font.pixelSize: Fonts.smallSize

                                        HoverHandler { id: clearHover }
                                        TapHandler {
                                            onTapped: {
                                                Sfx.tapAlt();
                                                Printing.cancelAll();
                                            }
                                        }
                                    }
                                }

                                Repeater {
                                    model: Printing.jobs

                                    Rectangle {
                                        id: job

                                        required property var modelData

                                        width: optsColumn.width
                                        height: 34
                                        radius: Shape.chip
                                        color: Colors.alpha(Colors.bg, 0.5)

                                        Text {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 12
                                            anchors.right: kill.left
                                            anchors.rightMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: job.modelData.id
                                            color: Colors.fgDim
                                            opacity: 0.8
                                            font.family: root.mono
                                            font.pixelSize: Fonts.smallSize
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            id: kill

                                            anchors.right: parent.right
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "󰅖"
                                            color: killHover.hovered ? Colors.bad : Colors.fgDim
                                            opacity: killHover.hovered ? 1 : 0.5
                                            font.family: root.mono
                                            font.pixelSize: 12

                                            HoverHandler { id: killHover }
                                            TapHandler {
                                                onTapped: {
                                                    Sfx.tapAlt();
                                                    Printing.cancel(job.modelData.id);
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    id: footer

                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    anchors.margins: Shape.padBase
                    anchors.leftMargin: Shape.padLoose
                    anchors.rightMargin: Shape.padLoose
                    height: 52

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 320
                        text: {
                            if (Printing.error !== "")
                                return "󰀪  " + Printing.error;
                            if (Printing.lastJob !== "")
                                return "󰄬  " + I18n.t("print.sent") + Printing.lastJob;
                            return I18n.t(Printing.doc ? "print.keysDoc" : "print.keysBrowse");
                        }
                        color: Printing.error !== "" ? Colors.bad
                             : Printing.lastJob !== "" ? Colors.good
                             : Colors.fgDim
                        opacity: Printing.error !== "" || Printing.lastJob !== "" ? 0.95 : 0.45
                        font.family: root.mono
                        font.pixelSize: Fonts.smallSize
                        elide: Text.ElideRight
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 14

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !!Printing.doc
                            text: I18n.count("plural.sheet", Printing.sheets)
                            color: Colors.fgDim
                            opacity: 0.55
                            font.family: root.mono
                            font.pixelSize: Fonts.smallSize
                        }

                        Rectangle {
                            id: go

                            readonly property bool armed: !!Printing.doc
                                                          && Printing.ready
                                                          && Printing.rangeValid
                                                          && !Printing.sending

                            anchors.verticalCenter: parent.verticalCenter
                            width: 150
                            height: 40
                            radius: Shape.chip
                            antialiasing: true

                            color: go.armed
                                ? (goHover.hovered ? Colors.accent
                                                   : Colors.alpha(Colors.accent, 0.88))
                                : Colors.alpha(Colors.bgAlt, 0.6)
                            Behavior on color { ColorAnimation { duration: Motion.fast } }

                            scale: goTap.pressed ? 0.96 : 1
                            Behavior on scale { Spring {} }

                            HoverHandler { id: goHover; enabled: go.armed }
                            TapHandler {
                                id: goTap
                                enabled: go.armed
                                onTapped: {
                                    Sfx.tap();
                                    Printing.submit();
                                }
                            }

                            Row {
                                anchors.centerIn: parent
                                spacing: 9

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: Printing.sending ? "󰔟" : "󰐪"
                                    color: go.armed ? Colors.accentText : Colors.fgDim
                                    opacity: go.armed ? 1 : 0.5
                                    font.family: root.mono
                                    font.pixelSize: 15
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: I18n.t(Printing.sending ? "print.sending" : "print.go")
                                    color: go.armed ? Colors.accentText : Colors.fgDim
                                    opacity: go.armed ? 1 : 0.5
                                    font.family: Fonts.display
                                    font.pixelSize: Fonts.bodySize
                                    font.weight: Font.DemiBold
                                }
                            }
                        }
                    }
                }
            }

            Keys.onReturnPressed: if (Printing.doc) Printing.submit()
            Keys.onEnterPressed: if (Printing.doc) Printing.submit()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Backspace && Printing.doc) {
                    Printing.drop();
                    event.accepted = true;
                }
            }
        }
    }

    function inRange(page) {
        const r = Printing.range.trim();
        if (r === "" || !Printing.rangeValid)
            return true;

        for (const part of r.split(",")) {
            const bits = part.split("-");
            const from = parseInt(bits[0], 10);
            if (!isFinite(from))
                continue;
            if (bits.length === 1) {
                if (page === from)
                    return true;
                continue;
            }
            const to = bits[1] === "" ? Infinity : parseInt(bits[1], 10);
            if (page >= from && page <= to)
                return true;
        }
        return false;
    }
}
