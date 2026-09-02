import QtQuick

Item {
    id: grain

    property real amount: 0.035

    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../assets/grain.png")
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        opacity: grain.amount
        smooth: false
        cache: true
        asynchronous: true
    }
}
