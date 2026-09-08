import QtQuick
import "root:/services"

QtObject {
    id: hold

    property bool active: false

    property bool held: false

    onActiveChanged: hold.sync()

    function sync() {
        if (hold.active === hold.held)
            return;
        hold.held = hold.active;
        if (hold.active) Weather.hold();
        else Weather.release();
    }

    Component.onCompleted: hold.sync()
    Component.onDestruction: if (hold.held) Weather.release()
}
