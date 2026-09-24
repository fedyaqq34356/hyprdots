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
        barStyle:      { type: "pick", def: "modular",
                         values: ["modular", "solid", "bar"] },
        distinctPills: { type: "bool", def: false },

        monoWidth:   { type: "int", def: 100, min: 20, max: 100 },
        monoInset:   { type: "int", def: 0,   min: 0,  max: 12 },
        monoRadius:  { type: "int", def: 0,   min: 0,  max: 40 },
        monoFill:    { type: "int", def: 88,  min: 0,  max: 100 },
        monoBorder:  { type: "bool", def: false },
        monoRule:    { type: "bool", def: true },
        blob:          { type: "bool", def: true },
        blobFuse:      { type: "int", def: 4,   min: 0,  max: 30 },
        blobGlide:     { type: "bool", def: true },
        intro:         { type: "bool", def: true },
        hoverGrow:     { type: "bool", def: true },
        tooltips:      { type: "bool", def: true },

        autohide:      { type: "bool", def: false },
        autohideDelay: { type: "int", def: 600, min: 100, max: 3000 },
        autohidePeek:  { type: "int", def: 4,   min: 1,   max: 20 }
    })

    readonly property var styleGroups: [
        { key: "shape",  names: ["barStyle", "distinctPills", "radius",
                                 "barHeight", "islandHeight", "islandPadding",
                                 "itemSpacing", "islandGap", "edgeMargin"] },
        { key: "mono",   when: "bar",
                         names: ["monoWidth", "monoInset", "monoRadius",
                                 "monoFill", "monoBorder", "monoRule"] },
        { key: "paint",  names: ["fill", "fillHover", "border", "borderAlpha",
                                 "shadow"] },
        { key: "type",   names: ["fontSize", "glyphSize"] },
        { key: "motion", names: ["blob", "blobFuse", "blobGlide", "intro",
                                 "hoverGrow", "tooltips"] },
        { key: "hide",   names: ["autohide", "autohideDelay", "autohidePeek"] }
    ]

    function styleGroupTitle(key) { return I18n.t("barc.sec." + key); }

    function optTitle(name) {
        const key = "barc.o." + name;
        const t = I18n.t(key);
        return t === key ? name : t;
    }

    function valueTitle(value) {
        const key = "barc.v." + value;
        const t = I18n.t(key);
        return t === key ? value : t;
    }

    property bool perScreen: false

    property var cfgs: ({
        "*": { zones: { left: [], center: [], right: [] }, style: ({}) }
    })

    readonly property string sharedKey: "*"
    readonly property var zoneNames: ["left", "center", "right"]

    function key(screen) {
        if (!root.perScreen || !screen)
            return root.sharedKey;
        return root.cfgs[screen] !== undefined ? screen : root.sharedKey;
    }

    function cfg(screen) {
        const c = root.cfgs[root.key(screen)];
        return c ? c : root.cfgs[root.sharedKey];
    }

    property bool introPlayed: false

    function s(name, screen) {
        const c = root.cfg(screen);
        if (c && c.style && c.style[name] !== undefined)
            return c.style[name];
        const spec = root.styleSpec[name];
        return spec ? spec.def : 0;
    }

    function reserved(screen) {
        return root.s("autohide", screen) ? 0 : root.s("barHeight", screen);
    }

    function setStyle(name, value, screen) {
        const k = root.key(screen);
        const prev = root.cfg(screen);
        const style = {};
        for (const n in prev.style)
            style[n] = prev.style[n];
        style[name] = value;
        root.replaceCfg(k, { zones: prev.zones, style: style });
    }

    function resetStyle(screen) {
        const k = root.key(screen);
        const prev = root.cfg(screen);
        root.replaceCfg(k, { zones: prev.zones, style: ({}) });
    }

    function islands(zone, screen) {
        const c = root.cfg(screen);
        const z = c && c.zones ? c.zones[zone] : null;
        return z ? z : [];
    }

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

    function replaceCfg(k, nextCfg) {
        const all = {};
        for (const name in root.cfgs)
            all[name] = root.cfgs[name];
        all[k] = nextCfg;
        root.cfgs = all;
        root.save();
    }

    function cloneCfg(c) {
        const zones = {};
        for (const zone of root.zoneNames) {
            const src = (c && c.zones && c.zones[zone]) ? c.zones[zone] : [];
            const list = [];
            for (let i = 0; i < src.length; i++) {
                const items = [];
                for (let j = 0; j < src[i].items.length; j++) {
                    const it = src[i].items[j];
                    const opts = {};
                    for (const n in it.opts)
                        opts[n] = it.opts[n];
                    items.push({ key: root.nextKey(), type: it.type, opts: opts });
                }
                list.push({ key: root.nextKey(), items: items });
            }
            zones[zone] = list;
        }
        const style = {};
        if (c && c.style) {
            for (const n in c.style)
                style[n] = c.style[n];
        }
        return { zones: zones, style: style };
    }

    function setPerScreen(on, screens) {
        if (on) {
            const all = {};
            for (const name in root.cfgs)
                all[name] = root.cfgs[name];
            const base = root.cfgs[root.sharedKey];
            const list = screens ? screens : [];
            for (let i = 0; i < list.length; i++) {
                if (all[list[i]] === undefined)
                    all[list[i]] = root.cloneCfg(base);
            }
            root.cfgs = all;
        }
        root.perScreen = on;
        root.save();
    }

    function sameIslands(a, b) {
        if (a === b)
            return true;
        if (!a || !b || a.length !== b.length)
            return false;
        for (let i = 0; i < a.length; i++) {
            if (a[i] !== b[i])
                return false;
        }
        return true;
    }

    function mutate(screen, fn) {
        const k = root.key(screen);
        const prev = root.cfg(screen);
        const prevZones = prev.zones;
        const next = {
            left: prevZones.left.slice(),
            center: prevZones.center.slice(),
            right: prevZones.right.slice()
        };
        fn(next);

        for (const zone of root.zoneNames) {
            if (root.sameIslands(prevZones[zone], next[zone]))
                next[zone] = prevZones[zone];
        }

        root.replaceCfg(k, { zones: next, style: prev.style });
    }

    function addIsland(zone, screen) {
        root.mutate(screen, next => {
            next[zone] = next[zone].concat([{ key: root.nextKey(), items: [] }]);
        });
    }

    function removeIsland(zone, key, screen) {
        root.mutate(screen, next => {
            next[zone] = next[zone].filter(i => i.key !== key);
        });
    }

    function moveIsland(zone, key, delta, screen) {
        root.mutate(screen, next => {
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

    function islandToZone(zone, key, target, screen) {
        if (zone === target)
            return;
        root.mutate(screen, next => {
            const found = next[zone].find(i => i.key === key);
            if (!found)
                return;
            next[zone] = next[zone].filter(i => i.key !== key);
            next[target] = next[target].concat([found]);
        });
    }

    function addItem(zone, islandKey, type, screen) {
        root.mutate(screen, next => {
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

    function removeItem(zone, islandKey, itemKey, screen) {
        root.mutate(screen, next => {
            next[zone] = next[zone].map(isle => {
                if (isle.key !== islandKey)
                    return isle;
                return { key: isle.key, items: isle.items.filter(i => i.key !== itemKey) };
            });
        });
    }

    function moveItem(zone, islandKey, itemKey, delta, screen) {
        root.mutate(screen, next => {
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

    function setItemOpt(zone, islandKey, itemKey, name, value, screen) {
        root.mutate(screen, next => {
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

    function reset(screen) {
        root.replaceCfg(root.key(screen),
                        { zones: root.defaults(), style: ({}) });
    }

    function copyCfg(fromScreen, toScreen) {
        if (fromScreen === toScreen)
            return;
        root.replaceCfg(root.key(toScreen),
                        root.cloneCfg(root.cfg(fromScreen)));
    }

    Timer {
        id: flush
        interval: 400
        onTriggered: root.writeNow()
    }

    function save() { flush.restart(); }

    function writeNow() {
        flush.stop();
        store.perScreen = root.perScreen;
        store.cfgs = root.cfgs;
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

    function readZones(raw) {
        if (!raw || !raw.left)
            return root.defaults();
        return {
            left: root.readIslands(raw.left),
            center: root.readIslands(raw.center),
            right: root.readIslands(raw.right)
        };
    }

    function readStyle(raw) {
        const out = {};
        if (raw) {
            for (const k in raw)
                out[k] = raw[k];
        }
        return out;
    }

    FileView {
        id: file
        path: Quickshell.statePath("bar.json")

        onLoaded: {
            const out = {};
            let any = false;

            const raw = store.cfgs;
            if (raw) {
                for (const k in raw) {
                    const c = raw[k];
                    if (!c)
                        continue;
                    out[k] = {
                        zones: root.readZones(c.zones),
                        style: root.readStyle(c.style)
                    };
                    any = true;
                }
            }

            if (!any) {
                out[root.sharedKey] = {
                    zones: root.readZones(store.zones),
                    style: root.readStyle(store.style)
                };
            }

            if (out[root.sharedKey] === undefined)
                out[root.sharedKey] = { zones: root.defaults(), style: ({}) };

            root.cfgs = out;
            root.perScreen = store.perScreen === true;

            let max = 0;
            for (const name in root.cfgs) {
                const zones = root.cfgs[name].zones;
                for (const zone of root.zoneNames) {
                    for (const isle of zones[zone]) {
                        max = Math.max(max, isle.key);
                        for (const it of isle.items)
                            max = Math.max(max, it.key);
                    }
                }
            }
            root.keySeed = max + 1;
        }

        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                return;
            root.cfgs = ({
                "*": { zones: root.defaults(), style: ({}) }
            });
            root.perScreen = false;
            root.save();
        }

        JsonAdapter {
            id: store
            property var cfgs: ({})
            property bool perScreen: false
            property var zones: ({})
            property var style: ({})
        }
    }
}
