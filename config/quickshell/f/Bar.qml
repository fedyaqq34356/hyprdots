import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Services.Pipewire
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell.Wayland

Scope {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            WlrLayershell.namespace: "qs-bar"
            id: win
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }

            // Окно выше самой полосы: в запасе снизу рисуются подсказки.
            // Ввод при этом ограничен полосой, иначе прозрачная зона
            // перехватывала бы клики по окнам под баром.
            implicitHeight: 96
            exclusiveZone: 34
            color: "transparent"
            mask: Region { item: strip }

            // Подсказка вешается на элемент как дочерний обработчик наведения:
            // HoverHandler не Item, поэтому в раскладке места не занимает.
            component Tip: HoverHandler {
                property string text: ""
                onHoveredChanged: hovered ? tips.show(parent, text) : tips.hide(parent)
            }

            component Sep: Rectangle {
                Layout.alignment: Qt.AlignVCenter
                width: 1
                height: 12
                radius: 1
                color: Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.18)
            }

            component Island: Rectangle {
                id: island
                property bool hovered: false

                // Каждый островок выезжает сверху со своей задержкой, так что
                // бар собирается слева направо, а не возникает целиком.
                property int introDelay: 0

                radius: 12
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b,
                               hovered ? 0.92 : 0.80)
                border.width: 1
                border.color: hovered
                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.55)
                    : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.32)

                scale: hovered ? 1.04 : 1.0

                // Островки лежат на обоях, а не на плоскости: без тени
                // граница читается только за счёт рамки.
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0, 0, island.hovered ? 0.45 : 0.30)
                    shadowBlur: 0.55
                    shadowVerticalOffset: 3
                }

                Behavior on color { ColorAnimation { duration: 220 } }
                Behavior on border.color { ColorAnimation { duration: 220 } }
                Behavior on scale {
                    NumberAnimation { duration: 240; easing.type: Easing.OutBack }
                }

                HoverHandler {
                    onHoveredChanged: island.hovered = hovered
                }

                // Свой transform, а не y: островки выровнены по anchors, и
                // трогать y напрямую нельзя.
                opacity: 0
                transform: Translate { id: intro; y: -42 }

                Component.onCompleted: introAnim.start()

                SequentialAnimation {
                    id: introAnim

                    PauseAnimation { duration: island.introDelay }

                    ParallelAnimation {
                        NumberAnimation {
                            target: intro; property: "y"; to: 0
                            duration: 620
                            easing.type: Easing.OutBack
                            easing.overshoot: 1.05
                        }
                        NumberAnimation {
                            target: island; property: "opacity"; to: 1
                            duration: 380
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }

            // Полоса бара. Всё видимое содержимое живёт здесь, чтобы маска
            // ввода совпадала ровно с ним.
            Item {
                id: strip
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                height: 34

                Island {
                    id: wsIsland
                    introDelay: 0
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    height: 26
                    width: wsRow.implicitWidth + 16

                    Tip { text: "Рабочие столы  ·  клик — переход" }

                    Row {
                        id: wsRow
                        anchors.centerIn: parent
                        spacing: 7

                        Repeater {
                            model: Hyprland.workspaces

                            Rectangle {
                                id: wsDot
                                required property var modelData
                                readonly property bool isActive:
                                    Hyprland.focusedWorkspace
                                    && Hyprland.focusedWorkspace.id === modelData.id

                                // Пока в лаунчере подсвечено приложение,
                                // столы с его окнами загораются отдельно.
                                readonly property bool hasApp:
                                    Running.onWorkspace(modelData.id)

                                width: isActive || hasApp ? 20 : 7
                                height: 7
                                radius: 4
                                color: hasApp ? Colors.accentAlt
                                     : isActive ? Colors.accent
                                     : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                               Colors.fgDim.b, 0.30)
                                anchors.verticalCenter: parent.verticalCenter

                                Behavior on width {
                                    NumberAnimation { duration: 280; easing.type: Easing.OutBack }
                                }
                                Behavior on color { ColorAnimation { duration: 200 } }

                                Rectangle {
                                    id: pulse
                                    anchors.centerIn: parent
                                    width: parent.width
                                    height: parent.height
                                    radius: height / 2
                                    color: "transparent"
                                    border.width: 2
                                    border.color: wsDot.hasApp ? Colors.accentAlt : Colors.accent
                                    opacity: 0
                                    z: -1
                                }

                                ParallelAnimation {
                                    id: pulseAnim
                                    NumberAnimation {
                                        target: pulse; property: "scale"
                                        from: 1; to: 3.4
                                        duration: 520; easing.type: Easing.OutCubic
                                    }
                                    NumberAnimation {
                                        target: pulse; property: "opacity"
                                        from: 0.85; to: 0
                                        duration: 520; easing.type: Easing.OutCubic
                                    }
                                }

                                onIsActiveChanged: if (isActive) pulseAnim.restart()

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -5
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Hyprland.dispatch("workspace " + modelData.id)
                                }
                            }
                        }
                    }
                }

                // Плеер. Появляется только когда есть что показывать, иначе
                // бар держал бы пустое место под редкий случай.
                Island {
                    id: mediaIsland
                    introDelay: 110
                    visible: Media.has && Media.label !== ""

                    anchors.left: wsIsland.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 8
                    height: 26
                    width: 152

                    Tip {
                        text: Media.has
                        ? Media.label + "\nклик — панель  ·  ЛКМ по значку — пауза"
                          + "\nколесо — трек"
                        : ""
                    }

                    Row {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.leftMargin: 9
                        anchors.rightMargin: 9
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 7

                        // Обложка в кольце прогресса: позиция в треке видна,
                        // не занимая места под отдельную полосу или цифры.
                        Item {
                            width: 22
                            height: 22
                            anchors.verticalCenter: parent.verticalCenter

                            ProgressRing {
                                anchors.fill: parent
                                visible: Media.hasPosition
                                value: Media.progress
                                color: Colors.accent
                                trackColor: Qt.rgba(Colors.outline.r,
                                                    Colors.outline.g,
                                                    Colors.outline.b, 0.30)
                            }

                            Rectangle {
                                width: 16
                                height: 16
                                radius: 5
                                clip: true
                                anchors.centerIn: parent
                                color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g, Colors.bgAlt.b, 0.7)

                                Image {
                                    id: barCover
                                    anchors.fill: parent
                                    source: Media.art
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    visible: Media.art !== "" && status === Image.Ready
                                }

                                // Пока обложка не загрузилась — состояние
                                // воспроизведения всё равно видно.
                                Text {
                                    anchors.centerIn: parent
                                    visible: !barCover.visible
                                    text: Media.playing ? "󰝚" : "󰎈"
                                    color: Colors.accent
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: Media.toggle()
                            }
                        }

                        // Вместо названия — спектр. Название целиком
                        // читается в подсказке и в панели плеера, а в баре
                        // полосы говорят то же самое без прокрутки.
                        Row {
                            id: spectrum
                            width: parent.width - 36
                            height: 18
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            // Полосы делят доступную ширину поровну, иначе
                            // спектр не дотягивался бы до края островка.
                            readonly property real barWidth:
                                (width - spacing * (Cava.bars - 1)) / Cava.bars

                            Repeater {
                                model: Cava.bars

                                Rectangle {
                                    required property int index

                                    // cava редко упирается в потолок своей
                                    // шкалы, поэтому добавляем запас усиления
                                    // и подрезаем — иначе спектр выглядит
                                    // придавленным даже на громкой музыке.
                                    readonly property real level: {
                                        const v = Cava.levels[index];
                                        if (v === undefined) return 0;
                                        return Math.min(1, v * 1.7);
                                    }

                                    width: spectrum.barWidth
                                    radius: width / 2
                                    anchors.verticalCenter: parent.verticalCenter

                                    // Минимум оставляет ровную линию точек
                                    // в тишине вместо пустого места.
                                    height: Math.max(width, level * spectrum.height)

                                    color: Media.playing ? Colors.accent : Colors.fgDim
                                    opacity: Media.playing ? 0.55 + level * 0.45 : 0.35

                                    Behavior on height {
                                        NumberAnimation { duration: 90; easing.type: Easing.OutQuad }
                                    }
                                    Behavior on color { ColorAnimation { duration: 250 } }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        cursorShape: Qt.PointingHandCursor
                        z: -1
                        onClicked: function (mouse) {
                            if (mouse.button === Qt.RightButton) Media.next();
                            else media.toggle();
                        }
                    }

                    WheelHandler {
                        onWheel: wheel => {
                            if (wheel.angleDelta.y > 0) Media.previous();
                            else Media.next();
                        }
                    }
                }

                Island {
                    id: clockIsland
                    introDelay: 220
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    height: 26
                    width: clockText.implicitWidth + 24

                    Tip {
                        text: calendar.longDate + "\nклик — календарь"
                    }

                    RollText {
                        id: clockText
                        anchors.centerIn: parent
                        text: Qt.formatDateTime(clock.date, "HH:mm")
                        color: Colors.fg
                        pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: calendar.toggle()
                    }
                }

                Island {
                    introDelay: 330
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: 8
                    height: 26
                    width: rightRow.implicitWidth + 20

                    RowLayout {
                        id: rightRow
                        anchors.centerIn: parent
                        spacing: 8


                        // Recording is the loudest thing in the bar on purpose:
                        // it is the only state you can forget you left running.
                        Row {
                            id: recRow
                            spacing: 6
                            visible: Recorder.active

                            Tip { text: "Идёт запись экрана  ·  клик — остановить" }

                            Rectangle {
                                width: 8
                                height: 8
                                radius: 4
                                color: Colors.bad
                                anchors.verticalCenter: parent.verticalCenter

                                SequentialAnimation on opacity {
                                    running: Recorder.active
                                    loops: Animation.Infinite
                                    NumberAnimation { to: 0.25; duration: 700; easing.type: Easing.InOutQuad }
                                    NumberAnimation { to: 1.0;  duration: 700; easing.type: Easing.InOutQuad }
                                }
                            }

                            Text {
                                text: Recorder.clock
                                color: Colors.bad
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter
                            }

                            TapHandler {
                                cursorShape: Qt.PointingHandCursor
                                onTapped: Recorder.stop()
                            }
                        }

                        Sep { visible: Recorder.active && SystemTray.items.values.length > 0 }

                        Row {
                            spacing: 9
                            visible: SystemTray.items.values.length > 0

                            Repeater {
                                model: SystemTray.items

                                IconImage {
                                    id: trayIcon
                                    required property var modelData
                                    source: {
                                        const i = modelData.icon;
                                        if (!i) return "";
                                        if (i.startsWith("/") || i.includes("://")
                                            || i.includes("?")) return i;
                                        return Quickshell.iconPath(i, "application-x-executable");
                                    }
                                    implicitSize: 15
                                    anchors.verticalCenter: parent.verticalCenter

                                    Tip {
                                        text: modelData.tooltipTitle && modelData.tooltipTitle !== ""
                                        ? modelData.tooltipTitle
                                        : (modelData.title ? modelData.title : "")
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: function (mouse) {
                                            if (mouse.button === Qt.LeftButton)
                                                modelData.activate();
                                            else
                                                modelData.secondaryActivate();
                                        }
                                    }
                                }
                            }
                        }

                        Sep { visible: SystemTray.items.values.length > 0 }

                        // Connectivity and sound: glyphs stay quiet, only a
                        // problem state takes colour.
                        Row {
                            spacing: 8

                            Text {
                                id: netGlyph
                                text: Network.glyph
                                color: Network.connected ? Colors.fgDim : Colors.bad
                                opacity: Network.connected ? 0.75 : 1.0
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter

                                Tip {
                                    text: Network.connected
                                    ? Network.ssid + "  ·  сигнал " + Network.strength + "%"
                                      + "\nклик — сеть"
                                    : "Нет подключения  ·  клик — сеть"
                                }

                                Behavior on color { ColorAnimation { duration: 250 } }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -4
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: wifi.toggle()
                                }
                            }

                            Text {
                                id: micGlyph
                                readonly property var src: Pipewire.defaultAudioSource
                                visible: src && src.audio && src.audio.muted
                                text: "󰍭"
                                color: Colors.bad
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                anchors.verticalCenter: parent.verticalCenter

                                Tip { text: "Микрофон выключен" }
                            }

                            Row {
                                id: volRow
                                spacing: 4
                                anchors.verticalCenter: parent.verticalCenter

                                readonly property var sink: Pipewire.defaultAudioSink
                                readonly property real vol: sink && sink.audio ? sink.audio.volume : 0
                                readonly property bool muted: sink && sink.audio ? sink.audio.muted : false

                                Tip {
                                    text: (volRow.muted ? "Звук выключен" : "Громкость "
                                          + Math.round(volRow.vol * 100) + "%")
                                          + "\nклик — тишина  ·  колесо — громче/тише"
                                }

                                Text {
                                    text: parent.muted ? "󰝟" : "󰕾"
                                    color: parent.muted ? Colors.bad : Colors.fgDim
                                    opacity: parent.muted ? 1.0 : 0.75
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Text {
                                    visible: !parent.muted
                                    text: Math.round(parent.vol * 100) + "%"
                                    color: Colors.fgDim
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 11
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                TapHandler {
                                    cursorShape: Qt.PointingHandCursor
                                    onTapped: {
                                        const a = parent.sink && parent.sink.audio;
                                        if (a) a.muted = !a.muted;
                                    }
                                }

                                WheelHandler {
                                    onWheel: wheel => {
                                        const a = parent.sink && parent.sink.audio;
                                        if (!a) return;
                                        const step = wheel.angleDelta.y > 0 ? 0.02 : -0.02;
                                        a.volume = Math.max(0, Math.min(1, a.volume + step));
                                    }
                                }
                            }
                        }

                        Sep {}

                        // Identity of the session: layout and charge. These are
                        // the two you actually read, so they carry the contrast.
                        Row {
                            spacing: 9

                            // Периферия подаёт голос, только когда садится:
                            // постоянный значок «мышь заряжена» — шум.
                            Row {
                                id: periphRow
                                spacing: 4
                                visible: Peripherals.low
                                anchors.verticalCenter: parent.verticalCenter

                                Tip {
                                    text: Peripherals.model + "  ·  " + Peripherals.percent + "%"
                                }

                                Text {
                                    text: Peripherals.glyph
                                    color: Peripherals.critical ? Colors.bad : Colors.warn
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 12
                                    anchors.verticalCenter: parent.verticalCenter

                                    Behavior on color { ColorAnimation { duration: 300 } }
                                }

                                Text {
                                    text: Peripherals.percent + "%"
                                    color: Peripherals.critical ? Colors.bad : Colors.warn
                                    font.family: "JetBrainsMono Nerd Font"
                                    font.pixelSize: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            Text {
                                id: kbText
                                text: Keyboard.code
                                color: Colors.fgDim
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 10
                                font.letterSpacing: 0.8
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter

                                Tip { text: "Раскладка  ·  клик — переключить" }

                                MouseArea {
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: Keyboard.next()
                                }
                            }

                            Text {
                                id: battText
                                readonly property var dev: UPower.displayDevice
                                readonly property int pct: dev ? Math.round(dev.percentage * 100) : 0
                                readonly property bool charging:
                                    dev && dev.state === UPowerDeviceState.Charging

                                visible: dev && dev.isLaptopBattery
                                text: (charging ? "󰂄 " : "") + pct + "%"
                                color: charging ? Colors.good
                                     : pct <= 12 ? Colors.bad
                                     : pct <= 25 ? Colors.warn
                                     : Colors.fg
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.weight: Font.DemiBold
                                anchors.verticalCenter: parent.verticalCenter

                                Tip {
                                    text: {
                                    if (!battText.dev) return "";
                                    if (battText.charging) return "Заряжается  ·  " + battText.pct + "%";
                                    const t = battText.dev.timeToEmpty;
                                    if (!t || t <= 0) return "Батарея  ·  " + battText.pct + "%";
                                    const h = Math.floor(t / 3600);
                                    const m = Math.floor((t % 3600) / 60);
                                    return "Батарея  ·  " + battText.pct + "%\nостаток ~"
                                           + (h > 0 ? h + " ч " : "") + m + " мин";
                                }
                                }

                                Behavior on color { ColorAnimation { duration: 300 } }
                            }
                        }
                    }
                }
            }

            // Пока любое окно в полный экран, сессия не должна засыпать:
            // геймпад и мышь в игре не всегда считаются активностью ввода.
            IdleInhibitor {
                window: win
                enabled: {
                    const list = ToplevelManager.toplevels
                        ? ToplevelManager.toplevels.values : [];
                    for (const t of list) {
                        if (t && t.fullscreen) return true;
                    }
                    return false;
                }
            }

            // Подсказки рисуются под полосой, в немаскированной зоне окна.
            // Один экземпляр на бар: одновременно наведён всегда один элемент.
            Item {
                id: tips
                anchors.fill: parent
                z: 200

                property Item current: null
                property string text: ""

                function show(item, str) {
                    if (!str || str === "") return;
                    tips.current = item;
                    tips.text = str;
                }

                function hide(item) {
                    if (tips.current === item) {
                        tips.current = null;
                        tips.text = "";
                    }
                }

                readonly property point at: current
                    ? current.mapToItem(tips, current.width / 2, current.height)
                    : Qt.point(0, 0)

                Rectangle {
                    id: bubble
                    visible: opacity > 0.01
                    opacity: tips.current ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: 140 } }

                    // Не даём подсказке уехать за край экрана.
                    x: Math.max(6, Math.min(tips.width - width - 6,
                                            tips.at.x - width / 2))
                    y: 42
                    Behavior on x { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                    width: tipText.implicitWidth + 20
                    height: tipText.implicitHeight + 14
                    radius: 10
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.96)
                    border.width: 1
                    border.color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                          Colors.outline.b, 0.35)

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0, 0, 0.40)
                        shadowBlur: 0.6
                        shadowVerticalOffset: 3
                    }

                    Text {
                        id: tipText
                        anchors.centerIn: parent
                        text: tips.text
                        color: Colors.fgDim
                        horizontalAlignment: Text.AlignHCenter
                        font.family: "JetBrainsMono Nerd Font"
                        font.pixelSize: 10
                        lineHeight: 1.25
                    }
                }
            }
        }
    }
}
