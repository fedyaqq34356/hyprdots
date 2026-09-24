import QtQuick
import "root:/design"

QtObject {
    id: hold

    property bool active: false

    property bool held: false
    property bool slow: false

    onActiveChanged: hold.sync()

    function sync() {
        if (hold.active === hold.held)
            return;
        hold.held = hold.active;
        if (hold.slow)
            Phase.slowHolders += hold.active ? 1 : -1;
        else
            Phase.holders += hold.active ? 1 : -1;
    }

    Component.onCompleted: hold.sync()
    Component.onDestruction: {
        if (!hold.held)
            return;
        if (hold.slow)
            Phase.slowHolders -= 1;
        else
            Phase.holders -= 1;
    }
}
