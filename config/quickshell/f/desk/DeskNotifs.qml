import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "list"

    readonly property bool bare: face.variant === "count"
                              || face.variant === "badge"
                              || face.variant === "dots"
                              || face.variant === "ticker"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    readonly property var recent: NotifHistory.items.slice(0, 4)
    readonly property var newest: NotifHistory.items.length > 0
        ? NotifHistory.items[0] : null

    readonly property var senders: NotifHistory.groups.slice(0, 5)

    opacity: NotifHistory.count > 0 ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    Loader {
        id: loader
        sourceComponent: face.variant === "count" ? count
                       : face.variant === "cards" ? cards
                       : face.variant === "apps" ? apps
                       : face.variant === "badge" ? badge
                       : face.variant === "compact" ? compact
                       : face.variant === "dots" ? dots
                       : face.variant === "ticker" ? ticker
                       : face.variant === "latest" ? latest
                       : face.variant === "column" ? column
                       : list
    }

    Component {
        id: count

        Row {
            spacing: 14

            Item {
                width: 58
                height: 58
                anchors.verticalCenter: parent.verticalCenter

                Rectangle {
                    anchors.fill: parent
                    radius: width / 2
                    antialiasing: true
                    color: NotifHistory.unseen > 0
                        ? Qt.rgba(Colors.accent.r, Colors.accent.g,
                                  Colors.accent.b, 0.16)
                        : Qt.rgba(Colors.fgDim.r, Colors.fgDim.g,
                                  Colors.fgDim.b, 0.08)
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                }

                Text {
                    anchors.centerIn: parent
                    text: NotifHistory.unseen > 0 ? "󰂚" : "󰂜"
                    color: NotifHistory.unseen > 0 ? Colors.accent : Colors.fgDim
                    font.family: face.mono
                    font.pixelSize: 24
                    Behavior on color { ColorAnimation { duration: Motion.base } }
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: -4

                Text {
                    text: NotifHistory.unseen > 0
                        ? NotifHistory.unseen : NotifHistory.count
                    color: Colors.fg
                    opacity: 0.92
                    font.family: face.mono
                    font.pixelSize: 46
                    font.weight: Font.Thin
                }

                Text {
                    text: I18n.plural("plural.notification",
                                      NotifHistory.unseen > 0
                                      ? NotifHistory.unseen : NotifHistory.count)
                    color: Colors.fgDim
                    opacity: 0.55
                    font.family: face.mono
                    font.pixelSize: 11
                    font.letterSpacing: 2
                }
            }
        }
    }

    Component {
        id: list

        Rectangle {
            implicitWidth: 300
            implicitHeight: stack.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: stack
                anchors.centerIn: parent
                width: parent.width - 34
                spacing: 12

                Repeater {
                    model: face.recent

                    Row {
                        required property var modelData

                        width: stack.width
                        spacing: 11

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 26
                            height: 26
                            radius: Shape.detail + 2
                            antialiasing: true
                            color: Qt.rgba(
                                NotifHistory.appColor(modelData.app).r,
                                NotifHistory.appColor(modelData.app).g,
                                NotifHistory.appColor(modelData.app).b, 0.20)

                            Text {
                                anchors.centerIn: parent
                                text: NotifHistory.appLetter(modelData.app)
                                color: NotifHistory.appColor(modelData.app)
                                font.family: face.mono
                                font.pixelSize: 12
                                font.weight: Font.Bold
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 37
                            spacing: 2

                            Text {
                                width: parent.width
                                text: modelData.summary
                                color: Colors.fg
                                elide: Text.ElideRight
                                font.family: face.mono
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            Text {
                                width: parent.width
                                visible: text !== ""
                                text: modelData.body
                                color: Colors.fgDim
                                opacity: 0.65
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                font.family: face.mono
                                font.pixelSize: 11
                            }
                        }
                    }
                }
            }
        }
    }
    Component {
        id: cards

        Column {
            spacing: 8

            Repeater {
                model: face.recent

                Rectangle {
                    id: card

                    required property var modelData

                    width: 300
                    height: 62
                    radius: Shape.field
                    color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)

                    Sheen {
                        anchors.fill: parent
                        radius: Shape.field
                        edgeOpacity: 0.12
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        anchors.margins: 8
                        width: 3
                        radius: 1.5
                        color: NotifHistory.appColor(card.modelData.app)
                    }

                    Column {
                        anchors.fill: parent
                        anchors.leftMargin: 22
                        anchors.rightMargin: 14
                        anchors.topMargin: 11
                        spacing: 3

                        Text {
                            width: parent.width
                            text: card.modelData.summary
                            color: Colors.fg
                            elide: Text.ElideRight
                            font.family: face.mono
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                        }

                        Text {
                            width: parent.width
                            visible: text !== ""
                            text: card.modelData.body
                            color: Colors.fgDim
                            opacity: 0.65
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            font.family: face.mono
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }

    Component {
        id: apps

        Rectangle {
            implicitWidth: 260
            implicitHeight: senderList.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: senderList

                anchors.centerIn: parent
                width: parent.width - 34
                spacing: 10

                Repeater {
                    model: face.senders

                    Row {
                        id: sender

                        required property var modelData

                        width: senderList.width
                        spacing: 11

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: 28
                            height: 28
                            radius: Shape.detail + 2
                            antialiasing: true
                            color: Qt.rgba(
                                NotifHistory.appColor(sender.modelData.app).r,
                                NotifHistory.appColor(sender.modelData.app).g,
                                NotifHistory.appColor(sender.modelData.app).b, 0.20)

                            Text {
                                anchors.centerIn: parent
                                text: NotifHistory.appLetter(sender.modelData.app)
                                color: NotifHistory.appColor(sender.modelData.app)
                                font.family: face.mono
                                font.pixelSize: 13
                                font.weight: Font.Bold
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 90
                            elide: Text.ElideRight
                            text: sender.modelData.app
                            color: sender.modelData.critical ? Colors.bad : Colors.fg
                            opacity: 0.9
                            font.family: Fonts.display
                            font.pixelSize: 14
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: sender.modelData.entries.length
                            color: Colors.fgDim
                            opacity: 0.6
                            font.family: face.mono
                            font.pixelSize: 13
                        }
                    }
                }
            }
        }
    }

    Component {
        id: badge

        Item {
            implicitWidth: 62
            implicitHeight: 62

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                antialiasing: true
                color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.55)
                border.width: 1
                border.color: NotifHistory.unseen > 0
                    ? Qt.rgba(Colors.accent.r, Colors.accent.g, Colors.accent.b, 0.5)
                    : Qt.rgba(Colors.outline.r, Colors.outline.g, Colors.outline.b, 0.22)
            }

            Text {
                anchors.centerIn: parent
                text: NotifHistory.unseen > 0 ? "󰂚" : "󰂜"
                color: NotifHistory.unseen > 0 ? Colors.accent : Colors.fgDim
                font.family: face.mono
                font.pixelSize: 26
            }

            Rectangle {
                visible: NotifHistory.unseen > 0
                anchors.right: parent.right
                anchors.top: parent.top
                width: Math.max(22, unseenCount.implicitWidth + 10)
                height: 22
                radius: 11
                antialiasing: true
                color: Colors.accent

                Text {
                    id: unseenCount

                    anchors.centerIn: parent
                    text: NotifHistory.unseen
                    color: Colors.accentText
                    font.family: face.mono
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }
            }
        }
    }

    Component {
        id: compact

        Rectangle {
            implicitWidth: 280
            implicitHeight: 52
            radius: Shape.field
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.5)

            Sheen {
                anchors.fill: parent
                radius: Shape.field
                edgeOpacity: 0.14
            }

            Row {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 11

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: NotifHistory.unseen > 0 ? "󰂚" : "󰂜"
                    color: NotifHistory.unseen > 0 ? Colors.accent : Colors.fgDim
                    font.family: face.mono
                    font.pixelSize: 18
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: NotifHistory.unseen > 0
                        ? NotifHistory.unseen : NotifHistory.count
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 100
                    elide: Text.ElideRight
                    text: face.newest ? face.newest.summary : ""
                    color: Colors.fgDim
                    opacity: 0.7
                    font.family: face.mono
                    font.pixelSize: 12
                }
            }
        }
    }

    Component {
        id: dots

        Grid {
            columns: 10
            columnSpacing: 7
            rowSpacing: 7

            Repeater {
                model: NotifHistory.items.slice(0, 30)

                Rectangle {
                    id: mark

                    required property var modelData
                    required property int index

                    readonly property bool unseen: index < NotifHistory.unseen

                    width: 12
                    height: 12
                    radius: 6
                    antialiasing: true
                    color: NotifHistory.appColor(mark.modelData.app)
                    opacity: unseen ? 1 : 0.35

                    border.width: mark.modelData.critical ? 2 : 0
                    border.color: Colors.bad

                    Behavior on opacity { NumberAnimation { duration: Motion.base } }
                }
            }
        }
    }

    Component {
        id: ticker

        Row {
            spacing: 12

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 26
                height: 26
                radius: Shape.detail + 2
                antialiasing: true
                visible: face.newest !== null
                color: face.newest
                    ? Qt.rgba(NotifHistory.appColor(face.newest.app).r,
                              NotifHistory.appColor(face.newest.app).g,
                              NotifHistory.appColor(face.newest.app).b, 0.2)
                    : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: face.newest ? NotifHistory.appLetter(face.newest.app) : ""
                    color: face.newest
                        ? NotifHistory.appColor(face.newest.app) : Colors.fgDim
                    font.family: face.mono
                    font.pixelSize: 12
                    font.weight: Font.Bold
                }
            }

            Marquee {
                anchors.verticalCenter: parent.verticalCenter
                width: 320
                height: 24
                text: face.newest
                    ? face.newest.summary
                      + (face.newest.body !== "" ? "  ·  " + face.newest.body : "")
                    : ""
                color: Colors.fg
                family: face.mono
                pixelSize: 15
            }
        }
    }

    Component {
        id: latest

        Rectangle {
            implicitWidth: 320
            implicitHeight: 128
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.5)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 8

                Row {
                    spacing: 9

                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: 8
                        height: 8
                        radius: 4
                        antialiasing: true
                        color: face.newest
                            ? NotifHistory.appColor(face.newest.app) : Colors.fgDim
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: face.newest ? face.newest.app : ""
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: face.mono
                        font.pixelSize: 10
                        font.letterSpacing: 2
                    }
                }

                Text {
                    width: parent.width
                    text: face.newest ? face.newest.summary : ""
                    color: Colors.fg
                    elide: Text.ElideRight
                    font.family: Fonts.display
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Text {
                    width: parent.width
                    text: face.newest ? face.newest.body : ""
                    color: Colors.fgDim
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }

    Component {
        id: column

        Rectangle {
            implicitWidth: 190
            implicitHeight: narrow.implicitHeight + 30
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: narrow

                anchors.centerIn: parent
                width: parent.width - 30
                spacing: 10

                Repeater {
                    model: face.recent

                    Column {
                        id: entry

                        required property var modelData

                        width: narrow.width
                        spacing: 2

                        Text {
                            width: parent.width
                            text: entry.modelData.app
                            color: NotifHistory.appColor(entry.modelData.app)
                            opacity: 0.85
                            elide: Text.ElideRight
                            font.family: face.mono
                            font.pixelSize: 9
                            font.letterSpacing: 1
                        }

                        Text {
                            width: parent.width
                            text: entry.modelData.summary
                            color: Colors.fg
                            opacity: 0.9
                            elide: Text.ElideRight
                            font.family: face.mono
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
