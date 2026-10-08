import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import "root:/design"
import "root:/overlays"
import "root:/reusables"
import "root:/services"

Item {
    id: sc
    readonly property Item hero: thumb

    property color tint: Colors.accent
    property string path: ""

    signal dismissed()

    readonly property string url: sc.path !== "" ? "file://" + sc.path : ""

    function run(argv) {
        Quickshell.execDetached(argv);
    }

    property bool canEdit: false
    Process {
        running: true
        command: ["sh", "-c", "command -v satty >/dev/null && echo yes"]
        stdout: StdioCollector {
            onStreamFinished: sc.canEdit = text.trim() === "yes"
        }
    }

    ClippingRectangle {
        id: thumb

        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        width: Math.min(parent.width * 0.42,
                        shot.implicitHeight > 0
                            ? height * shot.implicitWidth / shot.implicitHeight
                            : height * 16 / 9)
        radius: 14
        color: Colors.alpha(sc.tint, 0.12)
        border.width: 1
        border.color: Colors.alpha(Colors.fg, 0.16)

        property real rise: -34
        scale: 0.3
        rotation: -9
        transform: Translate { y: thumb.rise }
        Component.onCompleted: {
            thumb.rise = 0;
            thumb.scale = 1;
            thumb.rotation = 0;
        }
        Behavior on rise { Spring {} }
        Behavior on scale { Spring {} }
        Behavior on rotation { Spring {} }

        Image {
            id: shot
            anchors.fill: parent
            source: sc.url
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false
            mipmap: true
            smooth: true
        }

        Rectangle {
            id: flashOver
            anchors.fill: parent
            color: "white"
            opacity: 0.85
            Component.onCompleted: flashOver.opacity = 0
            Behavior on opacity { NumberAnimation { duration: 480; easing.type: Easing.OutCubic } }
        }

        HoverHandler {
            id: thumbHover
            cursorShape: grab.drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        }

        Rectangle {
            anchors.fill: parent
            radius: thumb.radius
            color: "transparent"
            border.width: 2
            border.color: Colors.alpha(sc.tint, 0.6)
            opacity: thumbHover.hovered ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: Motion.fast } }
        }
    }

    Item {
        id: carrier
        width: thumb.width
        height: thumb.height
        visible: false

        Drag.active: grab.drag.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.CopyAction
        Drag.mimeData: ({ "text/uri-list": sc.url + "\r\n" })
        Drag.imageSource: sc.url
        Drag.onDragFinished: {
            carrier.x = 0;
            carrier.y = 0;
        }
    }

    MouseArea {
        id: grab
        anchors.fill: thumb
        drag.target: carrier
        drag.threshold: 6
        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
        onClicked: sc.run(["xdg-open", sc.path])
    }

    Column {
        anchors.left: thumb.right
        anchors.leftMargin: 14
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: 2

        Row {
            spacing: 8

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: I18n.t("isle.shot.title")
                color: Colors.alpha(Colors.fg, 0.5)
                font.family: Fonts.display
                font.pixelSize: 11
                font.capitalization: Font.AllUppercase
                font.letterSpacing: 0.4
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: shot.status === Image.Ready
                text: shot.implicitWidth + " × " + shot.implicitHeight
                color: Colors.alpha(Colors.fg, 0.75)
                font.family: Fonts.mono
                font.pixelSize: 11
            }
        }

        Row {
            spacing: 0
            x: -8

            IslandKey {
                glyph: "󰏋"
                size: 18
                onActivated: {
                    sc.run(["xdg-open", sc.path]);
                    sc.dismissed();
                }
            }

            IslandKey {
                visible: sc.canEdit
                glyph: "󰏫"
                size: 18
                onActivated: {
                    sc.run(["satty", "--filename", sc.path, "--output-filename",
                            sc.path, "--copy-command", "wl-copy"]);
                    sc.dismissed();
                }
            }

            IslandKey {
                glyph: "󰉋"
                size: 18
                onActivated: {
                    sc.run(["kitty", "--class", "yazi", "-e", "yazi", sc.path]);
                    sc.dismissed();
                }
            }

            IslandKey {
                glyph: "󰩺"
                size: 18
                ink: Colors.bad
                onActivated: {
                    sc.run(["gio", "trash", sc.path]);
                    sc.dismissed();
                }
            }
        }
    }
}
