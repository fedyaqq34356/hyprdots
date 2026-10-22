import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: deck

    required property var c
    readonly property bool open: deck.c.shown && deck.c.isle

    property int index: 0

    readonly property var results: {
        const q = input.text.trim().toLowerCase();
        const all = NotifHistory.items;
        if (q === "")
            return all;
        return all.filter(e => (e.summary + " " + e.body + " " + e.app).toLowerCase().includes(q));
    }
    readonly property var entry: deck.results.length > 0
        ? deck.results[Math.max(0, Math.min(deck.index, deck.results.length - 1))] : null
    readonly property int rest: Math.max(0, deck.results.length - deck.index - 1)

    onOpenChanged: {
        if (deck.open) {
            input.text = "";
            deck.index = 0;
            input.forceActiveFocus();
        }
    }

    function step(d) {
        const n = deck.results.length;
        if (n === 0)
            return;
        const next = Math.max(0, Math.min(n - 1, deck.index + d));
        face.dir = d;
        lean.target = d;
        leanBack.restart();
        if (next !== deck.index) {
            deck.index = next;
            Sfx.tapAlt();
        }
    }

    function openEntry() {
        const e = deck.entry;
        if (!e)
            return;
        const app = (e.app || "").toLowerCase();
        const de = DesktopEntries.heuristicLookup(e.app);
        const cls = /telegram/.test(app) ? "org.telegram.desktop"
                  : de && de.startupClass ? de.startupClass
                  : de ? de.id : app.split(/\s+/)[0];
        Quickshell.execDetached(["hyprdo", "dispatch", "focuswindow", "class:(?i)" + cls]);
        deck.c.close();
    }

    function imageOf(e) {
        const i = e ? e.image || "" : "";
        return i.startsWith("/") ? "file://" + i : i.startsWith("file:") ? i : "";
    }
    function iconOf(e) {
        if (!e)
            return "";
        let i = e.icon || "";
        if (i === "") {
            const de = DesktopEntries.heuristicLookup(e.app) || deck.entryByName(e.app);
            i = de && de.icon ? de.icon : "";
        }
        if (i === "")
            return "";
        return i.startsWith("/") ? "file://" + i : i.startsWith("file:") || i.startsWith("image:") ? "" : Quickshell.iconPath(i, true);
    }
    function entryByName(app) {
        const key = (app || "").toLowerCase().trim();
        const first = key.split(/\s+/)[0] || "";
        if (first.length < 3)
            return null;
        const list = DesktopEntries.applications.values;
        for (let i = 0; i < list.length; i++) {
            const e = list[i];
            if ((e.name || "").toLowerCase() === first || (e.id || "").toLowerCase().includes(first))
                return e;
        }
        return null;
    }

    property bool sipping: false
    function drop() {
        if (!deck.entry || deck.sipping)
            return;
        deck.sipping = true;
        sip.target = 1;
        Sfx.swoosh();
        sipDone.restart();
    }
    Timer {
        id: sipDone
        interval: 360
        onTriggered: {
            if (deck.entry)
                NotifHistory.removeId(deck.entry.id);
            if (deck.index >= deck.results.length)
                deck.index = Math.max(0, deck.results.length - 1);
            face.dir = 1;
            sip.target = 0;
            deck.sipping = false;
        }
    }

    readonly property bool talk: deck.open || drip.holding
    Binding { target: IslandBus; property: "searching"; value: deck.talk }
    Binding { target: IslandBus; property: "searchScreen"; value: win.screen ? win.screen.name : ""; when: deck.talk }
    Binding { target: IslandBus; property: "query"; value: input.text; when: deck.talk }
    Binding { target: IslandBus; property: "cursor"; value: input.cursorPosition; when: deck.talk }
    Binding { target: IslandBus; property: "mode"; value: "notif"; when: deck.talk }
    Binding {
        target: IslandBus; property: "hint"; when: deck.talk
        value: deck.results.length > 0 ? (Math.min(deck.index, deck.results.length - 1) + 1) + " / " + deck.results.length
             : input.text.trim() !== "" ? "No matches" : ""
    }
    Binding { target: IslandBus; property: "hintGlyph"; value: ""; when: deck.talk }
    Binding { target: IslandBus; property: "hue"; value: drip.glow; when: deck.talk }
    Binding { target: IslandBus; property: "hueOn"; value: true; when: deck.talk }

    property int lastLen: 0
    Connections {
        target: input
        function onTextChanged() {
            const n = input.text.length;
            if (deck.open && n !== deck.lastLen)
                IslandBus.keyed(n > deck.lastLen ? 1 : -1);
            deck.lastLen = n;
            deck.index = 0;
        }
    }

    HyprlandFocusGrab {
        active: deck.open
        windows: [win]
        onCleared: deck.c.close()
    }

    PanelWindow {
        id: win
        WlrLayershell.namespace: "qs-notifdeck"
        screen: Focus.screen
        visible: deck.open || drip.living
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: -1
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "black"
            opacity: deck.open ? 0.16 : 0
            Behavior on opacity { NumberAnimation { duration: 260 } }
            MouseArea {
                anchors.fill: parent
                onClicked: deck.c.close()
            }
        }

        TextInput {
            id: input
            x: -10000
            width: 10
            focus: true
            Keys.onEscapePressed: {
                if (input.text !== "") input.text = "";
                else deck.c.close();
            }
            Keys.onLeftPressed: deck.step(-1)
            Keys.onRightPressed: deck.step(1)
            Keys.onUpPressed: deck.step(-1)
            Keys.onDownPressed: deck.step(1)
            Keys.onReturnPressed: deck.openEntry()
            Keys.onEnterPressed: deck.openEntry()
            Keys.onDeletePressed: deck.drop()
        }

        Item {
            id: drip
            anchors.fill: parent

            readonly property bool known: IslandBus.isleW > 0
            readonly property real cx: drip.known ? IslandBus.isleX + IslandBus.isleW / 2 : drip.width / 2
            readonly property real base: drip.known ? IslandBus.isleY + IslandBus.isleH : 47
            readonly property real isleW: drip.known ? IslandBus.isleW : IslandBus.searchW

            MorphSpring {
                id: life
                response: 0.72
                damping: 0.96
                closeMs: 420
                softClose: true
                target: deck.open ? 1 : 0
            }
            MorphSpring {
                id: sip
                response: 0.5
                damping: 0.95
                closeMs: 300
                softClose: true
                springBack: true
                target: 0
            }
            MorphSpring {
                id: lean
                springBack: true
                response: 0.42
                damping: 0.9
                epsilon: 0.002
                target: 0
            }
            Timer { id: leanBack; interval: 110; onTriggered: lean.target = 0 }

            readonly property real g: Math.max(0, life.value) * (1 - Math.max(0, Math.min(1, sip.value)))
            readonly property bool living: life.value > 0.005 || deck.open
            readonly property bool holding: !deck.open && life.value > 0.12

            readonly property real cardW: 540
            readonly property real wantH: deck.entry ? Math.max(130, Math.min(300, bodyCol.implicitHeight + 64)) : 110
            property real shownH: drip.wantH
            Behavior on shownH { NumberAnimation { duration: 480; easing.type: Easing.InOutCubic } }

            readonly property real bw: Motion.mix(drip.isleW * 0.42, drip.cardW, drip.g)
                                       * (1 + 0.05 * Math.abs(lean.value))
            readonly property real bh: Motion.mix(18, drip.shownH, drip.g)
                                       * (1 - 0.03 * Math.abs(lean.value))
            readonly property real by: Motion.mix(drip.base - 16, drip.base + 12, drip.g)
            readonly property real bx: drip.cx - drip.bw / 2 + 18 * lean.value

            ArtTint {
                id: art
                x: drip.cx
                y: 0
                source: deck.imageOf(face.e) !== "" ? deck.imageOf(face.e) : deck.iconOf(face.e)
                fallback: Colors.accent
            }
            readonly property color hue: face.e && face.e.critical ? Colors.bad
                : art.found ? art.color : face.e ? NotifHistory.appColor(face.e.app) : Colors.accent
            property color glow: drip.hue
            Behavior on glow { ColorAnimation { duration: 900; easing.type: Easing.InOutCubic } }

            RectangularShadow {
                x: drip.bx
                y: drip.by + 10
                width: drip.bw
                height: drip.bh
                radius: 34
                blur: 70
                spread: -6
                color: Colors.alpha(drip.glow, 0.30)
                opacity: drip.g
                visible: opacity > 0.01
            }

            Item {
                id: host
                x: drip.cx - 360
                y: drip.base - 24
                width: 720
                height: 460

                Item {
                    property bool isBlob: true
                    width: Math.min(drip.isleW - 44, 260)
                    height: 8
                    x: drip.cx - width / 2 - host.x
                    y: drip.base - 8 - host.y
                    visible: drip.g > 0.005
                }

                Item {
                    property bool isBlob: true
                    width: drip.bw
                    height: drip.bh
                    x: drip.bx - host.x
                    y: drip.by - host.y
                    visible: drip.g > 0.005
                }

                Repeater {
                    model: 3
                    Item {
                        id: bead
                        required property int index
                        property bool isBlob: true
                        property real k: deck.rest > bead.index && deck.open ? 1 : 0
                        Behavior on k { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                        readonly property real size: (14 - bead.index * 3.5) * bead.k * drip.g
                        readonly property var drop: [4, 22, 36]
                        width: Math.max(0.1, bead.size)
                        height: Math.max(0.1, bead.size * 1.1)
                        x: drip.bx + drip.bw / 2 - width / 2 - host.x
                        y: drip.by + drip.bh + bead.drop[bead.index] * bead.k - bead.size / 2 - host.y
                        visible: bead.size > 1
                        onXChanged: goo.applySync()
                        onYChanged: goo.applySync()
                        onWidthChanged: goo.applySync()
                        onVisibleChanged: goo.applySync()
                    }
                }
            }

            onBxChanged: goo.applySync()
            onByChanged: goo.applySync()
            onBwChanged: goo.applySync()
            onBhChanged: goo.applySync()
            onCxChanged: goo.applySync()

            Blobs {
                id: goo
                host: host
                fuse: 22
                corner: 28
                stroke: 0
                shadow: false
                fillColor: "black"
                fillAlpha: 1
                hoverColor: "black"
                hoverAlpha: 1
                strokeAlpha: 0
                visible: count > 0 && drip.g > 0.005
            }

            ClippingRectangle {
                id: card
                x: drip.bx
                y: drip.by
                width: drip.bw
                height: drip.bh
                radius: Math.min(28, height / 2)
                color: "transparent"
                opacity: Math.max(0, Math.min(1, (drip.g - 0.55) / 0.45))
                visible: opacity > 0.01

                readonly property real t: card.visible ? (Phase.ts % 10) / 10 * Math.PI * 2 : 0
                PhaseHold { active: card.visible; slow: true }

                RectangularShadow {
                    x: card.width * (0.10 + 0.10 * Math.sin(card.t)) - 40
                    y: card.height * (0.25 + 0.16 * Math.cos(card.t * 2)) - 50
                    width: 190
                    height: 140
                    radius: 70
                    blur: 80
                    color: Colors.alpha(drip.glow, 0.36)
                }
                RectangularShadow {
                    x: card.width * (0.62 + 0.14 * Math.cos(card.t)) - 40
                    y: card.height * (0.55 + 0.18 * Math.sin(card.t * 2 + 1)) - 60
                    width: 210
                    height: 150
                    radius: 75
                    blur: 90
                    color: Colors.alpha(Qt.lighter(drip.glow, 1.3), 0.16)
                }
                Rectangle {
                    anchors.top: parent.top
                    anchors.topMargin: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 80
                    height: 1
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: "transparent" }
                        GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.16) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }

                Item {
                    id: face
                    anchors.centerIn: parent
                    width: drip.cardW
                    height: drip.shownH

                    property var e: null
                    property int dir: 1
                    property real shift: 0
                    property real haze: 0
                    readonly property string wantKey: deck.entry ? deck.entry.id + "@" + deck.entry.time : ""

                    onWantKeyChanged: {
                        if (face.e === null || !deck.entry) {
                            face.e = deck.entry;
                            faceIn.restart();
                            return;
                        }
                        swap.restart();
                    }

                    transform: Translate { x: face.shift }
                    layer.enabled: face.haze > 0.01
                    layer.effect: MultiEffect {
                        blurEnabled: true
                        blurMax: 32
                        blur: face.haze
                        autoPaddingEnabled: false
                    }

                    SequentialAnimation {
                        id: swap
                        ParallelAnimation {
                            NumberAnimation { target: face; property: "opacity"; to: 0; duration: 170; easing.type: Easing.InCubic }
                            NumberAnimation { target: face; property: "shift"; to: 26 * face.dir; duration: 170; easing.type: Easing.InCubic }
                            NumberAnimation { target: face; property: "haze"; to: 1; duration: 170 }
                        }
                        ScriptAction { script: face.e = deck.entry }
                        ScriptAction { script: faceIn.restart() }
                    }
                    ParallelAnimation {
                        id: faceIn
                        NumberAnimation { target: face; property: "opacity"; from: 0; to: 1; duration: 420; easing.type: Easing.OutCubic }
                        NumberAnimation { target: face; property: "shift"; from: -30 * face.dir; to: 0; duration: 520; easing.type: Easing.OutCubic }
                        NumberAnimation { target: face; property: "haze"; from: 1; to: 0; duration: 420; easing.type: Easing.OutCubic }
                    }

                    Column {
                        anchors.centerIn: parent
                        visible: face.e === null
                        spacing: 8
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "󰂛"
                            color: Qt.rgba(1, 1, 1, 0.35)
                            font.family: Fonts.glyph
                            font.pixelSize: Fonts.bigger
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: I18n.t("notif.empty")
                            color: Qt.rgba(1, 1, 1, 0.45)
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.medium
                        }
                    }

                    Item {
                        id: avatar
                        visible: face.e !== null
                        x: 26
                        y: 24
                        width: 44
                        height: 44

                        RectangularShadow {
                            anchors.centerIn: parent
                            width: 36
                            height: 36
                            radius: 18
                            blur: 22
                            color: Colors.alpha(drip.glow, 0.6)
                        }
                        Rectangle {
                            anchors.fill: parent
                            radius: 22
                            color: Colors.alpha(drip.glow, 0.18)
                            border.width: 1
                            border.color: Colors.alpha(drip.glow, 0.4)
                        }
                        ClippingRectangle {
                            anchors.fill: parent
                            anchors.margins: 1
                            radius: width / 2
                            color: "transparent"
                            visible: deck.imageOf(face.e) !== ""
                            Image {
                                anchors.fill: parent
                                source: deck.imageOf(face.e)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                sourceSize.width: 96
                            }
                        }
                        IconImage {
                            anchors.centerIn: parent
                            implicitSize: 26
                            visible: deck.imageOf(face.e) === "" && deck.iconOf(face.e) !== ""
                            source: deck.imageOf(face.e) === "" ? deck.iconOf(face.e) : ""
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: face.e !== null && deck.imageOf(face.e) === "" && deck.iconOf(face.e) === ""
                            text: face.e ? NotifHistory.appLetter(face.e.app) : ""
                            color: Qt.lighter(drip.glow, 1.3)
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.large
                            font.weight: Font.DemiBold
                        }
                    }

                    Column {
                        id: bodyCol
                        visible: face.e !== null
                        anchors.left: avatar.right
                        anchors.leftMargin: 16
                        anchors.right: parent.right
                        anchors.rightMargin: 28
                        y: 24
                        spacing: 6

                        Row {
                            spacing: 8
                            Text {
                                text: face.e ? face.e.app : ""
                                color: Qt.lighter(drip.glow, 1.35)
                                font.family: Fonts.display
                                font.features: { "tnum": 1 }
                                font.pixelSize: Fonts.text
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: face.e ? "· " + NotifHistory.ago(face.e.time) : ""
                                color: Qt.rgba(1, 1, 1, 0.4)
                                font.family: Fonts.display
                                font.features: { "tnum": 1 }
                                font.pixelSize: Fonts.text
                            }
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: face.e ? face.e.summary : ""
                            color: "white"
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.large
                            font.weight: Font.DemiBold
                            wrapMode: Text.WordWrap
                            maximumLineCount: 2
                            elide: Text.ElideRight
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: face.e ? face.e.body : ""
                            color: Qt.rgba(1, 1, 1, 0.72)
                            font.family: Fonts.display
                            font.features: { "tnum": 1 }
                            font.pixelSize: Fonts.medium
                            lineHeight: 1.12
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 6
                            elide: Text.ElideRight
                        }
                    }
                }

                TapHandler { onTapped: deck.openEntry() }
                HoverHandler { cursorShape: Qt.PointingHandCursor }
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    property real acc: 0
                    onWheel: (ev) => {
                        acc += ev.angleDelta.y || ev.angleDelta.x;
                        if (Math.abs(acc) < 120 || wheelRest.running)
                            return;
                        deck.step(acc < 0 ? 1 : -1);
                        acc = 0;
                        wheelRest.restart();
                    }
                }
                Timer { id: wheelRest; interval: 220 }
            }
        }
    }
}
