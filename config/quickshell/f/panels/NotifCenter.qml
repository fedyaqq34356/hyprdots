import Quickshell
import Quickshell.Hyprland
import Quickshell.Widgets
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
    readonly property color tint: Dnd.active ? Colors.fgDim : Colors.accent

    property var collapsed: ({})

    property int freshCount: 0

    function alpha(c, a) { return Qt.rgba(c.r, c.g, c.b, a); }

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    function isCollapsed(app) { return root.collapsed[app] === true; }

    function toggleGroup(app) {
        const next = ({});
        for (const k in root.collapsed)
            next[k] = root.collapsed[k];
        next[app] = !(next[app] === true);
        root.collapsed = next;
    }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (shown) {
            root.freshCount = NotifHistory.unseen;
            drawer.forceActiveFocus();
        } else {
            NotifHistory.markSeen();
        }
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        id: win
        WlrLayershell.namespace: "qs-notifcenter"
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

        FocusScope {
            id: drawer
            width: 440
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.rightMargin: 12
            anchors.topMargin: 12
            anchors.bottomMargin: 12
            focus: true

            opacity: root.shown ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.base } }

            transform: Translate {
                x: root.shown ? 0 : drawer.width + 24
                Behavior on x {
                    NumberAnimation {
                        duration: Motion.slow
                        easing.type: Easing.Bezier
                        easing.bezierCurve: Motion.expo
                    }
                }
            }

            Keys.onEscapePressed: root.close()
            Keys.onPressed: event => {
                if (event.key === Qt.Key_Delete
                        || (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier))) {
                    NotifHistory.clear();
                    event.accepted = true;
                } else if (event.key === Qt.Key_D) {
                    Dnd.toggle();
                    event.accepted = true;
                }
            }

            Item {
                anchors.fill: parent
                z: -1
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowBlur: 1.0
                    shadowVerticalOffset: 8
                    shadowOpacity: 0.55
                    shadowColor: "#000000"
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Shape.card
                    color: Colors.bg
                }
            }

            Rectangle {
                id: card
                anchors.fill: parent
                radius: Shape.card
                clip: true

                gradient: Gradient {
                    GradientStop { position: 0.0
                        color: root.alpha(Colors.bgAlt, 0.96) }
                    GradientStop { position: 0.45
                        color: root.alpha(Colors.bg, 0.985) }
                    GradientStop { position: 1.0
                        color: root.alpha(Colors.bg, 0.99) }
                }

                Canvas {
                    id: wash
                    width: 520
                    height: 520
                    x: card.width / 2 - width / 2
                    y: -260

                    Connections {
                        target: root
                        function onTintChanged() { wash.requestPaint(); }
                    }

                    onPaint: {
                        const ctx = getContext("2d");
                        ctx.reset();
                        const r = width / 2;
                        const g = ctx.createRadialGradient(r, r, r * 0.05, r, r, r);
                        g.addColorStop(0.0, root.alpha(root.tint, 0.22));
                        g.addColorStop(0.5, root.alpha(root.tint, 0.07));
                        g.addColorStop(1.0, root.alpha(root.tint, 0.0));
                        ctx.fillStyle = g;
                        ctx.fillRect(0, 0, width, height);
                    }
                }

                Sheen {
                    anchors.fill: parent
                    radius: Shape.card
                    edge: root.tint
                    edgeOpacity: 0.26
                }

                Item {
                    id: header
                    anchors { top: parent.top; left: parent.left; right: parent.right }
                    anchors.margins: 20
                    height: 44

                    Row {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 12

                        Rectangle {
                            width: 40
                            height: 40
                            radius: Shape.chip
                            anchors.verticalCenter: parent.verticalCenter
                            color: root.alpha(root.tint, 0.16)
                            border.width: 1
                            border.color: root.alpha(root.tint, 0.30)
                            Behavior on color { ColorAnimation { duration: Motion.base } }

                            Text {
                                anchors.centerIn: parent
                                text: Dnd.active ? "󰂛" : "󰂚"
                                color: root.tint
                                font.family: root.mono
                                font.pixelSize: 18
                                Behavior on color { ColorAnimation { duration: Motion.base } }
                            }

                            Rectangle {
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.rightMargin: -3
                                anchors.topMargin: -3
                                width: Math.max(16, badge.implicitWidth + 8)
                                height: 16
                                radius: 8
                                color: Colors.accent
                                visible: root.freshCount > 0
                                scale: root.freshCount > 0 ? 1 : 0
                                Behavior on scale { Spring {} }

                                Text {
                                    id: badge
                                    anchors.centerIn: parent
                                    text: root.freshCount > 99 ? "99+" : String(root.freshCount)
                                    color: Colors.accentText
                                    font.family: root.mono
                                    font.pixelSize: 9
                                    font.weight: Font.Bold
                                }
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 2

                            Text {
                                text: I18n.t("notif.title")
                                color: Colors.fg
                                font.family: Fonts.display
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: {
                                    if (NotifHistory.count === 0)
                                        return I18n.t("notif.historyEmpty");
                                    const total = NotifHistory.count + I18n.t("notif.inHistory");
                                    return root.freshCount > 0
                                        ? total + "  ·  " + root.freshCount + I18n.t("notif.fresh")
                                        : total;
                                }
                                color: Colors.fgDim
                                opacity: 0.7
                                font.family: root.mono
                                font.pixelSize: 10
                            }
                        }
                    }

                    IconButton {
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        glyph: "󰩹"
                        tint: Colors.bad
                        mono: root.mono
                        tip: I18n.t("notif.clearAll")
                        opacity: NotifHistory.count > 0 ? 1 : 0.25
                        enabled: NotifHistory.count > 0
                        Behavior on opacity { NumberAnimation { duration: Motion.base } }
                        onActivated: if (NotifHistory.count > 0) NotifHistory.clear()
                    }
                }

                Rectangle {
                    id: dndPill
                    anchors { top: header.bottom; left: parent.left; right: parent.right }
                    anchors.topMargin: 16
                    anchors.leftMargin: 20
                    anchors.rightMargin: 20
                    height: 46
                    radius: Shape.chip

                    color: Dnd.active ? root.alpha(Colors.bgAlt, 0.75)
                                      : root.alpha(Colors.accent, 0.16)
                    border.width: 1
                    border.color: Dnd.active ? root.alpha(Colors.outline, 0.22)
                                             : root.alpha(Colors.accent, 0.40)
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                    Behavior on border.color { ColorAnimation { duration: Motion.base } }

                    scale: dndTap.pressed ? 0.98 : 1
                    Behavior on scale { Spring {} }

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Dnd.active ? "󰂛" : "󰂚"
                            color: Dnd.active ? Colors.fgDim : Colors.accent
                            opacity: Dnd.active ? 0.6 : 1
                            font.family: root.mono
                            font.pixelSize: 15
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 1

                            Text {
                                text: Dnd.active ? I18n.t("notif.dnd") : I18n.t("notif.dndOff")
                                color: Dnd.active ? Colors.fgDim : Colors.fg
                                opacity: Dnd.active ? 0.75 : 0.95
                                font.family: root.mono
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                text: Dnd.active ? I18n.t("notif.dndOnSub")
                                                 : I18n.t("notif.dndOffSub")
                                color: Colors.fgDim
                                opacity: 0.55
                                font.family: root.mono
                                font.pixelSize: 9
                            }
                        }
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.rightMargin: 16
                        anchors.verticalCenter: parent.verticalCenter
                        width: 40
                        height: 22
                        radius: Shape.chip
                        color: Dnd.active ? root.alpha(Colors.outline, 0.25)
                                          : root.alpha(Colors.accent, 0.50)
                        Behavior on color { ColorAnimation { duration: Motion.base } }

                        Rectangle {
                            width: 16
                            height: 16
                            radius: 8
                            y: 3
                            x: Dnd.active ? 3 : parent.width - width - 3
                            color: Dnd.active ? Colors.fgDim : Colors.fg
                            Behavior on x {
                                NumberAnimation {
                                    duration: Motion.base
                                    easing.type: Easing.Bezier
                                    easing.bezierCurve: Motion.snap
                                }
                            }
                        }
                    }

                    TapHandler {
                        id: dndTap
                        onTapped: Dnd.toggle()
                    }
                }

                ListView {
                    id: list
                    anchors {
                        top: dndPill.bottom
                        left: parent.left
                        right: parent.right
                        bottom: footer.top
                    }
                    anchors.topMargin: 18
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    anchors.bottomMargin: 8

                    clip: true
                    spacing: 14
                    model: NotifHistory.groups
                    boundsBehavior: Flickable.StopAtBounds
                    opacity: NotifHistory.count > 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.base } }

                    delegate: Item {
                        id: group

                        required property var modelData
                        required property int index

                        readonly property bool folded: root.isCollapsed(modelData.app)

                        width: list.width
                        height: groupCol.height

                        opacity: 0
                        transform: Translate { id: groupSlide; x: 30 }

                        SequentialAnimation {
                            running: true
                            PauseAnimation { duration: Motion.delay(group.index) }
                            ParallelAnimation {
                                NumberAnimation {
                                    target: groupSlide; property: "x"; to: 0
                                    duration: Motion.slow
                                    easing.type: Easing.Bezier
                                    easing.bezierCurve: Motion.expo
                                }
                                NumberAnimation {
                                    target: group; property: "opacity"; to: 1
                                    duration: Motion.base
                                }
                            }
                        }

                        Column {
                            id: groupCol
                            width: parent.width
                            spacing: 6

                            Rectangle {
                                id: groupHead
                                width: parent.width
                                height: 34
                                radius: Shape.chip
                                color: headHover.hovered
                                    ? root.alpha(Colors.bgAlt, 0.55)
                                    : "transparent"
                                Behavior on color { ColorAnimation { duration: Motion.fast } }

                                HoverHandler { id: headHover }
                                TapHandler { onTapped: root.toggleGroup(group.modelData.app) }

                                Row {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 9

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "󰅀"
                                        color: Colors.fgDim
                                        opacity: 0.65
                                        font.family: root.mono
                                        font.pixelSize: 11
                                        rotation: group.folded ? -90 : 0
                                        Behavior on rotation {
                                            NumberAnimation {
                                                duration: Motion.base
                                                easing.type: Easing.Bezier
                                                easing.bezierCurve: Motion.snap
                                            }
                                        }
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 18
                                        height: 18
                                        radius: 6
                                        color: root.alpha(
                                            NotifHistory.appColor(group.modelData.app), 0.18)

                                        IconImage {
                                            anchors.centerIn: parent
                                            visible: group.modelData.icon !== ""
                                            implicitSize: 14
                                            source: group.modelData.icon === "" ? ""
                                                : Quickshell.iconPath(group.modelData.icon, "")
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: group.modelData.icon === ""
                                            text: NotifHistory.appLetter(group.modelData.app)
                                            color: NotifHistory.appColor(group.modelData.app)
                                            font.family: root.mono
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                        }
                                    }

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: group.modelData.app
                                        color: group.modelData.critical ? Colors.bad : Colors.fg
                                        opacity: 0.9
                                        font.family: root.mono
                                        font.pixelSize: 11
                                        font.weight: Font.DemiBold
                                    }

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: countText.implicitWidth + 12
                                        height: 16
                                        radius: 8
                                        color: root.alpha(Colors.outline, 0.18)

                                        Text {
                                            id: countText
                                            anchors.centerIn: parent
                                            text: String(group.modelData.entries.length)
                                            color: Colors.fgDim
                                            font.family: root.mono
                                            font.pixelSize: 9
                                        }
                                    }
                                }

                                Text {
                                    anchors.right: parent.right
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰅖"
                                    color: Colors.bad
                                    font.family: root.mono
                                    font.pixelSize: 11
                                    opacity: headHover.hovered ? 0.85 : 0
                                    Behavior on opacity { NumberAnimation { duration: Motion.fast } }

                                    TapHandler {
                                        onTapped: NotifHistory.clearApp(group.modelData.app)
                                    }
                                }
                            }

                            Item {
                                width: parent.width
                                height: group.folded ? 0 : entries.height
                                clip: true

                                Behavior on height {
                                    NumberAnimation {
                                        duration: Motion.slow
                                        easing.type: Easing.Bezier
                                        easing.bezierCurve: Motion.decel
                                    }
                                }

                                Column {
                                    id: entries
                                    width: parent.width
                                    spacing: 5

                                    Repeater {
                                        model: group.modelData.entries

                                        NotifRow {
                                            required property var modelData
                                            entry: modelData
                                            mono: root.mono
                                            fresh: modelData.index < root.freshCount
                                            onDismissed: NotifHistory.removeId(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Column {
                    anchors.centerIn: list
                    spacing: 10
                    visible: NotifHistory.count === 0
                    opacity: NotifHistory.count === 0 ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Dnd.active ? "󰂛" : "󰂚"
                        color: Colors.fgDim
                        opacity: 0.30
                        font.family: root.mono
                        font.pixelSize: 52
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: I18n.t("notif.emptyHere")
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: root.mono
                        font.pixelSize: 13
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Dnd.active
                            ? I18n.t("notif.dndBanner")
                            : I18n.t("notif.emptyHint")
                        color: Colors.fgDim
                        opacity: 0.45
                        font.family: root.mono
                        font.pixelSize: 10
                    }
                }

                Item {
                    id: footer
                    anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                    anchors.margins: 14
                    height: 18

                    Text {
                        anchors.left: parent.left
                        anchors.leftMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: NotifHistory.groups.length + I18n.t("notif.apps")
                        color: Colors.fgDim
                        opacity: 0.45
                        font.family: root.mono
                        font.pixelSize: 9
                        visible: NotifHistory.count > 0
                    }

                    Text {
                        anchors.right: parent.right
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        text: I18n.t("notif.keys")
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
