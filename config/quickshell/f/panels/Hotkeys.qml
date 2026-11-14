import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property var screenOverride: null
    property string query: ""

    property var overrides: ({})
    property string editing: ""
    property var editMods: ({ SUPER: false, CTRL: false, ALT: false, SHIFT: false })
    property string editError: ""

    readonly property string mono: Fonts.mono
    readonly property bool ru: Prefs.language === "ru"
    readonly property string userPath: Quickshell.env("HOME") + "/.config/hypr/config/binds-user.conf"

    readonly property var groups: [
        { ru: "главное", en: "basics", items: [
            ["Super+D", "меню приложений", "app launcher"],
            ["Super+Enter", "терминал", "terminal"],
            ["Super+Tab", "обзор окон и столов", "overview"],
            ["Super+Q", "закрыть окно", "close window"],
            ["Alt+F4", "закрыть окно", "close window"],
            ["Super+F", "на весь экран", "fullscreen"],
            ["Super+Shift+F", "плавающее окно", "toggle floating"],
            ["Super+P", "выключение и перезагрузка", "power menu"],
            ["Super+Shift+L", "заблокировать экран", "lock screen"],
            ["Super+Shift+P", "настройки", "settings"],
            ["Super+/", "эта подсказка", "this cheat sheet"],
            ["Alt Shift", "сменить раскладку", "switch layout"]
        ] },
        { ru: "файлы и программы", en: "files and apps", items: [
            ["Super+E", "файлы в терминале", "terminal file manager"],
            ["Super+Shift+Y", "файлы в окне", "file manager"],
            ["Super+Shift+B", "панель файлов", "files panel"],
            ["Super+C", "калькулятор", "calculator"],
            ["Super+V", "буфер обмена", "clipboard"],
            ["Super+Shift+V", "очистить буфер", "wipe clipboard"],
            ["Super+W", "обои", "wallpapers"],
            ["Super+Shift+D", "календарь", "calendar"],
            ["Super+T", "таймер", "timer"],
            ["Super+Alt+T", "убрать таймер", "dismiss timer"]
        ] },
        { ru: "рабочие столы и окна", en: "workspaces and windows", items: [
            ["Super+1…9", "перейти на стол", "go to workspace"],
            ["Super+Shift+1…9", "перенести окно на стол", "move window to workspace"],
            ["Super+H/J/K/L", "фокус влево, вниз, вверх, вправо", "focus left, down, up, right"],
            ["Super+стрелки", "двигать окно", "move window"],
            ["Super+Shift+стрелки", "размер окна", "resize window"],
            ["Super+ЛКМ", "тащить окно", "drag window"],
            ["Super+ПКМ", "размер мышью", "resize with mouse"]
        ] },
        { ru: "скриншоты и запись", en: "capture", items: [
            ["Print", "область", "region"],
            ["Super+Shift+S", "область", "region"],
            ["Shift+Print", "область и рисовать", "region and edit"],
            ["Alt+Print", "окно", "window"],
            ["Ctrl+Print", "все экраны", "all screens"],
            ["Super+Print", "этот экран", "this screen"],
            ["Super+Shift+X", "область с размытием", "blurred region"],
            ["Super+Shift+T", "текст с экрана", "text from screen"],
            ["Super+Shift+C", "цвет с экрана", "pick color"],
            ["Super+Alt+Q", "QR-код", "QR code"],
            ["Super+Alt+G", "поиск по картинке", "image search"],
            ["Super+Alt+R", "запись экрана", "record screen"],
            ["Super+Alt+Shift+R", "запись области", "record region"]
        ] },
        { ru: "звук", en: "sound", items: [
            ["Super+= / -", "громкость", "volume"],
            ["Super+M", "микрофон вкл/выкл", "mute mic"],
            ["Super+Shift+= / -", "громкость микрофона", "mic volume"],
            ["Super+Shift+M", "панель звука", "audio panel"],
            ["Super+Shift+Q", "эквалайзер", "equalizer"],
            ["Super+A", "плеер", "media"]
        ] },
        { ru: "сеть и устройства", en: "network and devices", items: [
            ["Super+N", "Wi-Fi", "Wi-Fi"],
            ["Super+B", "Bluetooth", "Bluetooth"],
            ["Super+Ctrl+S", "скорость интернета", "network speed"],
            ["Super+Ctrl+D", "мониторы", "displays"],
            ["Super+Ctrl+P", "печать", "print"]
        ] },
        { ru: "уведомления", en: "notifications", items: [
            ["Super+Shift+N", "центр уведомлений", "notification center"],
            ["Super+Ctrl+N", "не беспокоить", "do not disturb"],
            ["Super+Ctrl+F", "режим фокуса", "focus mode"]
        ] },
        { ru: "система", en: "system", items: [
            ["Ctrl+Shift+Esc", "процессы", "processes"],
            ["Super+F1", "нагрузка", "system load"],
            ["Super+Shift+F4", "обновить систему", "update packages"],
            ["Super+Shift+F3", "очистить кэш", "clean cache"],
            ["Super+Shift+F5", "перезапустить панель", "reset panel"],
            ["Super+Shift+R", "перечитать настройки", "reload config"],
            ["Super+Shift+E", "выйти из сеанса", "log out"]
        ] },
        { ru: "вид", en: "look", items: [
            ["Super+Shift+I", "остров", "island"],
            ["Super+Shift+A", "док", "dock"],
            ["Super+Shift+J", "конструктор панели", "bar builder"],
            ["Super+Shift+W", "редактировать стол", "edit desktop"],
            ["Super+Shift+G", "рисовать на экране", "draw on screen"]
        ] }
    ]

    readonly property var modNames: ({ Super: "SUPER", Shift: "SHIFT", Ctrl: "CTRL", Alt: "ALT" })
    readonly property var keyNames: ({ Enter: "Return", Esc: "Escape", "/": "slash" })
    readonly property var prettyNames: ({ SUPER: "Super", SHIFT: "Shift", CTRL: "Ctrl", ALT: "Alt",
                                          Return: "Enter", Escape: "Esc", slash: "/", space: "Space" })

    function canon(display) {
        const parts = display.split("+");
        const out = [];
        for (let i = 0; i < parts.length; i++) {
            const p = parts[i];
            if (i < parts.length - 1) {
                if (!root.modNames[p])
                    return "";
                out.push(root.modNames[p]);
            } else {
                const k = root.keyNames[p] || p;
                if (!/^([A-Z0-9]|F[0-9]{1,2}|Tab|Print|Return|Escape|slash)$/.test(k))
                    return "";
                out.push(k);
            }
        }
        return out.join(" + ");
    }

    function pretty(c) {
        return c.split(" + ").map(p => root.prettyNames[p] || p).join("+");
    }

    function shownKey(display) {
        const c = root.canon(display);
        return c !== "" && root.overrides[c] ? root.pretty(root.overrides[c]) : display;
    }

    function comboId(c) {
        const parts = c.split(" + ");
        const k = parts.pop().toUpperCase();
        return parts.map(p => p.toUpperCase()).sort().join("+") + "|" + k;
    }

    function normKey(text) {
        const t = text.trim();
        if (t === "")
            return "";
        if (/^[a-zA-Z0-9]$/.test(t))
            return t.toUpperCase();
        if (/^[fF][0-9]{1,2}$/.test(t))
            return t.toUpperCase();
        const named = { "/": "slash", "enter": "Return", "esc": "Escape", "tab": "Tab",
                        "space": "space", "пробел": "space", "print": "Print" };
        return named[t.toLowerCase()] || "";
    }

    function startEdit(display) {
        const c = root.canon(display);
        if (c === "")
            return;
        if (root.editing === c) {
            root.editing = "";
            return;
        }
        const cur = (root.overrides[c] || c).split(" + ");
        cur.pop();
        root.editMods = { SUPER: cur.indexOf("SUPER") >= 0, CTRL: cur.indexOf("CTRL") >= 0,
                          ALT: cur.indexOf("ALT") >= 0, SHIFT: cur.indexOf("SHIFT") >= 0 };
        root.editError = "";
        root.editing = c;
        Sfx.pick();
    }

    function toggleMod(m) {
        const n = Object.assign({}, root.editMods);
        n[m] = !n[m];
        root.editMods = n;
        root.editError = "";
    }

    function save(keyText) {
        const k = root.normKey(keyText);
        if (k === "") {
            root.editError = root.ru ? "впиши одну букву, цифру или F1…F12" : "type one letter, digit or F1…F12";
            return;
        }
        const mods = ["SUPER", "CTRL", "ALT", "SHIFT"].filter(m => root.editMods[m]);
        const to = mods.concat([k]).join(" + ");
        const id = root.comboId(to);
        for (const g of root.groups) {
            for (const it of g.items) {
                const c = root.canon(it[0]);
                if (c === "" || c === root.editing)
                    continue;
                if (root.comboId(root.overrides[c] || c) === id) {
                    root.editError = (root.ru ? "уже занято: " : "already used: ") + (root.ru ? it[1] : it[2]);
                    return;
                }
            }
        }
        const n = Object.assign({}, root.overrides);
        if (id === root.comboId(root.editing))
            delete n[root.editing];
        else
            n[root.editing] = to;
        root.apply(n);
    }

    function reset() {
        const n = Object.assign({}, root.overrides);
        delete n[root.editing];
        root.apply(n);
    }

    function apply(n) {
        root.overrides = n;
        root.editing = "";
        root.editError = "";
        const lines = Object.keys(n).map(f => f + " = " + n[f]);
        userFile.setText(lines.length ? lines.join("\n") + "\n" : "");
        if (!root.screenOverride)
            reloader.running = true;
        Sfx.tapAlt();
    }

    function parse(text) {
        const n = {};
        for (const line of text.split("\n")) {
            const i = line.indexOf("=");
            if (i <= 0)
                continue;
            const from = line.slice(0, i).trim();
            const to = line.slice(i + 1).trim();
            if (from !== "" && to !== "")
                n[from] = to;
        }
        root.overrides = n;
    }

    FileView {
        id: userFile
        path: root.userPath
        printErrors: false
        onLoaded: root.parse(userFile.text())
        onLoadFailed: root.overrides = ({})
    }

    Process {
        id: reloader
        command: ["hyprctl", "reload"]
    }

    readonly property var shownGroups: {
        const q = root.query.trim().toLowerCase();
        const ov = root.overrides;
        const out = [];
        for (const g of root.groups) {
            const items = q === "" ? g.items : g.items.filter(it =>
                root.shownKey(it[0]).toLowerCase().indexOf(q) >= 0
                || it[1].toLowerCase().indexOf(q) >= 0
                || it[2].toLowerCase().indexOf(q) >= 0);
            if (items.length > 0)
                out.push({ title: root.ru ? g.ru : g.en, items: items });
        }
        return out;
    }

    function open() {
        root.query = "";
        root.editing = "";
        userFile.reload();
        root.shown = true;
        Sfx.tip();
    }

    function close() {
        if (!root.shown)
            return;
        root.shown = false;
        root.editing = "";
        Sfx.panelOut();
    }

    function toggle() {
        if (root.shown)
            root.close();
        else
            root.open();
    }

    HyprlandFocusGrab {
        active: root.shown && !root.screenOverride
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win

        WlrLayershell.namespace: "qs-keys"
        WlrLayershell.layer: WlrLayer.Overlay

        screen: root.screenOverride ? root.screenOverride : Focus.screen
        visible: root.shown
        focusable: true

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        exclusiveZone: -1
        color: "transparent"

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0, 0, 0, 0.45)
            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.slow } }

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

        Glass {
            id: card

            anchors.horizontalCenter: parent.horizontalCenter
            y: Math.max(60, (parent.height - height) / 2)
            width: Math.min(760, parent.width - 80)
            height: Math.min(720, parent.height - 120)
            radius: Shape.modal
            elevation: 3
            tintOpacity: 0.92

            opacity: emerge.on ? emerge.cardOpacity : (root.shown ? 1 : 0)
            scale: emerge.on ? 1 : (root.shown ? 1 : 0.94)
            transform: Translate { x: emerge.dx; y: emerge.dy }
            Behavior on opacity { enabled: !emerge.on; NumberAnimation { duration: Motion.base } }
            Behavior on scale {
                enabled: !emerge.on
                NumberAnimation {
                    duration: Motion.slow
                    easing.type: Easing.Bezier
                    easing.bezierCurve: Motion.expo
                }
            }

            MouseArea { anchors.fill: parent }

            Keys.onEscapePressed: {
                if (root.editing !== "")
                    root.editing = "";
                else
                    root.close();
            }

            Row {
                id: head

                x: 32
                y: 26
                spacing: 14

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰌌"
                    color: Colors.accent
                    font.family: root.mono
                    font.pixelSize: Fonts.big
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 2

                    Text {
                        text: root.ru ? "клавиши" : "keys"
                        color: Colors.fg
                        font.family: Fonts.display
                        font.pixelSize: Fonts.big
                    }

                    Text {
                        text: root.ru ? "нажми на строку, чтобы поменять" : "click a row to change it"
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: root.mono
                        font.pixelSize: Fonts.tiny
                    }
                }
            }

            Field {
                id: search

                anchors.right: parent.right
                anchors.rightMargin: 32
                anchors.verticalCenter: head.verticalCenter
                width: Math.min(260, card.width - head.width - 100)
                height: 38
                mono: root.mono
                placeholder: root.ru ? "поиск" : "search"
                onTextChanged: root.query = search.text
            }

            Connections {
                target: root
                function onShownChanged() {
                    if (root.shown) {
                        search.clear();
                        list.contentY = 0;
                        search.grab();
                    }
                }
            }

            Flickable {
                id: list

                anchors.fill: parent
                anchors.topMargin: 96
                anchors.leftMargin: 32
                anchors.rightMargin: 24
                anchors.bottomMargin: 20
                contentHeight: body.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: body

                    width: list.width - 8
                    spacing: 18

                    Text {
                        visible: root.shownGroups.length === 0
                        text: root.ru ? "ничего не найдено" : "nothing found"
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: root.mono
                        font.pixelSize: Fonts.small
                    }

                    Repeater {
                        model: root.shownGroups

                        Column {
                            id: group

                            required property var modelData

                            width: body.width
                            spacing: 4

                            Text {
                                text: group.modelData.title
                                color: Colors.accent
                                opacity: 0.85
                                font.family: root.mono
                                font.pixelSize: Fonts.tiny
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 1.2
                                bottomPadding: 4
                            }

                            Repeater {
                                model: group.modelData.items

                                Rectangle {
                                    id: row

                                    required property var modelData

                                    readonly property string code: root.canon(row.modelData[0])
                                    readonly property bool editable: row.code !== ""
                                    readonly property bool open: root.editing !== "" && root.editing === row.code
                                    readonly property bool changed: row.editable && !!root.overrides[row.code]

                                    width: group.width
                                    height: row.open ? 38 + editor.height + 10 : 30
                                    radius: 10
                                    color: row.open
                                        ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.55)
                                        : (hover.containsMouse && row.editable
                                           ? Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.35)
                                           : "transparent")
                                    Behavior on height { NumberAnimation { duration: Motion.base; easing.type: Easing.OutCubic } }

                                    MouseArea {
                                        id: hover
                                        width: parent.width
                                        height: 30
                                        hoverEnabled: true
                                        cursorShape: row.editable ? Qt.PointingHandCursor : Qt.ArrowCursor
                                        onClicked: {
                                            root.startEdit(row.modelData[0]);
                                            if (root.editing === row.code)
                                                keyField.grab();
                                        }
                                    }

                                    Row {
                                        x: 6
                                        y: 3
                                        spacing: 4

                                        Repeater {
                                            model: root.shownKey(row.modelData[0]).split("+")

                                            Rectangle {
                                                required property string modelData

                                                width: cap.implicitWidth + 16
                                                height: 24
                                                radius: 8
                                                color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                                               Colors.bgAlt.b, 0.75)
                                                border.width: 1
                                                border.color: row.changed
                                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.6)
                                                    : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)

                                                Text {
                                                    id: cap
                                                    anchors.centerIn: parent
                                                    text: parent.modelData
                                                    color: row.changed ? Colors.accent : Colors.accentAlt
                                                    font.family: root.mono
                                                    font.pixelSize: Fonts.tiny
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        x: 268
                                        height: 30
                                        width: parent.width - 268 - 10
                                        verticalAlignment: Text.AlignVCenter
                                        text: root.ru ? row.modelData[1] : row.modelData[2]
                                        color: Colors.fg
                                        opacity: 0.85
                                        elide: Text.ElideRight
                                        font.family: Fonts.display
                                        font.pixelSize: Fonts.small
                                    }

                                    Column {
                                        id: editor

                                        x: 6
                                        y: 38
                                        width: parent.width - 12
                                        spacing: 8
                                        visible: row.open

                                        Row {
                                            spacing: 6

                                            Repeater {
                                                model: ["SUPER", "CTRL", "ALT", "SHIFT"]

                                                Rectangle {
                                                    required property string modelData
                                                    readonly property bool on: !!root.editMods[modelData]

                                                    width: modLabel.implicitWidth + 22
                                                    height: 32
                                                    radius: 9
                                                    color: on
                                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.22)
                                                        : Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.7)
                                                    border.width: 1
                                                    border.color: on
                                                        ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.7)
                                                        : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.2)

                                                    Text {
                                                        id: modLabel
                                                        anchors.centerIn: parent
                                                        text: root.prettyNames[parent.modelData]
                                                        color: parent.on ? Colors.accent : Colors.fgDim
                                                        font.family: root.mono
                                                        font.pixelSize: Fonts.small
                                                    }

                                                    MouseArea {
                                                        anchors.fill: parent
                                                        cursorShape: Qt.PointingHandCursor
                                                        onClicked: root.toggleMod(parent.modelData)
                                                    }
                                                }
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: "+"
                                                color: Colors.fgDim
                                                font.family: root.mono
                                                font.pixelSize: Fonts.small
                                            }

                                            Field {
                                                id: keyField
                                                width: 90
                                                height: 32
                                                mono: root.mono
                                                placeholder: root.ru ? "клавиша" : "key"
                                                text: row.open ? root.pretty((root.overrides[row.code] || row.code).split(" + ").pop()) : ""
                                                onAccepted: root.save(keyField.text)
                                            }

                                            Rectangle {
                                                width: saveLabel.implicitWidth + 24
                                                height: 32
                                                radius: 9
                                                color: Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.85)

                                                Text {
                                                    id: saveLabel
                                                    anchors.centerIn: parent
                                                    text: root.ru ? "сохранить" : "save"
                                                    color: Colors.bg
                                                    font.family: root.mono
                                                    font.pixelSize: Fonts.small
                                                }

                                                MouseArea {
                                                    anchors.fill: parent
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.save(keyField.text)
                                                }
                                            }

                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: row.changed
                                                text: root.ru ? "как было" : "reset"
                                                color: Colors.fgDim
                                                font.family: root.mono
                                                font.pixelSize: Fonts.small
                                                font.underline: resetArea.containsMouse

                                                MouseArea {
                                                    id: resetArea
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: root.reset()
                                                }
                                            }
                                        }

                                        Text {
                                            visible: root.editError !== ""
                                            text: root.editError
                                            color: Colors.bad
                                            font.family: root.mono
                                            font.pixelSize: Fonts.tiny
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
