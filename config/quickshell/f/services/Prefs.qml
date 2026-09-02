pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property bool sfxEnabled: adapter.sfxEnabled
    readonly property real sfxVolume: Math.max(0, Math.min(1, adapter.sfxVolume))
    readonly property string notifySound: adapter.notifySound
    readonly property string language: adapter.language
    readonly property string fontDisplay: adapter.fontDisplay
    readonly property string barPosition: adapter.barPosition
    readonly property bool barAtTop: adapter.barPosition !== "bottom"

    readonly property bool widgetsEnabled: adapter.widgetsEnabled
    readonly property bool quickActionsEnabled: adapter.quickActionsEnabled
    readonly property bool drawEnabled: adapter.drawEnabled
    readonly property bool wellbeingEnabled: adapter.wellbeingEnabled
    readonly property bool polkitEnabled: adapter.polkitEnabled
    readonly property bool dockEnabled: adapter.dockEnabled
    readonly property bool guideSeen: adapter.guideSeen
    readonly property bool idleEnabled: adapter.idleEnabled
    readonly property int idleLockSec: adapter.idleLockSec
    readonly property int idleScreenOffSec: adapter.idleScreenOffSec

    readonly property bool loaded: view.loaded

    function set(key, value) {
        if (adapter[key] === value)
            return;
        adapter[key] = value;
        view.writeAdapter();
    }

    function toggle(key) {
        root.set(key, !adapter[key]);
    }

    FileView {
        id: view

        property bool loaded: false

        path: Quickshell.statePath("config.json")
        watchChanges: true
        onFileChanged: view.reload()
        onLoaded: view.loaded = true
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                view.writeAdapter();
                view.loaded = true;
            }
        }

        JsonAdapter {
            id: adapter

            property bool sfxEnabled: true
            property real sfxVolume: 0.55
            property string notifySound: "Sine"
            property string language: "en"
            property string fontDisplay: "Adwaita Sans"
            property string barPosition: "top"

            property bool widgetsEnabled: true
            property bool quickActionsEnabled: true
            property bool drawEnabled: true
            property bool wellbeingEnabled: true
            property bool polkitEnabled: true
            property bool dockEnabled: true

            property bool guideSeen: false

            property bool idleEnabled: true
            property int idleLockSec: 3000
            property int idleScreenOffSec: 3300
        }
    }
}
