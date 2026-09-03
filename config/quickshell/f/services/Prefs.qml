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
    readonly property string weatherPlace: adapter.weatherPlace
    readonly property string barPosition: adapter.barPosition
    readonly property string osdStyle: adapter.osdStyle
    readonly property bool barAtTop: adapter.barPosition !== "bottom"

    readonly property real uiScale: adapter.uiScale === undefined ? 1.0 : adapter.uiScale
    readonly property var monitorScales: adapter.monitorScales

    readonly property bool widgetsEnabled: adapter.widgetsEnabled
    readonly property bool quickActionsEnabled: adapter.quickActionsEnabled
    readonly property bool drawEnabled: adapter.drawEnabled
    readonly property bool wellbeingEnabled: adapter.wellbeingEnabled
    readonly property bool polkitEnabled: adapter.polkitEnabled
    readonly property bool dockEnabled: adapter.dockEnabled
    readonly property bool guideSeen: adapter.guideSeen
    readonly property bool greetingEnabled: adapter.greetingEnabled
    readonly property bool idleEnabled: adapter.idleEnabled
    readonly property int idleLockSec: adapter.idleLockSec
    readonly property int idleScreenOffSec: adapter.idleScreenOffSec

    readonly property string timerSound: adapter.timerSound
    readonly property real timerVolume: Math.max(0, Math.min(1, adapter.timerVolume))
    readonly property bool timerLoop: adapter.timerLoop
    readonly property int timerRingSec: adapter.timerRingSec
    readonly property bool timerTicking: adapter.timerTicking
    readonly property int timerTickSec: adapter.timerTickSec
    readonly property bool timerHalfway: adapter.timerHalfway
    readonly property bool timerNotify: adapter.timerNotify
    readonly property int timerSnoozeSec: adapter.timerSnoozeSec
    readonly property string timerCommand: adapter.timerCommand

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
            property string weatherPlace: ""
            property string barPosition: "top"
            property string osdStyle: "island"

            property real uiScale: 1.0
            property var monitorScales: ({})

            property bool widgetsEnabled: true
            property bool quickActionsEnabled: true
            property bool drawEnabled: true
            property bool wellbeingEnabled: true
            property bool polkitEnabled: true
            property bool dockEnabled: true

            property bool guideSeen: false
            property bool greetingEnabled: true

            property bool idleEnabled: true
            property int idleLockSec: 3000
            property int idleScreenOffSec: 3300

            property string timerSound: "chime"
            property real timerVolume: 0.8
            property bool timerLoop: true
            property int timerRingSec: 120
            property bool timerTicking: true
            property int timerTickSec: 5
            property bool timerHalfway: false
            property bool timerNotify: true
            property int timerSnoozeSec: 300
            property string timerCommand: ""
        }
    }
}
