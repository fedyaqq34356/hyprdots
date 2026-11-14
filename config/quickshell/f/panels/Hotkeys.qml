import Quickshell
import Quickshell.Hyprland
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

    readonly property string mono: Fonts.mono
    readonly property bool ru: Prefs.language === "ru"

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
            ["Alt+Shift", "сменить раскладку", "switch layout"]
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

    readonly property var shownGroups: {
        const q = root.query.trim().toLowerCase();
        const out = [];
        for (const g of root.groups) {
            const items = q === "" ? g.items : g.items.filter(it =>
                it[0].toLowerCase().indexOf(q) >= 0
                || it[1].toLowerCase().indexOf(q) >= 0
                || it[2].toLowerCase().indexOf(q) >= 0);
            if (items.length > 0)
                out.push({ title: root.ru ? g.ru : g.en, items: items });
        }
        return out;
    }

    function open() {
        root.query = "";
        root.shown = true;
        Sfx.tip();
    }

    function close() {
        if (!root.shown)
            return;
        root.shown = false;
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

            Keys.onEscapePressed: root.close()

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

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.ru ? "клавиши" : "keys"
                    color: Colors.fg
                    font.family: Fonts.display
                    font.pixelSize: Fonts.big
                }
            }

            Field {
                id: search

                anchors.right: parent.right
                anchors.rightMargin: 32
                anchors.verticalCenter: head.verticalCenter
                width: Math.min(300, card.width - head.width - 100)
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
                anchors.topMargin: 86
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
                            spacing: 6

                            Text {
                                text: group.modelData.title
                                color: Colors.accent
                                opacity: 0.85
                                font.family: root.mono
                                font.pixelSize: Fonts.tiny
                                font.capitalization: Font.AllUppercase
                                font.letterSpacing: 1.2
                                bottomPadding: 2
                            }

                            Repeater {
                                model: group.modelData.items

                                Item {
                                    id: row

                                    required property var modelData

                                    width: group.width
                                    height: 28

                                    Row {
                                        id: chips

                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 250
                                        spacing: 4

                                        Repeater {
                                            model: row.modelData[0].split("+")

                                            Rectangle {
                                                required property string modelData

                                                width: cap.implicitWidth + 16
                                                height: 24
                                                radius: 8
                                                color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                                               Colors.bgAlt.b, 0.75)
                                                border.width: 1
                                                border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                                      Colors.outline.b, 0.2)

                                                Text {
                                                    id: cap
                                                    anchors.centerIn: parent
                                                    text: parent.modelData
                                                    color: Colors.accentAlt
                                                    font.family: root.mono
                                                    font.pixelSize: Fonts.tiny
                                                }
                                            }
                                        }
                                    }

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 262
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: root.ru ? row.modelData[1] : row.modelData[2]
                                        color: Colors.fg
                                        opacity: 0.85
                                        elide: Text.ElideRight
                                        font.family: Fonts.display
                                        font.pixelSize: Fonts.small
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
