pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var items: []
    property int seq: 1

    readonly property var open: root.items.filter(n => !n.done)
    readonly property int count: root.open.length

    function add(text) {
        let t = (text || "").trim();
        if (t === "")
            return null;
        t = t.charAt(0).toUpperCase() + t.slice(1);
        const n = { id: root.seq++, text: t, at: Date.now(), done: 0 };
        root.items = root.items.concat([n]);
        root.persist();
        return n;
    }

    function find(word) {
        const q = (word || "").trim().toLowerCase();
        if (q === "")
            return root.open.length > 0 ? root.open[root.open.length - 1] : null;
        const list = root.open.slice().reverse();
        const head = list.find(n => (" " + n.text.toLowerCase()).includes(" " + q));
        return head || list.find(n => n.text.toLowerCase().includes(q)) || null;
    }

    function finish(id) {
        root.items = root.items.map(n => n.id === id ? Object.assign({}, n, { done: Date.now() }) : n);
        root.persist();
    }

    function remove(id) {
        root.items = root.items.filter(n => n.id !== id);
        root.persist();
    }

    function persist() {
        const keep = Date.now() - 86400000;
        root.items = root.items.filter(n => !n.done || n.done > keep);
        adapter.list = JSON.stringify(root.items);
        view.writeAdapter();
    }

    function restore() {
        let rows;
        try {
            rows = JSON.parse(adapter.list || "[]");
        } catch (e) {
            return;
        }
        root.items = rows || [];
        for (const n of root.items)
            root.seq = Math.max(root.seq, n.id + 1);
    }

    FileView {
        id: view
        path: Quickshell.statePath("notes.json")
        watchChanges: false
        onLoaded: root.restore()
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                view.writeAdapter();
        }

        JsonAdapter {
            id: adapter
            property string list: "[]"
        }
    }

    IpcHandler {
        target: "notes"
        function add(text: string): string {
            const n = root.add(text);
            return n ? n.id + " " + n.text : "empty";
        }
        function done(word: string): string {
            const n = root.find(word);
            if (!n)
                return "none";
            root.finish(n.id);
            return n.id + " " + n.text;
        }
        function list(): string {
            return root.items.map(n => n.id + (n.done ? " ✓ " : "   ") + n.text).join("\n");
        }
        function remove(id: int): void { root.remove(id); }
    }
}
