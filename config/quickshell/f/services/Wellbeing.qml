pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property bool enabled: Prefs.wellbeingEnabled
    readonly property int tick: 15

    property bool paused: false

    property string today: ""
    property var apps: ({})
    property var history: []

    readonly property int total: {
        let n = 0;
        for (const k in root.apps) n += root.apps[k];
        return n;
    }

    readonly property var ranked: {
        const list = [];
        for (const k in root.apps)
            list.push({ app: k, seconds: root.apps[k] });
        list.sort((a, b) => b.seconds - a.seconds);
        return list;
    }

    readonly property string current: {
        const t = ToplevelManager.activeToplevel;
        if (!t)
            return "";
        return t.appId || "";
    }

    function stamp() {
        const d = new Date();
        return d.getFullYear() + "-"
             + String(d.getMonth() + 1).padStart(2, "0") + "-"
             + String(d.getDate()).padStart(2, "0");
    }

    function human(seconds) {
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        if (h > 0) return h + I18n.t("unit.hourSpace") + m + I18n.t("unit.min");
        if (m > 0) return m + I18n.t("unit.min");
        return seconds + I18n.t("unit.sec");
    }

    function label(app) {
        if (app === "") return "—";
        const entry = DesktopEntries.byId(app);
        return entry && entry.name ? entry.name : app;
    }

    function roll() {
        const now = root.stamp();
        if (root.today === now)
            return;

        if (root.today !== "" && root.total > 0) {
            const past = root.history.slice();
            past.push({
                date: root.today,
                total: root.total,
                top: root.ranked.length > 0 ? root.ranked[0].app : ""
            });
            root.history = past.slice(-14);
        }

        root.today = now;
        root.apps = ({});
        root.save();
    }

    function save() {
        store.today = root.today;
        store.apps = root.apps;
        store.history = root.history;
        file.writeAdapter();
    }

    function clear() {
        root.apps = ({});
        root.history = [];
        root.save();
    }

    Timer {
        running: root.enabled
        interval: root.tick * 1000
        repeat: true
        onTriggered: {
            root.roll();
            if (root.paused || root.current === "")
                return;

            const next = Object.assign({}, root.apps);
            next[root.current] = (next[root.current] || 0) + root.tick;
            root.apps = next;
        }
    }

    Timer {
        running: root.enabled
        interval: 3 * 60 * 1000
        repeat: true
        onTriggered: root.save()
    }

    FileView {
        id: file
        path: Quickshell.statePath("wellbeing.json")

        onLoaded: {
            root.today = store.today === "" ? root.stamp() : store.today;

            const apps = ({});
            const src = store.apps;
            for (const k in src)
                apps[k] = src[k];
            root.apps = apps;

            const past = [];
            for (let i = 0; i < store.history.length; i++)
                past.push(store.history[i]);
            root.history = past;

            root.roll();
        }

        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound) {
                root.today = root.stamp();
                root.save();
            }
        }

        JsonAdapter {
            id: store
            property string today: ""
            property var apps: ({})
            property var history: []
        }
    }
}
