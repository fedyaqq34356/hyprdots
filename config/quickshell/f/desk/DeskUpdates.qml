import Quickshell
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Item {
    id: face

    property string variant: "count"

    readonly property bool bare: face.variant === "count"
                              || face.variant === "badge"
                              || face.variant === "dots"
                              || face.variant === "minimal"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    opacity: Updates.ready && Updates.count > 0 ? 1 : 0
    visible: opacity > 0.01
    Behavior on opacity { NumberAnimation { duration: Motion.slow } }

    readonly property int repoCount: Updates.repo.length
    readonly property int aurCount: Updates.aur.length

    Loader {
        id: loader
        sourceComponent: face.variant === "list" ? list
                       : face.variant === "split" ? split
                       : face.variant === "grid" ? tiles
                       : face.variant === "badge" ? badge
                       : face.variant === "compact" ? compact
                       : face.variant === "dots" ? dots
                       : face.variant === "column" ? column
                       : face.variant === "minimal" ? minimal
                       : face.variant === "detail" ? detail
                       : count
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
                    color: Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                   Colors.accentAlt.b, 0.16)
                }

                Text {
                    anchors.centerIn: parent
                    text: Updates.busy ? "󰇚" : "󰏗"
                    color: Colors.accentAlt
                    font.family: face.mono
                    font.pixelSize: 24
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: -4

                Text {
                    text: Updates.count
                    color: Colors.fg
                    opacity: 0.92
                    font.family: face.mono
                    font.pixelSize: 46
                    font.weight: Font.Thin
                }

                Text {
                    text: I18n.t("desk.updates")
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
            implicitWidth: 280
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
                spacing: 9

                Row {
                    width: stack.width

                    Text {
                        text: "󰏗"
                        color: Colors.accentAlt
                        font.family: face.mono
                        font.pixelSize: 13
                    }

                    Item { width: 8; height: 1 }

                    Text {
                        text: Updates.count + "  " + I18n.t("desk.updates")
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: face.mono
                        font.pixelSize: 11
                        font.letterSpacing: 1
                    }
                }

                Repeater {
                    model: Updates.all.slice(0, 6)

                    Row {
                        required property var modelData

                        width: stack.width
                        spacing: 8

                        Text {
                            width: parent.width - 90
                            text: modelData.name
                            color: Colors.fg
                            elide: Text.ElideRight
                            font.family: face.mono
                            font.pixelSize: 12
                        }

                        Text {
                            width: 82
                            horizontalAlignment: Text.AlignRight
                            text: modelData.to
                            color: Colors.accentAlt
                            opacity: 0.8
                            elide: Text.ElideLeft
                            font.family: face.mono
                            font.pixelSize: 11
                        }
                    }
                }

                Text {
                    visible: Updates.count > 6
                    text: "+" + (Updates.count - 6)
                    color: Colors.fgDim
                    opacity: 0.5
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }
    Component {
        id: split

        Rectangle {
            implicitWidth: 260
            implicitHeight: 116
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Row {
                anchors.fill: parent
                anchors.margins: 20

                Repeater {
                    model: [
                        { label: "repo", value: face.repoCount, tint: Colors.accentAlt },
                        { label: "aur",  value: face.aurCount,  tint: Colors.accent }
                    ]

                    Column {
                        id: half

                        required property var modelData

                        width: 110
                        spacing: -2

                        Text {
                            text: half.modelData.value
                            color: half.modelData.tint
                            font.family: face.mono
                            font.pixelSize: 46
                            font.weight: Font.Thin
                        }

                        Text {
                            text: half.modelData.label
                            color: Colors.fgDim
                            opacity: 0.55
                            font.family: face.mono
                            font.pixelSize: 11
                            font.letterSpacing: 3
                        }
                    }
                }
            }
        }
    }

    Component {
        id: tiles

        Rectangle {
            implicitWidth: 300
            implicitHeight: pack.implicitHeight + 36
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Grid {
                id: pack

                anchors.centerIn: parent
                width: parent.width - 36
                columns: 2
                columnSpacing: 8
                rowSpacing: 8

                Repeater {
                    model: Updates.all.slice(0, 8)

                    Rectangle {
                        id: pkg

                        required property var modelData

                        width: (pack.width - pack.columnSpacing) / 2
                        height: 40
                        radius: Shape.chip
                        color: Qt.rgba(Colors.bgAlt.r, Colors.bgAlt.g,
                                       Colors.bgAlt.b, 0.35)

                        Column {
                            anchors.fill: parent
                            anchors.margins: 9
                            spacing: 1

                            Text {
                                width: parent.width
                                text: pkg.modelData.name
                                color: Colors.fg
                                elide: Text.ElideRight
                                font.family: face.mono
                                font.pixelSize: 11
                            }

                            Text {
                                width: parent.width
                                text: pkg.modelData.to
                                color: Colors.accentAlt
                                opacity: 0.75
                                elide: Text.ElideLeft
                                font.family: face.mono
                                font.pixelSize: 9
                            }
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
                border.color: Qt.rgba(Colors.accentAlt.r, Colors.accentAlt.g,
                                      Colors.accentAlt.b, 0.5)
            }

            Text {
                anchors.centerIn: parent
                text: Updates.busy ? "󰇚" : "󰏗"
                color: Colors.accentAlt
                font.family: face.mono
                font.pixelSize: 26
            }

            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                width: Math.max(22, pending.implicitWidth + 10)
                height: 22
                radius: 11
                antialiasing: true
                color: Colors.accentAlt

                Text {
                    id: pending

                    anchors.centerIn: parent
                    text: Updates.count
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
            implicitWidth: 270
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
                    text: Updates.busy ? "󰇚" : "󰏗"
                    color: Colors.accentAlt
                    font.family: face.mono
                    font.pixelSize: 18
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Updates.count
                    color: Colors.fg
                    font.family: face.mono
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - 110
                    elide: Text.ElideRight
                    text: Updates.all.length > 0 ? Updates.all[0].name : ""
                    color: Colors.fgDim
                    opacity: 0.65
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
                model: Math.min(30, Updates.count)

                Rectangle {
                    required property int index

                    readonly property bool aur: index >= face.repoCount

                    width: 11
                    height: 11
                    radius: 5.5
                    antialiasing: true
                    color: aur ? Colors.accent : Colors.accentAlt
                    opacity: aur ? 0.9 : 0.55

                    Behavior on color { ColorAnimation { duration: Colors.morph } }
                }
            }
        }
    }

    Component {
        id: column

        Rectangle {
            implicitWidth: 180
            implicitHeight: names.implicitHeight + 30
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: names

                anchors.centerIn: parent
                width: parent.width - 30
                spacing: 7

                Text {
                    text: Updates.count + " " + I18n.t("desk.updates")
                    color: Colors.accentAlt
                    opacity: 0.8
                    font.family: face.mono
                    font.pixelSize: 10
                    font.letterSpacing: 1
                }

                Repeater {
                    model: Updates.all.slice(0, 7)

                    Text {
                        required property var modelData

                        width: names.width
                        text: modelData.name
                        color: Colors.fg
                        opacity: 0.85
                        elide: Text.ElideRight
                        font.family: face.mono
                        font.pixelSize: 12
                    }
                }
            }
        }
    }

    Component {
        id: minimal

        Row {
            spacing: 10

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Updates.busy ? "󰇚" : "󰏗"
                color: Colors.accentAlt
                font.family: face.mono
                font.pixelSize: 20
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: Updates.count
                color: Colors.fg
                font.family: face.mono
                font.pixelSize: 28
                font.weight: Font.Light
            }
        }
    }

    Component {
        id: detail

        Rectangle {
            implicitWidth: 300
            implicitHeight: full.implicitHeight + 40
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.45)

            Sheen {
                anchors.fill: parent
                radius: Shape.card
                edgeOpacity: 0.12
            }

            Column {
                id: full

                anchors.centerIn: parent
                width: parent.width - 40
                spacing: 14

                Row {
                    width: parent.width

                    Text {
                        text: Updates.count
                        color: Colors.fg
                        font.family: face.mono
                        font.pixelSize: 34
                        font.weight: Font.Light
                    }

                    Item { width: parent.width - 190; height: 1 }

                    Text {
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        text: face.repoCount + " repo  ·  " + face.aurCount + " aur"
                        color: Colors.fgDim
                        opacity: 0.6
                        font.family: face.mono
                        font.pixelSize: 11
                    }
                }

                Row {
                    width: parent.width
                    height: 6
                    spacing: 3

                    Rectangle {
                        width: Math.max(3, (parent.width - 3)
                            * face.repoCount / Math.max(1, Updates.count))
                        height: parent.height
                        radius: 3
                        color: Colors.accentAlt
                        Behavior on width { NumberAnimation { duration: Motion.slow } }
                    }

                    Rectangle {
                        width: Math.max(3, (parent.width - 3)
                            * face.aurCount / Math.max(1, Updates.count))
                        height: parent.height
                        radius: 3
                        color: Colors.accent
                        Behavior on width { NumberAnimation { duration: Motion.slow } }
                    }
                }

                Repeater {
                    model: Updates.all.slice(0, 4)

                    Row {
                        id: entry

                        required property var modelData

                        width: full.width
                        spacing: 8

                        Text {
                            width: parent.width - 96
                            text: entry.modelData.name
                            color: Colors.fg
                            opacity: 0.9
                            elide: Text.ElideRight
                            font.family: face.mono
                            font.pixelSize: 12
                        }

                        Text {
                            width: 88
                            horizontalAlignment: Text.AlignRight
                            text: entry.modelData.from + " → " + entry.modelData.to
                            color: Colors.accentAlt
                            opacity: 0.75
                            elide: Text.ElideLeft
                            font.family: face.mono
                            font.pixelSize: 10
                        }
                    }
                }
            }
        }
    }
}
