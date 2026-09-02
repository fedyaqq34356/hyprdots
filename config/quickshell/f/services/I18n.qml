pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property string lang: Prefs.language
    readonly property var codes: ["en", "ru"]

    property var tables: ({})

    readonly property var table: root.tables[root.lang] || ({})
    readonly property var fallback: root.tables["en"] || ({})

    function t(key) {
        const value = root.table[key];
        if (value !== undefined)
            return value;
        const spare = root.fallback[key];
        return spare !== undefined ? spare : key;
    }

    function list(key) {
        const value = root.t(key);
        return Array.isArray(value) ? value : [];
    }

    function plural(key, n) {
        const forms = root.t(key);
        if (typeof forms === "string")
            return forms;

        if (root.lang === "ru") {
            const tens = Math.abs(n) % 100;
            if (tens >= 11 && tens <= 14)
                return forms.many;
            const ones = Math.abs(n) % 10;
            if (ones === 1)
                return forms.one;
            if (ones >= 2 && ones <= 4)
                return forms.few;
            return forms.many;
        }

        return Math.abs(n) === 1 ? forms.one : forms.many;
    }

    function count(key, n) {
        return n + " " + root.plural(key, n);
    }

    readonly property string dir:
        Quickshell.env("HOME") + "/.config/quickshell/f/lang/"

    function absorb(code, text) {
        try {
            const next = Object.assign({}, root.tables);
            next[code] = JSON.parse(text);
            root.tables = next;
        } catch (e) {
            console.warn("i18n: broken table for " + code);
        }
    }

    FileView {
        path: root.dir + "en.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.absorb("en", text())
    }

    FileView {
        path: root.dir + "ru.json"
        blockLoading: true
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.absorb("ru", text())
    }
}
