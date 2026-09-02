pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property int halfLifeDays: 14
    readonly property real halfLifeMs: root.halfLifeDays * 86400000

    property var entries: ({})

    function now() { return Date.now(); }

    function decay(from, to) {
        const age = Math.max(0, to - from);
        return Math.pow(0.5, age / root.halfLifeMs);
    }

    function score(id) {
        const e = root.entries[id];
        if (!e)
            return 0;
        return e.score * root.decay(e.at, root.now());
    }

    function bump(id) {
        if (!id)
            return;
        const at = root.now();
        const e = root.entries[id];
        const aged = e ? e.score * root.decay(e.at, at) : 0;

        const next = Object.assign({}, root.entries);
        next[id] = { score: aged + 1, at: at };
        root.entries = next;
        root.save();
    }

    function forget(id) {
        const next = Object.assign({}, root.entries);
        delete next[id];
        root.entries = next;
        root.save();
    }

    function save() {
        store.entries = root.entries;
        file.writeAdapter();
    }

    FileView {
        id: file
        path: Quickshell.statePath("frecency.json")
        blockLoading: true

        onLoaded: {
            const next = ({});
            const src = store.entries;
            for (const k in src) {
                const e = src[k];
                if (e && e.score !== undefined)
                    next[k] = { score: e.score, at: e.at || root.now() };
            }
            root.entries = next;
        }

        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                return;
            legacy.running = true;
        }

        JsonAdapter {
            id: store
            property var entries: ({})
        }
    }

    Process {
        id: legacy
        command: ["cat", Quickshell.statePath("launcher-usage.json")]
        stdout: StdioCollector {
            onStreamFinished: {
                const at = root.now();
                const next = ({});
                try {
                    const old = JSON.parse(text).counts || {};
                    for (const k in old)
                        next[k] = { score: Number(old[k]) || 0, at: at };
                } catch (e) {
                }
                root.entries = next;
                root.save();
            }
        }
    }
}
