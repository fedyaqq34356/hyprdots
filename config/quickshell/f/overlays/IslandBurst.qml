import QtQuick
import "root:/design"

Item {
    id: burst

    property color tint: Colors.accent
    property int count: 12
    property real reach: 38
    property int delay: 140
    property int duration: 760

    width: 0
    height: 0

    function play() {
        for (let i = 0; i < sparks.count; i++) {
            const s = sparks.itemAt(i);
            if (s)
                s.fly();
        }
    }

    Component.onCompleted: burst.play()

    Repeater {
        id: sparks
        model: burst.count

        Rectangle {
            id: spark
            required property int index

            readonly property real ang:
                spark.index / burst.count * Math.PI * 2 + ((spark.index * 7) % 5) * 0.09
            readonly property real far:
                burst.reach * (0.7 + 0.3 * (((spark.index * 37) % 10) / 10))
            property real d: 0

            width: spark.index % 3 === 0 ? 4.5 : 3
            height: width
            radius: width / 2
            antialiasing: true
            color: spark.index % 2 ? burst.tint : Qt.lighter(burst.tint, 1.55)
            x: Math.cos(spark.ang) * spark.d - width / 2
            y: Math.sin(spark.ang) * spark.d - height / 2
            opacity: 0
            scale: 1

            function fly() { run.restart(); }

            SequentialAnimation {
                id: run
                PauseAnimation { duration: burst.delay + (spark.index % 4) * 18 }
                ParallelAnimation {
                    NumberAnimation {
                        target: spark; property: "d"
                        from: burst.reach * 0.35; to: spark.far
                        duration: burst.duration
                        easing.type: Easing.OutCubic
                    }
                    NumberAnimation {
                        target: spark; property: "scale"
                        from: 1.3; to: 0.3
                        duration: burst.duration
                        easing.type: Easing.InQuad
                    }
                    SequentialAnimation {
                        NumberAnimation {
                            target: spark; property: "opacity"
                            from: 0; to: 1; duration: 90
                        }
                        NumberAnimation {
                            target: spark; property: "opacity"
                            to: 0; duration: burst.duration - 90
                            easing.type: Easing.InCubic
                        }
                    }
                }
            }
        }
    }
}
