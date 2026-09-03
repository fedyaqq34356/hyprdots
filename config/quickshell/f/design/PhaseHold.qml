import QtQuick
import "root:/design"

QtObject {
    id: hold

    property bool active: false

    property bool held: false

    onActiveChanged: hold.sync()

    function sync() {
        if (hold.active === hold.held)
            return;
        hold.held = hold.active;
        Phase.holders += hold.active ? 1 : -1;
    }

    Component.onCompleted: hold.sync()
    Component.onDestruction: if (hold.held) Phase.holders -= 1;
}
