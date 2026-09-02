pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import "root:/design"
import "root:/overlays"
import "root:/services"

Singleton {
    id: root

    readonly property int limit: 200

    readonly property var items: {
        const v = store.items;
        if (!v || v.length === undefined)
            return [];

        const out = [];
        for (let i = 0; i < v.length; i++)
            out.push(v[i]);
        return out;
    }

    readonly property int count: items.length

    readonly property int seenCount: Math.min(store.seenCount, count)
    readonly property int unseen: Math.max(0, count - seenCount)

    FileView {
        id: file
        path: Quickshell.statePath("notification-history.json")
        blockLoading: true
        watchChanges: false

        onLoadFailed: function () {
            store.items = [];
            file.writeAdapter();
        }

        JsonAdapter {
            id: store
            property var items: []
            property int seenCount: 0
        }
    }

    function commit(items, seen) {
        store.items = items;
        store.seenCount = Math.max(0, Math.min(seen, items.length));
        file.writeAdapter();
    }

    function add(n) {
        const entry = {
            id: String(n.id),
            app: n.appName || I18n.t("notif.system"),
            icon: n.appIcon || "",
            image: n.image || "",
            summary: n.summary || "",
            body: (n.body || "").replace(/<[^>]*>/g, "").trim(),
            critical: n.urgency === NotificationUrgency.Critical,
            time: Date.now()
        };

        root.commit([entry].concat(root.items).slice(0, root.limit),
                    root.seenCount);
    }

    function removeAt(index) {
        if (index < 0 || index >= root.items.length)
            return;
        const next = root.items.slice();
        next.splice(index, 1);
        root.commit(next, index < root.unseen ? root.seenCount : root.seenCount - 1);
    }

    function removeId(id) {
        root.removeAt(root.items.findIndex(e => e.id === id));
    }

    function clearApp(app) {
        const next = root.items.filter(e => e.app !== app);
        root.commit(next, root.seenCount - (root.items.length - next.length));
    }

    function clear() {
        root.commit([], 0);
    }

    function markSeen() {
        if (root.seenCount === root.count)
            return;
        root.commit(root.items, root.count);
    }

    readonly property var groups: {
        const order = [];
        const byApp = ({});

        for (let i = 0; i < items.length; i++) {
            const e = items[i];
            const key = e.app;
            if (byApp[key] === undefined) {
                byApp[key] = { app: key, icon: e.icon, entries: [], critical: false };
                order.push(key);
            }
            const copy = Object.assign({}, e);
            copy.index = i;
            byApp[key].entries.push(copy);

            if (e.critical)
                byApp[key].critical = true;
            if (byApp[key].icon === "" && e.icon !== "")
                byApp[key].icon = e.icon;
        }

        return order.map(k => byApp[k]);
    }

    function appHue(app) {
        let h = 0;
        for (let i = 0; i < app.length; i++)
            h = (h * 31 + app.charCodeAt(i)) % 3600;
        return h / 3600;
    }

    function appColor(app) {
        return Qt.hsla(root.appHue(app), Colors.statusSat, Colors.statusLight, 1);
    }

    function appLetter(app) {
        const t = (app || "?").trim();
        return t.length > 0 ? t.charAt(0).toUpperCase() : "?";
    }

    function ago(ms) {
        const diff = Date.now() - ms;
        if (diff < 60000)
            return I18n.t("time.now");

        const min = Math.floor(diff / 60000);
        if (min < 60)
            return min + I18n.t("unit.min");

        const hours = Math.floor(min / 60);
        if (hours < 24)
            return hours + I18n.t("unit.hour");

        if (hours < 48)
            return I18n.t("time.yesterday");

        return Qt.formatDateTime(new Date(ms), "dd.MM");
    }
}
