pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property var registry: ({
        "workspaces": {
            title: I18n.t("barc.workspaces"), glyph: "󰧨", group: "system",
            opts: { pill: { type: "bool", def: true } }
        },
        "media": {
            title: I18n.t("barc.media"), glyph: "󰎈", group: "media",
            opts: {
                width: { type: "int", def: 152, min: 60, max: 420 },
                spectrum: { type: "bool", def: true },
                cover: { type: "bool", def: true }
            }
        },
        "clock": {
            title: I18n.t("barc.clock"), glyph: "󰥔", group: "time",
            opts: {
                format: { type: "text", def: "HH:mm" },
                seconds: { type: "bool", def: true },
                feedback: { type: "bool", def: true }
            }
        },
        "tray": {
            title: I18n.t("barc.tray"), glyph: "󰀻", group: "system",
            opts: { size: { type: "int", def: 15, min: 10, max: 24 } }
        },
        "network": {
            title: I18n.t("barc.network"), glyph: "󰤨", group: "net",
            opts: { label: { type: "bool", def: false } }
        },
        "bluetooth": {
            title: I18n.t("net.bluetooth2"), glyph: "󰂯", group: "net", opts: {}
        },
        "vpn": { title: "VPN", glyph: "󰦝", group: "net", opts: {} },
        "netspeed": {
            title: I18n.t("barc.netspeed"), glyph: "󰓅", group: "net",
            opts: { down: { type: "bool", def: true }, up: { type: "bool", def: true } }
        },
        "volume": {
            title: I18n.t("audio.volume2"), glyph: "󰕾", group: "audio",
            opts: { percent: { type: "bool", def: true } }
        },
        "mic": { title: I18n.t("barc.mic"), glyph: "󰍬", group: "audio", opts: {} },
        "battery": {
            title: I18n.t("barc.battery"), glyph: "󰁹", group: "system",
            opts: { percent: { type: "bool", def: true } }
        },
        "keyboard": {
            title: I18n.t("barc.keyboard"), glyph: "󰌌", group: "system", opts: {}
        },
        "brightness": {
            title: I18n.t("barc.brightness"), glyph: "󰃞", group: "system",
            opts: { percent: { type: "bool", def: true } }
        },
        "peripherals": {
            title: I18n.t("barc.peripherals"), glyph: "󰍽", group: "system", opts: {}
        },
        "recorder": {
            title: I18n.t("barc.recorder"), glyph: "󰑊", group: "system", opts: {}
        },
        "outbound": {
            title: I18n.t("barc.outbound"), glyph: "󰀂", group: "net", opts: {}
        },
        "updates": {
            title: I18n.t("barc.updates"), glyph: "󰏗", group: "system",
            opts: { count: { type: "bool", def: true } }
        },
        "notifs": {
            title: I18n.t("barc.notifs"), glyph: "󰂚", group: "system",
            opts: { count: { type: "bool", def: true } }
        },
        "dnd": { title: I18n.t("barc.dnd"), glyph: "󰂛", group: "system", opts: {} },
        "cpu": {
            title: "CPU", glyph: "󱠓", group: "meters",
            opts: { label: { type: "bool", def: true }, bar: { type: "bool", def: false } }
        },
        "ram": {
            title: "RAM", glyph: "󰍛", group: "meters",
            opts: { label: { type: "bool", def: true }, bar: { type: "bool", def: false } }
        },
        "gpu": {
            title: "GPU", glyph: "󰢮", group: "meters",
            opts: { label: { type: "bool", def: true }, bar: { type: "bool", def: false } }
        },
        "vram": {
            title: "VRAM", glyph: "󰍛", group: "meters",
            opts: { label: { type: "bool", def: true }, bar: { type: "bool", def: false } }
        },
        "temp": {
            title: I18n.t("barc.cputemp"), glyph: "󰔏", group: "meters",
            opts: { label: { type: "bool", def: true }, bar: { type: "bool", def: false } }
        },
        "gputemp": {
            title: I18n.t("barc.gputemp"), glyph: "󰔏", group: "meters",
            opts: { label: { type: "bool", def: true }, bar: { type: "bool", def: false } }
        },
        "disk": {
            title: I18n.t("barc.disk"), glyph: "󰋊", group: "meters",
            opts: { mount: { type: "text", def: "/" } }
        },
        "weather": {
            title: I18n.t("barc.weather"), glyph: "󰖐", group: "time",
            opts: { icon: { type: "bool", def: true } }
        },
        "uptime": {
            title: I18n.t("barc.uptime"), glyph: "󰅐", group: "time", opts: {}
        },
        "date": {
            title: I18n.t("barc.date"), glyph: "󰃭", group: "time",
            opts: { format: { type: "text", def: "ddd d MMM" } }
        },
        "timer": {
            title: I18n.t("barc.timer"), glyph: "󰔛", group: "time", opts: {}
        },
        "sep": {
            title: I18n.t("barc.sep"), glyph: "󰇂", group: "layout", opts: {}
        },
        "spacer": {
            title: I18n.t("barc.spacer"), glyph: "󰇄", group: "layout",
            opts: { size: { type: "int", def: 16, min: 2, max: 200 } }
        },
        "text": {
            title: I18n.t("barc.text"), glyph: "󰚞", group: "layout",
            opts: {
                content: { type: "text", def: "hello" },
                glyph: { type: "text", def: "" }
            }
        },
        "command": {
            title: I18n.t("barc.command"), glyph: "󰆍", group: "layout",
            opts: {
                run: { type: "text", def: "date +%s" },
                every: { type: "int", def: 10, min: 1, max: 3600 },
                glyph: { type: "text", def: "" },
                click: { type: "text", def: "" }
            }
        }
    })

    readonly property var types: Object.keys(root.registry)

    readonly property var groups: ["system", "media", "audio", "net", "meters",
                                   "time", "layout"]

    function groupTitle(g) { return I18n.t("barc.group." + g); }

    function optionsFor(type) {
        const spec = root.registry[type];
        return spec ? spec.opts : ({});
    }

    function opt(item, name) {
        if (item && item.opts && item.opts[name] !== undefined)
            return item.opts[name];
        const spec = root.registry[item ? item.type : ""];
        if (spec && spec.opts[name])
            return spec.opts[name].def;
        return undefined;
    }

    readonly property var styleSpec: ({
        barHeight:     { type: "int", def: 34,  min: 20, max: 80 },
        islandHeight:  { type: "int", def: 26,  min: 14, max: 72 },
        edgeMargin:    { type: "int", def: 8,   min: 0,  max: 80 },
        islandGap:     { type: "int", def: 8,   min: 0,  max: 60 },
        itemSpacing:   { type: "int", def: 8,   min: 0,  max: 40 },
        islandPadding: { type: "int", def: 10,  min: 0,  max: 40 },
        radius:        { type: "int", def: 12,  min: 0,  max: 40 },
        fontSize:      { type: "int", def: 11,  min: 7,  max: 22 },
        glyphSize:     { type: "int", def: 12,  min: 7,  max: 26 },
        fill:          { type: "int", def: 80,  min: 0,  max: 100 },
        fillHover:     { type: "int", def: 92,  min: 0,  max: 100 },
        borderAlpha:   { type: "int", def: 32,  min: 0,  max: 100 },
        shadow:        { type: "bool", def: true },
        border:        { type: "bool", def: true },
        intro:         { type: "bool", def: true },
        hoverGrow:     { type: "bool", def: true },
        tooltips:      { type: "bool", def: true }
    })

    property var style: ({})

    function s(name) {
        if (root.style && root.style[name] !== undefined)
            return root.style[name];
        const spec = root.styleSpec[name];
        return spec ? spec.def : 0;
    }

    function setStyle(name, value) {
        const next = Object.assign({}, root.style);
        next[name] = value;
        root.style = next;
        root.save();
    }

    function resetStyle() {
        root.style = ({});
        root.save();
    }

    property var zones: ({ left: [], center: [], right: [] })

    readonly property var zoneNames: ["left", "center", "right"]

    function defaults() {
        function m(type, opts) {
            return { key: root.nextKey(), type: type, opts: opts || ({}) };
        }
        function isle(items) {
            return { key: root.nextKey(), items: items };
        }
        return {
            left: [
                isle([m("workspaces")]),
                isle([m("media")])
            ],
            center: [
                isle([m("clock")])
            ],
            right: [
                isle([
                    m("outbound"), m("recorder"), m("tray"), m("sep"),
                    m("vpn"), m("network"), m("bluetooth"), m("mic"),
                    m("volume"), m("sep"),
                    m("peripherals"), m("keyboard"), m("battery")
                ])
            ]
        };
    }

    property int keySeed: 1
    function nextKey() { return root.keySeed++; }

    function islands(zone) {
        const z = root.zones[zone];
        return z ? z : [];
    }

    function mutate(fn) {
        const next = {
            left: root.zones.left.slice(),
            center: root.zones.center.slice(),
            right: root.zones.right.slice()
        };
        fn(next);
        root.zones = next;
        root.save();
    }

    function addIsland(zone) {
        root.mutate(next => {
            next[zone] = next[zone].concat([{ key: root.nextKey(), items: [] }]);
        });
    }

    function removeIsland(zone, key) {
        root.mutate(next => {
            next[zone] = next[zone].filter(i => i.key !== key);
        });
    }

    function moveIsland(zone, key, delta) {
        root.mutate(next => {
            const list = next[zone].slice();
            const i = list.findIndex(x => x.key === key);
            const j = i + delta;
            if (i < 0 || j < 0 || j >= list.length)
                return;
            const tmp = list[i];
            list[i] = list[j];
            list[j] = tmp;
            next[zone] = list;
        });
    }

    function islandToZone(zone, key, target) {
        if (zone === target)
            return;
        root.mutate(next => {
            const found = next[zone].find(i => i.key === key);
            if (!found)
                return;
            next[zone] = next[zone].filter(i => i.key !== key);
            next[target] = next[target].concat([found]);
        });
    }

    function addItem(zone, islandKey, type) {
        root.mutate(next => {
            next[zone] = next[zone].map(isle => {
                if (isle.key !== islandKey)
                    return isle;
                return {
                    key: isle.key,
                    items: isle.items.concat([
                        { key: root.nextKey(), type: type, opts: ({}) }
                    ])
                };
            });
        });
    }

    function removeItem(zone, islandKey, itemKey) {
        root.mutate(next => {
            next[zone] = next[zone].map(isle => {
                if (isle.key !== islandKey)
                    return isle;
                return { key: isle.key, items: isle.items.filter(i => i.key !== itemKey) };
            });
        });
    }

    function moveItem(zone, islandKey, itemKey, delta) {
        root.mutate(next => {
            next[zone] = next[zone].map(isle => {
                if (isle.key !== islandKey)
                    return isle;
                const list = isle.items.slice();
                const i = list.findIndex(x => x.key === itemKey);
                const j = i + delta;
                if (i < 0 || j < 0 || j >= list.length)
                    return isle;
                const tmp = list[i];
                list[i] = list[j];
                list[j] = tmp;
                return { key: isle.key, items: list };
            });
        });
    }

    function setItemOpt(zone, islandKey, itemKey, name, value) {
        root.mutate(next => {
            next[zone] = next[zone].map(isle => {
                if (isle.key !== islandKey)
                    return isle;
                return {
                    key: isle.key,
                    items: isle.items.map(it => {
                        if (it.key !== itemKey)
                            return it;
                        const opts = Object.assign({}, it.opts);
                        opts[name] = value;
                        return { key: it.key, type: it.type, opts: opts };
                    })
                };
            });
        });
    }

    function reset() {
        root.keySeed = 1;
        root.zones = root.defaults();
        root.style = ({});
        root.save();
    }

    function save() {
        store.zones = root.zones;
        store.style = root.style;
        file.writeAdapter();
    }

    function readIslands(raw) {
        const out = [];
        if (!raw || raw.length === undefined)
            return out;
        for (let i = 0; i < raw.length; i++) {
            const isle = raw[i];
            if (!isle)
                continue;
            const items = [];
            const src = isle.items;
            if (src && src.length !== undefined) {
                for (let j = 0; j < src.length; j++) {
                    const it = src[j];
                    if (!it || !root.registry[it.type])
                        continue;
                    const opts = {};
                    if (it.opts) {
                        for (const k in it.opts)
                            opts[k] = it.opts[k];
                    }
                    items.push({
                        key: it.key !== undefined ? it.key : root.nextKey(),
                        type: it.type,
                        opts: opts
                    });
                }
            }
            out.push({
                key: isle.key !== undefined ? isle.key : root.nextKey(),
                items: items
            });
        }
        return out;
    }

    FileView {
        id: file
        path: Quickshell.statePath("bar.json")

        onLoaded: {
            const raw = store.zones;
            if (!raw || !raw.left) {
                root.zones = root.defaults();
            } else {
                root.zones = {
                    left: root.readIslands(raw.left),
                    center: root.readIslands(raw.center),
                    right: root.readIslands(raw.right)
                };
            }

            const st = {};
            if (store.style) {
                for (const k in store.style)
                    st[k] = store.style[k];
            }
            root.style = st;

            let max = 0;
            for (const zone of root.zoneNames) {
                for (const isle of root.zones[zone]) {
                    max = Math.max(max, isle.key);
                    for (const it of isle.items)
                        max = Math.max(max, it.key);
                }
            }
            root.keySeed = max + 1;
        }

        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                return;
            root.zones = root.defaults();
            root.style = ({});
            root.save();
        }

        JsonAdapter {
            id: store
            property var zones: ({})
            property var style: ({})
        }
    }
}
