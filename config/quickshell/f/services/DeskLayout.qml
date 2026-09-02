pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    property bool editing: false
    property int selected: -1

    readonly property var registry: ({
        "clock": {
            title: I18n.t("bar.clock"),
            glyph: "󰥔",
            faces: ["digital", "minimal", "hand"],
            size: 1.0
        },
        "media": {
            title: I18n.t("bar.music"),
            glyph: "󰎈",
            faces: ["cover", "round"],
            size: 1.0
        },
        "weather": {
            title: I18n.t("bar.weather"),
            glyph: "󰖐",
            faces: ["full", "compact"],
            size: 1.0
        },
        "usage": {
            title: I18n.t("bar.system"),
            glyph: "󰍛",
            faces: ["rings", "bars"],
            size: 1.0
        },
        "screentime": {
            title: I18n.t("desk.screentime"),
            glyph: "󰔟",
            faces: ["bars", "total"],
            size: 1.0
        }
    })

    readonly property var types: Object.keys(root.registry)

    property var items: []

    function nextKey() {
        let max = 0;
        for (const it of root.items)
            max = Math.max(max, it.key);
        return max + 1;
    }

    function add(type, screen) {
        const spec = root.registry[type];
        if (!spec)
            return;

        const list = root.items.slice();
        list.push({
            key: root.nextKey(),
            type: type,
            face: spec.faces[0],
            x: 0.5 + (list.length % 3) * 0.06 - 0.12,
            y: 0.35 + (list.length % 4) * 0.05,
            size: spec.size,
            screen: screen || ""
        });
        root.items = list;
        root.save();
    }

    function update(key, changes) {
        const list = [];
        for (const it of root.items)
            list.push(it.key === key ? Object.assign({}, it, changes) : it);
        root.items = list;
    }

    function remove(key) {
        root.items = root.items.filter(it => it.key !== key);
        if (root.selected === key)
            root.selected = -1;
        root.save();
    }

    function cycleFace(key) {
        const item = root.items.find(it => it.key === key);
        if (!item)
            return;
        const faces = root.registry[item.type].faces;
        const next = faces[(faces.indexOf(item.face) + 1) % faces.length];
        root.update(key, { face: next });
        root.save();
    }

    function resize(key, delta) {
        const item = root.items.find(it => it.key === key);
        if (!item)
            return;
        root.update(key, {
            size: Math.max(0.5, Math.min(3.0, item.size + delta))
        });
        root.save();
    }

    function forScreen(name) {
        return root.items.filter(it => it.screen === "" || it.screen === name);
    }

    function save() {
        store.items = root.items;
        file.writeAdapter();
    }

    FileView {
        id: file
        path: Quickshell.statePath("desk.json")

        onLoaded: {
            const list = [];
            for (let i = 0; i < store.items.length; i++) {
                const it = store.items[i];
                if (!it || !root.registry[it.type])
                    continue;
                list.push({
                    key: it.key,
                    type: it.type,
                    face: it.face,
                    x: it.x,
                    y: it.y,
                    size: it.size,
                    screen: it.screen || ""
                });
            }
            root.items = list;
        }

        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                return;
            root.items = [{
                key: 1, type: "clock", face: "minimal",
                x: 0.5, y: 0.28, size: 1.0, screen: ""
            }];
            root.save();
        }

        JsonAdapter {
            id: store
            property var items: []
        }
    }
}
