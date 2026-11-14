import Quickshell
import QtQuick

Timer {
    id: reaper

    required property LazyLoader loader
    readonly property var it: loader.item

    interval: 90000
    running: loader.active && !!it && !it.shown && it.busy !== true
    onTriggered: {
        if (it && !it.shown && it.busy !== true)
            loader.active = false;
    }
}
