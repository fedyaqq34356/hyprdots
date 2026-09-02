pragma Singleton

import Quickshell
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property var query: null

    function skeleton(v) {
        return (v || "").toLowerCase().replace(/[^a-z0-9]/g, "");
    }

    function candidates(entry) {
        if (!entry) return [];
        const out = [];
        const push = v => { if (v) out.push(v); };

        push(entry.startupClass);
        push(entry.id);
        if (entry.id) push(entry.id.replace(/\.desktop$/, ""));
        push(entry.name);
        return out;
    }

    function matches(entry, cls) {
        if (!entry || !cls) return false;

        const c = skeleton(cls);
        if (c.length < 3) return false;

        for (const raw of root.candidates(entry)) {
            const x = root.skeleton(raw);
            if (x.length < 3) continue;
            if (x === c) return true;
            if (c.endsWith(x) || x.endsWith(c)) return true;
        }
        return false;
    }

    readonly property var workspaces: {
        const out = [];
        if (!query) return out;

        const list = Hyprland.toplevels ? Hyprland.toplevels.values : [];
        for (const t of list) {
            if (!t) continue;
            const o = t.lastIpcObject;
            if (!o || !o.workspace) continue;
            if (!root.matches(root.query, o["class"])) continue;
            const id = o.workspace.id;
            if (out.indexOf(id) === -1) out.push(id);
        }
        return out;
    }

    readonly property bool any: workspaces.length > 0

    function onWorkspace(id) {
        return workspaces.indexOf(id) !== -1;
    }
}
