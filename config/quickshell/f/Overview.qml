import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick

Scope {
    id: root

    property bool shown: false
    property int selected: 0
    property string filter: ""

    readonly property var windows: {
        const all = ToplevelManager.toplevels.values.filter(t => t && t.title !== undefined);
        const q = root.filter.toLowerCase().trim();
        if (q === "") return all;
        return all.filter(t => (t.title || "").toLowerCase().includes(q)
                            || (t.appId || "").toLowerCase().includes(q));
    }

    function toggle() { root.shown = !root.shown; }
    function close()  { root.shown = false; }

    onShownChanged: {
        if (shown) {
            filter = "";
            selected = 0;
            grab.forceActiveFocus();
        }
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
            Behavior on opacity { NumberAnimation { duration: 200 } }

            MouseArea {
                anchors.fill: parent
                onClicked: root.close()
            }
        }

        FocusScope {
            id: grab
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
                spacing: 18
                opacity: root.shown ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 180 } }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.filter === ""
                        ? root.windows.length + (root.windows.length === 1 ? " окно" : " окон")
                        : "󰍉  " + root.filter
                    color: Colors.fgDim
                    opacity: 0.7
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 12
                }

                Grid {
                    id: grid
                    anchors.horizontalCenter: parent.horizontalCenter
                    columns: Math.min(4, Math.max(1, root.windows.length))
                    spacing: 16

                    Repeater {
                        model: root.windows

                        Rectangle {
                            id: card
                            required property var modelData
                            required property int index

                            readonly property bool current: root.selected === index

                            width: 320
                            height: 214
                            radius: 16
                            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.92)
                            border.width: 1
                            border.color: current
                                ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.75)
                                : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.22)
                            scale: current ? 1.04 : 1.0

                            Behavior on border.color { ColorAnimation { duration: 160 } }
                            Behavior on scale {
                                NumberAnimation { duration: 220; easing.type: Easing.OutBack }
                            }

                            Item {
                                anchors.fill: parent
                                anchors.margins: 8
                                anchors.bottomMargin: 34
                                clip: true

                                ScreencopyView {
                                    id: preview
                                    anchors.fill: parent
                                    captureSource: card.modelData
                                    live: false
                                    constraintSize: Qt.size(parent.width, parent.height)
                                }

                                // A window that has never been mapped on this
                                // output gives no frame; fall back to the icon.
                                IconImage {
                                    anchors.centerIn: parent
                                    visible: !preview.hasContent
                                    implicitSize: 48
                                    source: Quickshell.iconPath(card.modelData.appId,
                                                                "application-x-executable")
                                }
                            }

                            Text {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.margins: 10
                                elide: Text.ElideRight
                                text: card.modelData.title || card.modelData.appId
                                color: card.current ? Colors.fg : Colors.fgDim
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 11
                                font.weight: card.current ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onEntered: root.selected = card.index
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton)
                                        card.modelData.close();
                                    else
                                        root.activate(card.index);
                                }
                            }
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    visible: root.windows.length === 0
                    text: root.filter === "" ? "нет открытых окон" : "ничего не нашлось"
                    color: Colors.fgDim
                    opacity: 0.5
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 13
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "стрелки — выбор · Enter — перейти · средняя кнопка — закрыть · печатать — фильтр"
                    color: Colors.fgDim
                    opacity: 0.4
                    font.family: "JetBrainsMono Nerd Font"
                    font.pixelSize: 10
                }
            }
        }
    }
}
