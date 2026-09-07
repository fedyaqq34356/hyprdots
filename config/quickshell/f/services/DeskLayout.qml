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
            faces: ["minimal", "digital", "roll", "flip", "words", "hand",
                    "ring", "orbit", "binary", "bar"],
            size: 1.0
        },
        "media": {
            title: I18n.t("bar.music"),
            glyph: "󰎈",
            faces: ["cover", "poster", "tile", "stack", "round", "wave",
                    "pulse", "strip", "frame", "line"],
            size: 1.0
        },
        "weather": {
            title: I18n.t("bar.weather"),
            glyph: "󰖐",
            faces: ["full", "detail", "sky", "hero", "ring", "range",
                    "forecast", "strip", "compact", "badge"],
            size: 1.0
        },
        "usage": {
            title: I18n.t("bar.system"),
            glyph: "󰍛",
            faces: ["rings", "bars", "digits", "full", "meters", "compact",
                    "grid", "column", "gauge", "trace"],
            size: 1.0
        },
        "screentime": {
            title: I18n.t("desk.screentime"),
            glyph: "󰔟",
            faces: ["bars", "grid", "stack", "donut", "week", "budget",
                    "list", "now", "ring", "total"],
            size: 1.0
        },
        "visualizer": {
            title: I18n.t("desk.visualizer"),
            glyph: "󰗆",
            faces: ["bars", "mirror", "flame", "grid", "dots", "tape",
                    "wave", "line", "radial", "orb"],
            size: 1.0
        },
        "timer": {
            title: I18n.t("timer.title"),
            glyph: "󰔛",
            faces: ["ring", "arc", "digits", "bar", "sand", "list",
                    "grid", "pills", "stack", "minimal"],
            size: 1.0
        },
        "calendar": {
            title: I18n.t("bar.calendar"),
            glyph: "󰃭",
            faces: ["month", "week", "day", "tear", "ring", "list",
                    "year", "column", "dots", "compact"],
            size: 1.0
        },
        "battery": {
            title: I18n.t("desk.battery"),
            glyph: "󰁹",
            faces: ["ring", "cell", "detail", "arc", "wave", "digits",
                    "column", "dots", "bar", "pill"],
            size: 1.0
        },
        "disk": {
            title: I18n.t("desk.disk"),
            glyph: "󰋊",
            faces: ["bars", "grid", "rings", "column", "stack", "donut",
                    "gauge", "list", "dots", "compact"],
            size: 1.0
        },
        "net": {
            title: I18n.t("desk.net"),
            glyph: "󰤨",
            faces: ["link", "detail", "graph", "meters", "dial", "bars",
                    "column", "speed", "minimal", "badge"],
            size: 1.0
        },
        "notifs": {
            title: I18n.t("desk.notifs"),
            glyph: "󰂚",
            faces: ["list", "cards", "latest", "apps", "column", "compact",
                    "ticker", "dots", "count", "badge"],
            size: 1.0
        },
        "updates": {
            title: I18n.t("desk.updates"),
            glyph: "󰏗",
            faces: ["count", "list", "detail", "grid", "split", "column",
                    "compact", "dots", "minimal", "badge"],
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
