import Quickshell
import QtQuick
import "root:/design"
import "root:/services"

Item {
    id: face

    property string variant: "bars"

    readonly property bool bare: face.variant === "total"

    readonly property string mono: "JetBrainsMono Nerd Font"

    implicitWidth: loader.implicitWidth
    implicitHeight: loader.implicitHeight

    readonly property var leaders: Wellbeing.ranked.slice(0, 4)
    readonly property int peak:
        face.leaders.length > 0 ? face.leaders[0].seconds : 1

    Loader {
        id: loader
        sourceComponent: face.variant === "total" ? total : bars
    }

    Component {
        id: total

        Column {
            spacing: 2

            Text {
                text: Wellbeing.human(Wellbeing.total)
                color: Colors.fg
                font.family: face.mono
                font.pixelSize: 38
                font.weight: Font.Light
            }

            Text {
                text: I18n.t("time.today")
                color: Colors.fgDim
                opacity: 0.6
                font.family: face.mono
                font.pixelSize: 11
                font.letterSpacing: 2
            }
        }
    }

    Component {
        id: bars

        Rectangle {
            implicitWidth: 260
            implicitHeight: body.implicitHeight + 32
            radius: Shape.card
            color: Qt.rgba(Colors.bg.r, Colors.bg.g, Colors.bg.b, 0.42)

            Sheen {
                anchors.fill: parent
                radius: parent.radius
                edgeOpacity: 0.12
            }

            Column {
                id: body
                anchors.centerIn: parent
                width: parent.width - 32
                spacing: 12

                Row {
                    width: parent.width

                    Text {
                        text: I18n.t("time.todayGlyph")
                        color: Colors.fgDim
                        opacity: 0.7
                        font.family: face.mono
                        font.pixelSize: 11
                        font.letterSpacing: 1
                    }

                    Item { width: parent.width - 170; height: 1 }

                    Text {
                        text: Wellbeing.human(Wellbeing.total)
                        color: Colors.accent
                        font.family: face.mono
                        font.pixelSize: 12
                    }
                }

                Repeater {
                    model: face.leaders

                    Column {
                        required property var modelData

                        width: body.width
                        spacing: 4

                        Row {
                            width: parent.width

                            Text {
                                width: parent.width - 74
                                text: Wellbeing.label(modelData.app)
                                color: Colors.fg
                                opacity: 0.85
                                elide: Text.ElideRight
                                font.family: Fonts.display
                                font.pixelSize: 13
                            }

                            Text {
                                text: Wellbeing.human(modelData.seconds)
                                color: Colors.fgDim
                                opacity: 0.6
                                font.family: face.mono
                                font.pixelSize: 11
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 3
                            radius: 2
                            color: Qt.rgba(Colors.outline.r, Colors.outline.g,
                                           Colors.outline.b, 0.18)

                            Rectangle {
                                width: parent.width * (modelData.seconds / Math.max(1, face.peak))
                                height: parent.height
                                radius: parent.radius
                                color: Colors.accentAlt
                                Behavior on width { NumberAnimation { duration: Motion.slow } }
                            }
                        }
                    }
                }

                Text {
                    visible: face.leaders.length === 0
                    text: I18n.t("state.nothingYet")
                    color: Colors.fgDim
                    opacity: 0.5
                    font.family: face.mono
                    font.pixelSize: 11
                }
            }
        }
    }
}
