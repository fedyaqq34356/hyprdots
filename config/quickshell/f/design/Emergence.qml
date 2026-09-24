pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    signal launched()

    function launch() { root.launched(); }
}
