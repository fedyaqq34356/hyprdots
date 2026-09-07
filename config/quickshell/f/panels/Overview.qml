import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Effects
import "root:/design"
import "root:/services"

Scope {
    id: root

    property bool shown: false
    property int selected: 0
    property string filter: ""

    readonly property string mono: "JetBrainsMono Nerd Font"

    readonly property var windows: {
        const all = ToplevelManager.toplevels.values.filter(t => t && t.title !== undefined);
        const q = root.filter.toLowerCase().trim();
        if (q === "") return all;
        return all.filter(t => (t.title || "").toLowerCase().includes(q)
                            || (t.appId || "").toLowerCase().includes(q));
    }

    function plural(n) { return I18n.plural("plural.window", n); }

    function workspaceOf(toplevel) {
        if (!toplevel || !Hyprland.toplevels)
            return -1;

        const list = Hyprland.toplevels.values;
        for (const t of list) {
            if (!t)
                continue;
            if (t.wayland === toplevel) {
                const w = t.workspace;
                return w ? w.id : -1;
            }
        }

        for (const t of list) {
            const o = t ? t.lastIpcObject : null;
            if (!o || !o.workspace)
                continue;
            if (o.title === toplevel.title)
                return o.workspace.id;
        }

        return -1;
    }

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (shown) {
            filter = "";
            selected = 0;
            Qt.callLater(root.takeFocus);
        }
    }

    property var focusTarget: null

    function takeFocus() {
        if (root.focusTarget)
            root.focusTarget.forceActiveFocus();
    }

    function activate(index) {
        const t = root.windows[index];
        if (!t) return;
        root.close();
        t.activate();
    }

    function move(delta) {
        const n = root.windows.length;
        if (n === 0) return;
        root.selected = (root.selected + delta + n) % n;
    }

    HyprlandFocusGrab {
        active: root.shown
        windows: [win]
        onCleared: root.close()
    }

    PanelWindow {
        WlrLayershell.namespace: "qs-overview"
        id: win
        screen: Focus.screen
        visible: root.shown
        focusable: true

        anchors { top: true; bottom: true; left: true; right: true }
        exclusiveZone: 0
        color: "transparent"

        Loader {
            anchors.fill: parent
            active: root.shown

            sourceComponent: Item {
                anchors.fill: parent

                Rectangle {
                    anchors.fill: parent
                    color: "#000000"
                    opacity: root.shown ? 0.66 : 0
                    Behavior on opacity { NumberAnimation { duration: Motion.base } }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.close()
                    }
                }

                FocusScope {
                    id: grab

                    Component.onCompleted: root.focusTarget = grab
                    Component.onDestruction: root.focusTarget = null
                    anchors.fill: parent
                    focus: true

                    Keys.onEscapePressed: root.close()
                    Keys.onLeftPressed: root.move(-1)
                    Keys.onRightPressed: root.move(1)
                    Keys.onTabPressed: root.move(1)
                    Keys.onBacktabPressed: root.move(-1)
                    Keys.onReturnPressed: root.activate(root.selected)
                    Keys.onEnterPressed: root.activate(root.selected)
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Backspace) {
                            root.filter = root.filter.slice(0, -1);
                            root.selected = 0;
                            event.accepted = true;
                        } else if (event.text && event.text.length === 1
                                   && event.text.charCodeAt(0) >= 32) {
                            root.filter += event.text;
                            root.selected = 0;
                            event.accepted = true;
                        }
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 26

                        opacity: root.shown ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: Motion.base } }

                        Rectangle {
                            id: field

                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 460
                            height: 50
                            radius: Shape.field
                            antialiasing: true
                            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.82)
                            border.width: 1
                            border.color: root.filter !== ""
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                          Colors.accent.b, 0.55)
                                : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                          Colors.outline.b, 0.18)
                            Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                            Rectangle {
                                z: -1
                                anchors.centerIn: parent
                                width: parent.width + 12
                                height: parent.height + 12
                                radius: parent.radius + 6
                                color: Colors.accent
                                opacity: root.filter !== "" ? 0.22 : 0.12
                                Behavior on opacity { NumberAnimation { duration: Motion.slow } }

                                layer.enabled: true
                                layer.effect: MultiEffect {
                                    blurEnabled: true
                                    blur: 1.0
                                    blurMax: 40
                                }
                            }

                            Row {
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 14
                                spacing: 12

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "󰍉"
                                    color: Colors.accent
                                    opacity: root.filter !== "" ? 1 : 0.6
                                    font.family: root.mono
                                    font.pixelSize: 16
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 130
                                    elide: Text.ElideRight
                                    text: root.filter !== "" ? root.filter : I18n.t("act.search")
                                    color: root.filter !== "" ? Colors.fg : Colors.fgDim
                                    opacity: root.filter !== "" ? 1 : 0.45
                                    font.family: root.mono
                                    font.pixelSize: 14
                                }

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: countLabel.implicitWidth + 18
                                    height: 22
                                    radius: Shape.detail
                                    color: Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                   Colors.fgDim.b, 0.10)

                                    Text {
                                        id: countLabel
                                        anchors.centerIn: parent
                                        text: root.windows.length + " "
                                              + root.plural(root.windows.length)
                                        color: Colors.fgDim
                                        opacity: 0.75
                                        font.family: root.mono
                                        font.pixelSize: 10
                                    }
                                }
                            }
                        }

                        Grid {
                            id: grid

                            anchors.horizontalCenter: parent.horizontalCenter
                            columns: Math.min(3, Math.max(1, root.windows.length))
                            spacing: 20

                            Repeater {
                                model: root.windows

                                Item {
                                    id: slot

                                    required property var modelData
                                    required property int index

                                    readonly property bool current: root.selected === index
                                    readonly property int workspace:
                                        root.workspaceOf(modelData)

                                    width: 400
                                    height: 268

                                    opacity: 0
                                    scale: 0.94

                                    SequentialAnimation {
                                        running: true
                                        PauseAnimation { duration: Motion.delay(slot.index) }
                                        ParallelAnimation {
                                            NumberAnimation {
                                                target: slot; property: "opacity"; to: 1
                                                duration: Motion.base
                                            }
                                            NumberAnimation {
                                                target: slot; property: "scale"; to: 1
                                                duration: Motion.slow
                                                easing.type: Easing.Bezier
                                                easing.bezierCurve: Motion.snap
                                            }
                                        }
                                    }

                                    Rectangle {
                                        z: -1
                                        anchors.centerIn: parent
                                        width: parent.width - 16
                                        height: parent.height - 16
                                        radius: Shape.card
                                        color: Colors.accent
                                        opacity: slot.current ? 0.32
                                               : (cardArea.containsMouse ? 0.16 : 0)
                                        Behavior on opacity { NumberAnimation { duration: Motion.base } }

                                        layer.enabled: opacity > 0.01
                                        layer.effect: MultiEffect {
                                            blurEnabled: true
                                            blur: 1.0
                                            blurMax: 44
                                        }
                                    }

                                    ClippingRectangle {
                                        id: card

                                        anchors.fill: parent
                                        radius: Shape.card
                                        color: Qt.rgba(Colors.bg.r, Colors.bg.g,
                                                       Colors.bg.b, 0.92)
                                        border.width: slot.current ? 2 : 1
                                        border.color: slot.current
                                            ? Colors.accent
                                            : Qt.rgba(Colors.outline.r, Colors.outline.g,
                                                      Colors.outline.b, 0.22)
                                        Behavior on border.color { ColorAnimation { duration: Motion.fast } }

                                        scale: slot.current ? 1.03
                                             : (cardArea.containsMouse ? 1.015 : 1.0)
                                        Behavior on scale {
                                            SpringAnimation {
                                                spring: Motion.tapSpring
                                                damping: Motion.tapDamping
                                                mass: Motion.tapMass
                                                epsilon: 0.001
                                            }
                                        }

                                        ScreencopyView {
                                            id: preview

                                            anchors.fill: parent
                                            captureSource: slot.modelData

                                            live: false
                                            constraintSize: Qt.size(card.width, card.height)
                                        }

                                        IconImage {
                                            anchors.centerIn: parent
                                            visible: !preview.hasContent
                                            implicitSize: 64
                                            source: Quickshell.iconPath(slot.modelData.appId,
                                                                        "application-x-executable")
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            height: 62

                                            gradient: Gradient {
                                                GradientStop {
                                                    position: 0.0
                                                    color: Qt.rgba(Colors.bg.r, Colors.bg.g,
                                                                   Colors.bg.b, 0.0)
                                                }
                                                GradientStop {
                                                    position: 1.0
                                                    color: Qt.rgba(Colors.bg.r, Colors.bg.g,
                                                                   Colors.bg.b, 0.95)
                                                }
                                            }
                                        }

                                        Row {
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.bottom: parent.bottom
                                            anchors.leftMargin: 14
                                            anchors.rightMargin: 14
                                            anchors.bottomMargin: 12
                                            spacing: 11

                                            IconImage {
                                                anchors.verticalCenter: parent.verticalCenter
                                                implicitSize: 24
                                                source: Quickshell.iconPath(slot.modelData.appId,
                                                                            "application-x-executable")
                                            }

                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: parent.width - 24 - 11
                                                       - (slot.workspace > 0 ? 46 : 0)
                                                spacing: 1

                                                Text {
                                                    width: parent.width
                                                    elide: Text.ElideRight
                                                    text: slot.modelData.title
                                                          || slot.modelData.appId
                                                    color: slot.current ? Colors.fg : Colors.fgDim
                                                    opacity: slot.current ? 1 : 0.85
                                                    font.family: Fonts.display
                                                    font.pixelSize: 13
                                                    font.weight: slot.current
                                                        ? Font.DemiBold : Font.Normal
                                                }

                                                Text {
                                                    width: parent.width
                                                    visible: text !== ""
                                                    elide: Text.ElideRight
                                                    text: slot.modelData.appId || ""
                                                    color: Colors.fgDim
                                                    opacity: 0.55
                                                    font.family: root.mono
                                                    font.pixelSize: 9
                                                }
                                            }

                                            Rectangle {
                                                anchors.verticalCenter: parent.verticalCenter
                                                visible: slot.workspace > 0
                                                width: 34
                                                height: 24
                                                radius: Shape.detail
                                                antialiasing: true
                                                color: slot.current
                                                    ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                                              Colors.accent.b, 0.25)
                                                    : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                                              Colors.fgDim.b, 0.10)
                                                Behavior on color { ColorAnimation { duration: Motion.fast } }

                                                Text {
                                                    anchors.centerIn: parent
                                                    text: slot.workspace
                                                    color: slot.current ? Colors.accent : Colors.fgDim
                                                    opacity: slot.current ? 1 : 0.7
                                                    font.family: root.mono
                                                    font.pixelSize: 11
                                                    font.weight: Font.DemiBold
                                                }
                                            }
                                        }

                                        Sheen {
                                            anchors.fill: parent
                                            radius: Shape.card
                                            border: false
                                            grainOpacity: 0.02
                                        }
                                    }

                                    MouseArea {
                                        id: cardArea

                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onEntered: root.selected = slot.index
                                        onClicked: mouse => {
                                            if (mouse.button === Qt.MiddleButton)
                                                slot.modelData.close();
                                            else
                                                root.activate(slot.index);
                                        }
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            visible: root.windows.length === 0
                            text: root.filter === "" ? I18n.t("ov.noWindows") : I18n.t("ov.noMatch")
                            color: Colors.fgDim
                            opacity: 0.5
                            font.family: root.mono
                            font.pixelSize: 13
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: I18n.t("ov.keys")
                            color: Colors.fgDim
                            opacity: 0.4
                            font.family: root.mono
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
