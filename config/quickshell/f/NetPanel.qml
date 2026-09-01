import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import QtQuick
import QtQuick.Effects

Scope {
    id: root

    property bool shown: false
    property string tab: "wifi"
    property bool graphMode: true
    property string pendingSsid: ""

    readonly property string mono: "JetBrainsMono Nerd Font"
    readonly property int slotCount: 8

    function open(which) {
        if (which) root.tab = which;
        root.shown = true;
    }

    function toggle(which) {
        if (root.shown && (!which || which === root.tab)) {
            root.close();
            return;
        }
        root.open(which);
    }

    function close() { root.shown = false; }

    onShownChanged: {
        if (shown) {
            root.pendingSsid = "";
            password.text = "";
            Network.refresh();
            Network.rescan();
            Bt.refresh();
        }
        Network.sampling = shown && root.tab === "wifi";
        Bt.setScanning(shown && root.tab === "bt");
    }

    onTabChanged: {
        root.pendingSsid = "";
        Network.sampling = root.shown && root.tab === "wifi";
        Bt.setScanning(root.shown && root.tab === "bt");
        if (root.shown && root.tab === "wifi") Network.rescan();
    }

    readonly property bool wifiTab: root.tab === "wifi"

    property color tint: root.wifiTab ? Colors.accent : Colors.accentAlt
    Behavior on tint { ColorAnimation { duration: 300; easing.type: Easing.OutCubic } }

    readonly property bool radioOn: root.wifiTab ? Network.radio : Bt.powered
    readonly property bool live: root.wifiTab ? Network.connected : Bt.connectedCount > 0

    readonly property var allEntries: root.wifiTab
        ? (Network.radio ? Network.networks : [])
        : (Bt.powered ? Bt.devices : [])

    readonly property var orbitEntries: {
        const src = root.allEntries;
        const out = [];
        for (let i = 0; i < src.length && out.length < root.slotCount; i++) {
            const e = src[i];
            const isHub = root.wifiTab ? !!e.active : !!e.connected;
            if (isHub && root.live) continue;
            out.push(e);
        }
        return out;
    }

    readonly property var orbitModel: {
        const out = [];
        for (const e of root.orbitEntries) {
            if (root.wifiTab) {
                out.push({
                    title: e.ssid,
                    detail: e.strength + "%",
                    bars: Math.max(1, Math.min(4, Math.ceil(e.strength / 25))),
                    weight: e.strength / 100,
                    active: !!e.active,
                    working: false,
                    locked: !!e.secured && !e.active,
                    ref: e
                });
            } else {
                const connecting = e.state === 3 || !!e.pairing;
                out.push({
                    title: Bt.label(e),
                    detail: e.connected
                        ? (e.batteryAvailable
                            ? Math.round(e.battery * 100) + "%" : "вкл")
                        : (e.paired || e.bonded) ? "пара" : "новое",
                    glyph: Bt.icon(e),
                    bars: -1,
                    weight: e.connected ? 1.0 : (e.paired || e.bonded) ? 0.7 : 0.35,
                    active: !!e.connected,
                    working: connecting || e.state === 2,
                    locked: false,
                    ref: e
                });
            }
        }
        return out;
    }

    readonly property int hiddenCount:
        Math.max(0, root.allEntries.length - root.orbitEntries.length
                    - (root.live ? 1 : 0))

    readonly property string hubGlyph: root.wifiTab
        ? Network.glyph
        : (Bt.primary ? Bt.icon(Bt.primary) : Bt.glyph)

    readonly property string hubTitle: {
        if (root.wifiTab)
            return Network.connected ? Network.ssid
                 : Network.radio ? "не подключено" : "Wi-Fi выключен";
        if (!Bt.present) return "нет адаптера";
        if (!Bt.powered) return "Bluetooth выключен";
        return Bt.primary ? Bt.label(Bt.primary) : "нет подключений";
    }

    readonly property string hubSub: {
        if (root.wifiTab) {
            if (!Network.connected)
                return Network.radio ? Network.networks.length + " сетей рядом" : "";
            const parts = [Network.strength + "%"];
            if (Network.linkRate !== "") parts.push(Network.linkRate);
            return parts.join("  ·  ");
        }
        if (!Bt.powered) return "";
        if (Bt.connectedCount > 1) return Bt.connectedCount + " устройства";
        if (Bt.primary)
            return Bt.primary.batteryAvailable
                ? "батарея " + Math.round(Bt.primary.battery * 100) + "%"
                : "подключено";
        return Bt.devices.length + " рядом";
    }

    property var hoveredEntry: null

    readonly property var focus: root.graphMode ? root.hoveredEntry : null

    readonly property string focusTitle:
        root.focus ? (root.wifiTab ? root.focus.ssid : Bt.label(root.focus))
                   : root.hubTitle

    readonly property string focusSub: {
        const e = root.focus;
        if (!e) return root.hubSub;

        const bits = [];
        if (root.wifiTab) {
            bits.push("сигнал " + e.strength + "%");
            bits.push(e.secured ? "защищена" : "открытая");
            bits.push(e.active ? "нажми, чтобы отключиться"
                               : e.secured ? "нажми — спросит пароль"
                                           : "нажми, чтобы подключиться");
        } else {
            if (e.connected) bits.push("подключено");
            else if (e.paired || e.bonded) bits.push("сопряжено");
            else bits.push("не сопряжено");
            if (e.batteryAvailable)
                bits.push("батарея " + Math.round(e.battery * 100) + "%");
            if (e.address) bits.push(String(e.address).toLowerCase());
            bits.push(e.connected ? "нажми, чтобы отключить"
                                  : (e.paired || e.bonded) ? "нажми, чтобы подключить"
                                                           : "нажми, чтобы сопрячь");
        }
        return bits.join("  ·  ");
    }

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win
        WlrLayershell.namespace: "qs-net"
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: "#000000"
            opacity: root.shown ? 0.38 : 0
            Behavior on opacity { NumberAnimation { duration: 220 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        Item {
            id: cardHost
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.height * 0.10
            width: card.width
            height: card.height

            opacity: root.shown ? 1 : 0
            scale: root.shown ? 1 : 0.94
            Behavior on opacity { NumberAnimation { duration: 200 } }
            Behavior on scale {
                NumberAnimation { duration: 340; easing.type: Easing.OutBack; easing.overshoot: 0.8 }
            }

            Item {
                anchors.fill: parent
                z: -1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowVerticalOffset: 12
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
                width: 640
                height: header.height + stage.height + caption.height + footer.height + 56
                radius: 28

                gradient: Gradient {
                    GradientStop { position: 0.0
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.96) }
                    GradientStop { position: 0.5
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.985) }
                    GradientStop { position: 1.0
                        color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.99) }
                }

                border.width: 1
                border.color: root.alpha(root.tint, 0.26)

                Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                focus: true
                Keys.onEscapePressed: {
                    if (root.pendingSsid !== "") root.pendingSsid = "";
                    else root.close();
                }
                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Tab) {
                        root.tab = root.wifiTab ? "bt" : "wifi";
                        event.accepted = true;
                    }
                }

                Canvas {
                    id: glow
                    width: 520
                    height: 520
                    x: card.width / 2 - width / 2
                    y: header.height + stage.height / 2 - height / 2 + 10
                    opacity: root.radioOn ? 1 : 0.35
                    visible: root.graphMode
                    Behavior on opacity { NumberAnimation { duration: 300 } }

                    Connections {
                        target: root
                        function onTintChanged() { glow.requestPaint(); }
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const r = width / 2;
                        const g = ctx.createRadialGradient(r, r, r * 0.05, r, r, r);
                        g.addColorStop(0.0, Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.20));
                        g.addColorStop(0.45, Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.09));
                        g.addColorStop(1.0, Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.0));
                        ctx.fillStyle = g;
                        ctx.beginPath();
                        ctx.arc(r, r, r, 0, Math.PI * 2);
                        ctx.fill();
                    }

                    SequentialAnimation on scale {
                        running: root.shown && root.graphMode
                        loops: Animation.Infinite
                        NumberAnimation { from: 0.92; to: 1.06; duration: 4200; easing.type: Easing.InOutSine }
                        NumberAnimation { from: 1.06; to: 0.92; duration: 4200; easing.type: Easing.InOutSine }
                    }
                }

                Item {
                    id: header
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    anchors.margins: 20
                    height: 40

                    Rectangle {
                        id: powerChip
                        width: powerRow.implicitWidth + 26
                        height: 36
                        radius: 13
                        color: root.radioOn ? root.alpha(root.tint, 0.18)
                                            : root.alpha(Colors.bgAlt, 0.7)
                        border.width: 1
                        border.color: root.radioOn ? root.alpha(root.tint, 0.42)
                                                   : root.alpha(Colors.outline, 0.18)
                        Behavior on color { ColorAnimation { duration: 220 } }

                        Row {
                            id: powerRow
                            anchors.centerIn: parent
                            spacing: 9

                            Text {
                                text: root.wifiTab ? "󰖩" : "󰂯"
                                color: root.radioOn ? root.tint : Colors.fgDim
                                opacity: root.radioOn ? 1 : 0.55
                                font.family: root.mono
                                font.pixelSize: 14
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Text {
                                text: root.radioOn ? "включён" : "выключен"
                                color: root.radioOn ? Colors.fg : Colors.fgDim
                                opacity: root.radioOn ? 0.9 : 0.55
                                font.family: root.mono
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            Rectangle {
                                width: 34
                                height: 18
                                radius: 9
                                anchors.verticalCenter: parent.verticalCenter
                                color: root.radioOn ? root.alpha(root.tint, 0.45)
                                                    : root.alpha(Colors.outline, 0.25)
                                Behavior on color { ColorAnimation { duration: 200 } }

                                Rectangle {
                                    width: 13
                                    height: 13
                                    radius: 7
                                    y: 2.5
                                    x: root.radioOn ? parent.width - width - 3 : 3
                                    color: root.radioOn ? Colors.fg : Colors.fgDim
                                    Behavior on x {
                                        NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                                    }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (root.wifiTab) Network.toggleRadio();
                                else Bt.togglePower();
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        IconButton {
                            glyph: root.graphMode ? "󰋚" : "󰝤"
                            tint: root.tint
                            mono: root.mono
                            tip: root.graphMode ? "списком" : "схемой"
                            onActivated: root.graphMode = !root.graphMode
                        }

                        IconButton {
                            glyph: "󰑐"
                            tint: root.tint
                            mono: root.mono
                            spinning: root.wifiTab ? Network.busy : Bt.scanning
                            tip: "поиск"
                            onActivated: {
                                if (root.wifiTab) { Network.refresh(); Network.rescan(); }
                                else { Bt.setScanning(true); Bt.refresh(); }
                            }
                        }
                    }
                }

                Item {
                    id: stage
                    anchors { top: header.bottom; left: parent.left; right: parent.right }
                    anchors.topMargin: 6
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    height: root.graphMode
                        ? 456
                        : Math.max(180, Math.min(8 * 52 - 4, listView.contentHeight))
                    clip: true

                    Behavior on height { NumberAnimation { duration: 280; easing.type: Easing.OutCubic } }

                    OrbitGraph {
                        id: constellation
                        anchors.fill: parent
                        anchors.margins: 6
                        visible: opacity > 0.01
                        opacity: root.graphMode && root.radioOn ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 220 } }

                        model: root.orbitModel
                        tint: root.tint
                        mono: root.mono

                        hubGlyph: root.hubGlyph
                        hubLive: root.live
                        busy: root.wifiTab ? Network.busy : Bt.scanning

                        onPicked: item => root.activate(item.ref)
                        onHoveredItemChanged: root.hoveredEntry = hoveredItem ? hoveredItem.ref : null
                    }

                    ListView {
                        id: listView
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 4
                        boundsBehavior: Flickable.StopAtBounds
                        visible: opacity > 0.01
                        opacity: !root.graphMode && root.radioOn ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 220 } }

                        model: root.allEntries

                        delegate: NetRow {
                            required property var modelData
                            width: listView.width
                            entry: modelData
                            wifi: root.wifiTab
                            tint: root.tint
                            mono: root.mono
                            expanded: root.wifiTab && root.pendingSsid === modelData.ssid
                            onActivated: root.activate(modelData)
                            onForgetRequested: {
                                if (!root.wifiTab) Bt.forget(modelData);
                            }
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 12
                        visible: !root.radioOn || root.allEntries.length === 0

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: root.wifiTab ? "󰤮" : "󰂲"
                            color: Colors.fgDim
                            opacity: 0.22
                            font.family: root.mono
                            font.pixelSize: 54
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: {
                                if (!root.wifiTab && !Bt.present)
                                    return "Bluetooth-адаптер не найден";
                                if (!root.radioOn)
                                    return root.wifiTab ? "Wi-Fi выключен"
                                                        : "Bluetooth выключен";
                                if (!root.wifiTab && Bt.scanning) return "ищу устройства…";
                                return root.wifiTab ? "сетей не найдено" : "устройств нет";
                            }
                            color: Colors.fgDim
                            opacity: 0.5
                            font.family: root.mono
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: root.alpha(Colors.bg, 0.75)
                        visible: opacity > 0.01
                        opacity: root.pendingSsid !== "" ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 200 } }

                        MouseArea { anchors.fill: parent }

                        Column {
                            anchors.centerIn: parent
                            width: 340
                            spacing: 16

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "󰌾"
                                color: root.tint
                                font.family: root.mono
                                font.pixelSize: 32
                            }

                            Text {
                                width: parent.width
                                horizontalAlignment: Text.AlignHCenter
                                text: root.pendingSsid
                                color: Colors.fg
                                elide: Text.ElideRight
                                font.family: root.mono
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Rectangle {
                                width: parent.width
                                height: 46
                                radius: 15
                                color: root.alpha(Colors.bgAlt, 0.85)
                                border.width: 1
                                border.color: password.activeFocus
                                    ? root.alpha(root.tint, 0.6)
                                    : root.alpha(Colors.outline, 0.18)
                                Behavior on border.color { ColorAnimation { duration: 160 } }

                                Row {
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    TextInput {
                                        id: password
                                        width: parent.width - 52
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: Colors.fg
                                        font.family: root.mono
                                        font.pixelSize: 14
                                        echoMode: TextInput.Password
                                        passwordCharacter: "•"
                                        selectByMouse: true
                                        clip: true

                                        onAccepted: root.submitPassword()
                                        Keys.onEscapePressed: {
                                            root.pendingSsid = "";
                                            card.forceActiveFocus();
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            visible: password.text === ""
                                            text: "пароль"
                                            color: Colors.fgDim
                                            opacity: 0.35
                                            font.family: root.mono
                                            font.pixelSize: 13
                                        }
                                    }

                                    Rectangle {
                                        width: 34
                                        height: 30
                                        radius: 11
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: password.text === ""
                                            ? "transparent" : root.alpha(root.tint, 0.28)
                                        Behavior on color { ColorAnimation { duration: 160 } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: "󰌑"
                                            color: password.text === "" ? Colors.fgDim : root.tint
                                            opacity: password.text === "" ? 0.3 : 1
                                            font.family: root.mono
                                            font.pixelSize: 14
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: root.submitPassword()
                                        }
                                    }
                                }
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "esc — отмена"
                                color: Colors.fgDim
                                opacity: 0.35
                                font.family: root.mono
                                font.pixelSize: 10
                            }
                        }
                    }
                }

                Column {
                    id: caption
                    anchors { top: stage.bottom; left: parent.left; right: parent.right }
                    anchors.topMargin: 4
                    anchors.leftMargin: 40
                    anchors.rightMargin: 40
                    height: 42
                    spacing: 3

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        text: root.focusTitle
                        color: Colors.fg
                        elide: Text.ElideRight
                        font.family: root.mono
                        font.pixelSize: 15
                        font.weight: Font.DemiBold

                        Behavior on opacity { NumberAnimation { duration: 140 } }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        visible: text !== ""
                        text: root.focusSub
                        color: (root.hoveredEntry || root.live)
                            ? root.tint : Colors.fgDim
                        opacity: (root.hoveredEntry || root.live) ? 0.85 : 0.45
                        elide: Text.ElideRight
                        font.family: root.mono
                        font.pixelSize: 11
                    }
                }

                Item {
                    id: footer
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    anchors.margins: 20
                    height: 42

                    Rectangle {
                        id: tabs
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: 260
                        height: 40
                        radius: 14
                        color: root.alpha(Colors.bgAlt, 0.55)
                        border.width: 1
                        border.color: root.alpha(Colors.outline, 0.14)

                        Rectangle {
                            width: (parent.width - 8) / 2
                            height: parent.height - 8
                            y: 4
                            x: root.wifiTab ? 4 : parent.width - width - 4
                            radius: 11
                            color: root.alpha(root.tint, 0.24)
                            border.width: 1
                            border.color: root.alpha(root.tint, 0.42)
                            Behavior on x {
                                NumberAnimation { duration: 300; easing.type: Easing.OutBack; easing.overshoot: 0.7 }
                            }
                        }

                        Row {
                            anchors.fill: parent
                            anchors.margins: 4

                            Repeater {
                                model: [
                                    { key: "wifi", icon: "󰖩", label: "Wi-Fi" },
                                    { key: "bt",   icon: "󰂯", label: "Bluetooth" }
                                ]

                                Item {
                                    required property var modelData
                                    width: (tabs.width - 8) / 2
                                    height: parent.height

                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 7

                                        Text {
                                            text: modelData.icon
                                            color: root.tab === modelData.key ? root.tint : Colors.fgDim
                                            opacity: root.tab === modelData.key ? 1 : 0.55
                                            font.family: root.mono
                                            font.pixelSize: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        Text {
                                            text: modelData.label
                                            color: root.tab === modelData.key ? Colors.fg : Colors.fgDim
                                            opacity: root.tab === modelData.key ? 1 : 0.55
                                            font.family: root.mono
                                            font.pixelSize: 12
                                            font.weight: root.tab === modelData.key
                                                ? Font.DemiBold : Font.Normal
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.tab = modelData.key
                                    }
                                }
                            }
                        }
                    }

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        width: (parent.width - tabs.width) / 2 - 14
                        text: Network.error !== "" ? Network.error
                            : Bt.error !== "" ? Bt.error
                            : root.hiddenCount > 0 && root.graphMode
                                ? "+" + root.hiddenCount + " в списке"
                                : ""
                        color: (Network.error !== "" || Bt.error !== "") ? Colors.bad : Colors.fgDim
                        opacity: (Network.error !== "" || Bt.error !== "") ? 0.95 : 0.4
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                        font.family: root.mono
                        font.pixelSize: 10
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        horizontalAlignment: Text.AlignRight
                        text: "tab · esc"
                        color: Colors.fgDim
                        opacity: 0.3
                        font.family: root.mono
                        font.pixelSize: 10
                    }
                }
            }
        }
    }

    function activate(entry) {
        if (!entry) return;
        if (!root.wifiTab) {
            Bt.toggleDevice(entry);
            return;
        }
        if (entry.active) {
            Network.disconnect();
            return;
        }
        if (entry.secured) {
            root.pendingSsid = entry.ssid;
            password.text = "";
            password.forceActiveFocus();
            return;
        }
        Network.connect(entry.ssid, "");
    }

    function submitPassword() {
        if (root.pendingSsid === "") return;
        Network.connect(root.pendingSsid, password.text);
        root.pendingSsid = "";
        password.text = "";
    }
}
