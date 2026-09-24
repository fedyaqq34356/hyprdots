pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property var sources: [
        { key: "alarm",  glyph: "󰀠" },
        { key: "record", glyph: "󰑊" },
        { key: "osd",    glyph: "󰕾" },
        { key: "notif",  glyph: "󰂚" },
        { key: "bt",     glyph: "󰂱" },
        { key: "power",  glyph: "󰂄" },
        { key: "peri",   glyph: "󰍽" },
        { key: "net",    glyph: "󰖩" },
        { key: "vpn",    glyph: "󰦝" },
        { key: "print",  glyph: "󰐪" },
        { key: "route",  glyph: "󰓃" },
        { key: "focus",  glyph: "󰂛" },
        { key: "timer",  glyph: "󰔛" },
        { key: "media",  glyph: "󰎈" },
        { key: "clock",  glyph: "󰥔" }
    ]

    function sourceTitle(key) { return I18n.t("isle.src." + key); }

    readonly property var spec: ({
        enabled:     { type: "bool", def: true },

        srcAlarm:    { type: "bool", def: true },
        srcRecord:   { type: "bool", def: true },
        srcOsd:      { type: "bool", def: true },
        srcNotif:    { type: "bool", def: true },
        srcTimer:    { type: "bool", def: true },
        srcMedia:    { type: "bool", def: true },
        srcKeys:     { type: "bool", def: true },
        srcDesk:     { type: "bool", def: true },
        srcBt:       { type: "bool", def: true },
        srcPower:    { type: "bool", def: true },
        srcPeri:     { type: "bool", def: true },
        srcNet:      { type: "bool", def: true },
        srcVpn:      { type: "bool", def: true },
        srcPrint:    { type: "bool", def: true },
        srcRoute:    { type: "bool", def: true },
        srcFocus:    { type: "bool", def: true },
        srcClock:    { type: "bool", def: false },

        inBar:       { type: "bool", def: true },
        barTakeover: { type: "bool", def: true },

        edge:        { type: "pick", def: "top", values: ["top", "bottom"] },
        align:       { type: "pick", def: "center",
                       values: ["left", "center", "right"] },
        offsetX:     { type: "int", def: 0,  min: -800, max: 800 },
        offsetY:     { type: "int", def: 6,  min: 0,    max: 400 },
        where:       { type: "pick", def: "focus", values: ["focus", "all"] },

        pillHeight:  { type: "int", def: 28,  min: 18, max: 64 },
        pillMin:     { type: "int", def: 92, min: 60, max: 420 },
        wideWidth:   { type: "int", def: 420, min: 240, max: 900 },
        wideHeight:  { type: "int", def: 96,  min: 60,  max: 320 },
        mediaHeight: { type: "int", def: 158, min: 96,  max: 320 },
        radius:      { type: "int", def: 34,  min: 0,  max: 56 },

        black:       { type: "bool", def: true },
        fill:        { type: "int", def: 100, min: 0, max: 100 },
        borderAlpha: { type: "int", def: 0, min: 0, max: 100 },
        shadow:      { type: "bool", def: true },
        tintShadow:  { type: "bool", def: true },
        glow:        { type: "bool", def: true },
        glowAlpha:   { type: "int", def: 38, min: 0, max: 100 },
        ripple:      { type: "bool", def: true },
        blurSwap:    { type: "bool", def: true },
        artTint:     { type: "bool", def: true },
        privacy:     { type: "bool", def: true },
        sheen:       { type: "bool", def: true },
        jelly:       { type: "bool", def: true },
        tintEdge:    { type: "bool", def: true },
        rim:         { type: "bool", def: true },
        rimWidth:    { type: "int", def: 2, min: 1, max: 5 },

        minimal:     { type: "bool", def: true },
        minimalGap:  { type: "int", def: 14, min: 4, max: 40 },
        leftSlot:    { type: "bool", def: true },
        goo:         { type: "bool", def: true },

        hoverWide:   { type: "bool", def: true },
        tapWide:     { type: "bool", def: true },
        autoWide:    { type: "bool", def: true },
        autoWideMs:  { type: "int", def: 2200, min: 400, max: 8000 },
        dwellMs:     { type: "int", def: 2600, min: 300, max: 12000 },
        hideFull:    { type: "bool", def: true },
        eatPopups:   { type: "bool", def: true },
        sfx:         { type: "bool", def: true }
    })

    readonly property var groups: [
        { key: "src",    names: ["srcAlarm", "srcRecord", "srcOsd", "srcNotif",
                                 "srcTimer", "srcMedia", "srcKeys", "srcDesk",
                                 "srcBt", "srcPower", "srcPeri", "srcNet",
                                 "srcVpn", "srcPrint", "srcRoute", "srcFocus",
                                 "srcClock"] },
        { key: "place",  names: ["inBar", "barTakeover", "edge", "align",
                                 "where", "offsetX", "offsetY"] },
        { key: "size",   names: ["pillHeight", "pillMin", "wideWidth",
                                 "wideHeight", "mediaHeight", "radius",
                                 "minimalGap"] },
        { key: "paint",  names: ["black", "fill", "borderAlpha", "tintEdge",
                                 "artTint", "rim", "rimWidth", "sheen",
                                 "shadow", "tintShadow", "glow", "glowAlpha",
                                 "ripple", "blurSwap", "privacy", "jelly", "minimal",
                                 "leftSlot", "goo"] },
        { key: "act",    names: ["hoverWide", "tapWide", "autoWide",
                                 "autoWideMs", "dwellMs", "hideFull",
                                 "eatPopups", "sfx"] }
    ]

    function groupTitle(key) { return I18n.t("isle.sec." + key); }

    function optTitle(name) {
        const key = "isle.o." + name;
        const t = I18n.t(key);
        return t === key ? name : t;
    }

    function valueTitle(value) {
        const key = "isle.v." + value;
        const t = I18n.t(key);
        return t === key ? value : t;
    }

    property var style: ({})

    function s(name) {
        if (root.style && root.style[name] !== undefined)
            return root.style[name];
        const sp = root.spec[name];
        return sp ? sp.def : 0;
    }

    function on(key) {
        return root.s("src" + key.charAt(0).toUpperCase() + key.slice(1)) === true;
    }

    function setStyle(name, value) {
        const next = {};
        for (const k in root.style)
            next[k] = root.style[k];
        next[name] = value;
        root.style = next;
        root.save();
    }

    function reset() {
        root.style = ({});
        root.save();
    }

    Timer {
        id: flush
        interval: 400
        onTriggered: root.writeNow()
    }

    function save() { flush.restart(); }

    function writeNow() {
        flush.stop();
        store.style = root.style;
        file.writeAdapter();
    }

    FileView {
        id: file
        path: Quickshell.statePath("island.json")

        onLoaded: {
            const out = {};
            if (store.style) {
                for (const k in store.style)
                    out[k] = store.style[k];
            }
            root.style = out;
        }

        onLoadFailed: (error) => {
            if (error !== FileViewError.FileNotFound)
                return;
            root.style = ({});
            root.save();
        }

        JsonAdapter {
            id: store
            property var style: ({})
        }
    }
}
