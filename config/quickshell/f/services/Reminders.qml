pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property var items: []
    property int seq: 1

    signal due(var item)

    property var ringing: null
    property var queue: []

    function ring(r) {
        if (root.ringing === null)
            root.ringing = r;
        else
            root.queue = root.queue.concat([r]);
    }

    function nextRing() {
        const q = root.queue.slice();
        root.ringing = q.length > 0 ? q.shift() : null;
        root.queue = q;
    }

    function finishRing() {
        if (root.ringing)
            root.finish(root.ringing.id);
        root.nextRing();
    }

    function snoozeRing(minutes) {
        if (root.ringing)
            root.snooze(root.ringing.id, minutes);
        root.nextRing();
    }

    readonly property var pending: root.items.filter(r => !r.fired && !r.done)

    property double now: Date.now()
    readonly property var soon: {
        let best = null;
        for (const r of root.pending) {
            if (r.at - root.now > 3600000)
                continue;
            if (!best || r.at < best.at)
                best = r;
        }
        return best;
    }

    function dayKey(d) {
        return d.getFullYear() + "-" + (d.getMonth() + 1) + "-" + d.getDate();
    }

    function onDay(date) {
        const k = root.dayKey(date);
        return root.items.filter(r => root.dayKey(new Date(r.at)) === k)
                         .sort((a, b) => a.at - b.at);
    }

    readonly property var perDay: {
        const m = {};
        for (const r of root.items) {
            if (r.done)
                continue;
            const k = root.dayKey(new Date(r.at));
            m[k] = (m[k] || 0) + 1;
        }
        return m;
    }

    function add(text, baseDay) {
        const p = root.parse(text, baseDay);
        if (!p)
            return null;
        const r = { id: root.seq++, title: p.title, at: p.at, done: false, fired: p.at <= Date.now() };
        root.items = root.items.concat([r]).sort((a, b) => a.at - b.at);
        root.persist();
        return r;
    }

    function remove(id) {
        root.items = root.items.filter(r => r.id !== id);
        root.persist();
    }

    function toggle(id) {
        root.items = root.items.map(r => r.id === id ? Object.assign({}, r, { done: !r.done }) : r);
        root.persist();
    }

    function finish(id) {
        root.items = root.items.map(r => r.id === id ? Object.assign({}, r, { done: true, fired: true }) : r);
        root.persist();
    }

    function snooze(id, minutes) {
        const at = Date.now() + minutes * 60000;
        root.items = root.items.map(r => r.id === id
            ? Object.assign({}, r, { at: at, fired: false, done: false }) : r)
            .sort((a, b) => a.at - b.at);
        root.persist();
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.pending.length > 0
        onTriggered: {
            root.now = Date.now();
            root.check(false);
        }
    }

    function check(boot) {
        const now = Date.now();
        let fire = [];
        let changed = false;
        const next = root.items.map(r => {
            if (r.fired || r.done || r.at > now)
                return r;
            changed = true;
            const late = now - r.at;
            if (!boot || late < 12 * 3600000)
                fire.push(r);
            return Object.assign({}, r, { fired: true });
        });
        if (!changed)
            return;
        root.items = next;
        root.persist();
        for (const r of fire) {
            root.ring(r);
            root.due(r);
        }
    }

    readonly property var weekdaysRu: ["воскресень", "понедельник", "вторник", "сред", "четверг", "пятниц", "суббот"]
    readonly property var weekdaysEn: ["sunday", "monday", "tuesday", "wednesday", "thursday", "friday", "saturday"]
    readonly property var monthsRu: ["январ", "феврал", "март", "апрел", "ма", "июн", "июл", "август", "сентябр", "октябр", "ноябр", "декабр"]

    function parse(raw, baseDay) {
        let s = " " + String(raw || "").trim() + " ";
        if (s.trim() === "")
            return null;

        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate());
        let day = baseDay ? new Date(baseDay.getFullYear(), baseDay.getMonth(), baseDay.getDate()) : today;
        let dateSet = false;
        let h = -1, mi = 0;
        let rel = -1;

        const cut = (re) => {
            const m = s.match(re);
            if (m)
                s = s.replace(re, " ");
            return m;
        };

        let m = cut(/\s(?:через|in)\s+(\d+(?:[.,]\d+)?)?\s*(минут[уы]?|мин\.?|м|m|mins?|minutes?|час(?:а|ов)?|ч|h|hours?|hrs?|д(?:ня|ней|ень)|days?|d)(?=\s)/i);
        if (m) {
            const n = m[1] ? parseFloat(m[1].replace(",", ".")) : 1;
            const u = m[2].toLowerCase();
            const unit = /^(м|m|мин)/.test(u) ? 60000 : /^(ч|h|час)/.test(u) ? 3600000 : 86400000;
            rel = n * unit;
        } else if (cut(/\s(?:через\s+полчаса|in\s+half\s+an\s+hour)(?=\s)/i)) {
            rel = 1800000;
        }

        if (cut(/\s(?:послезавтра|day after tomorrow)(?=\s)/i)) {
            day = new Date(today.getTime() + 2 * 86400000); dateSet = true;
        } else if (cut(/\s(?:завтра|tomorrow)(?=\s)/i)) {
            day = new Date(today.getTime() + 86400000); dateSet = true;
        } else if (cut(/\s(?:сегодня|today|tonight)(?=\s)/i)) {
            day = today; dateSet = true;
        }

        if (!dateSet) {
            const wd = s.toLowerCase().match(/\s(?:в|во|on)?\s*(понедельник|вторник|среду|среда|четверг|пятницу|пятница|субботу|суббота|воскресенье|monday|tuesday|wednesday|thursday|friday|saturday|sunday)(?=\s)/i);
            if (wd) {
                const w = wd[1].toLowerCase();
                let idx = root.weekdaysEn.indexOf(w);
                if (idx < 0)
                    idx = root.weekdaysRu.findIndex(p => w.startsWith(p));
                if (idx >= 0) {
                    let add = (idx - today.getDay() + 7) % 7;
                    if (add === 0)
                        add = 7;
                    day = new Date(today.getTime() + add * 86400000);
                    dateSet = true;
                    s = s.replace(new RegExp("\\s(?:в|во|on)?\\s*" + wd[1] + "(?=\\s)", "i"), " ");
                }
            }
        }

        if (!dateSet) {
            const dm = s.match(/\s(\d{1,2})\s+([а-яё]+)(?=\s)/i);
            if (dm) {
                const w = dm[2].toLowerCase();
                const mo = root.monthsRu.findIndex(p => w.startsWith(p) && (p !== "ма" || w === "мая" || w === "май"));
                if (mo >= 0) {
                    day = new Date(today.getFullYear(), mo, parseInt(dm[1]));
                    if (day < today)
                        day = new Date(today.getFullYear() + 1, mo, parseInt(dm[1]));
                    dateSet = true;
                    s = s.replace(dm[0], " ");
                }
            }
        }
        if (!dateSet) {
            m = cut(/\s(\d{1,2})[./](\d{1,2})(?:[./](\d{2,4}))?(?=\s)/);
            if (m && parseInt(m[2]) >= 1 && parseInt(m[2]) <= 12) {
                let y = m[3] ? parseInt(m[3]) : today.getFullYear();
                if (y < 100)
                    y += 2000;
                day = new Date(y, parseInt(m[2]) - 1, parseInt(m[1]));
                if (!m[3] && day < today)
                    day = new Date(y + 1, parseInt(m[2]) - 1, parseInt(m[1]));
                dateSet = true;
            }
        }

        m = cut(/\s(?:в|at|@)?\s*(\d{1,2}):(\d{2})\s*(am|pm)?(?=\s)/i);
        if (m) {
            h = parseInt(m[1]); mi = parseInt(m[2]);
            if (m[3] && m[3].toLowerCase() === "pm" && h < 12) h += 12;
            if (m[3] && m[3].toLowerCase() === "am" && h === 12) h = 0;
        } else {
            m = cut(/\s(?:в|at|@)\s*(\d{1,2})\s*(утра|дня|вечера|ночи|am|pm|ч\.?|часов|часа|час)?(?=\s)/i)
                || cut(/\s(\d{1,2})\s*(am|pm)(?=\s)/i);
            if (m) {
                h = parseInt(m[1]);
                const p = (m[2] || "").toLowerCase();
                if ((p === "вечера" || p === "дня" || p === "pm") && h < 12) h += 12;
                if ((p === "ночи" || p === "am") && h === 12) h = 0;
            }
        }
        if (h > 23 || mi > 59)
            h = -1;

        let at;
        if (rel >= 0) {
            at = now.getTime() + rel;
        } else if (h >= 0) {
            at = new Date(day.getFullYear(), day.getMonth(), day.getDate(), h, mi).getTime();
            if (at <= now.getTime() && !dateSet && day.getTime() === today.getTime())
                at += 86400000;
        } else if (day.getTime() !== today.getTime()) {
            at = new Date(day.getFullYear(), day.getMonth(), day.getDate(), 9, 0).getTime();
        } else {
            const t = now.getTime() + 3600000;
            at = Math.ceil(t / 300000) * 300000;
        }

        let title = s.replace(/\s+/g, " ").trim()
            .replace(/^(?:напомни(?:ть)?(?:\s+мне)?|remind\s+me(?:\s+to)?|нагадай(?:\s+мені)?)\s*/i, "")
            .replace(/^[,.:;\-–—\s]+|[,.:;\-–—\s]+$/g, "");
        if (title === "")
            title = "Напоминание";
        title = title.charAt(0).toUpperCase() + title.slice(1);

        return { at: at, title: title, hasTime: h >= 0 || rel >= 0 };
    }

    function persist() {
        const keep = Date.now() - 7 * 86400000;
        adapter.list = JSON.stringify(root.items.filter(r => !(r.done && r.at < keep)));
        view.writeAdapter();
    }

    function restore() {
        let rows;
        try {
            rows = JSON.parse(adapter.list || "[]");
        } catch (e) {
            return;
        }
        root.items = (rows || []).sort((a, b) => a.at - b.at);
        for (const r of root.items)
            root.seq = Math.max(root.seq, r.id + 1);
        Qt.callLater(() => root.check(true));
    }

    FileView {
        id: view
        path: Quickshell.statePath("reminders.json")
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
        target: "remind"
        function add(text: string): string {
            const r = root.add(text, null);
            return r ? r.title + " @ " + new Date(r.at).toString() : "empty";
        }
        function list(): string {
            return root.items.map(r => r.id + " " + new Date(r.at).toLocaleString() + " " + r.title
                                  + (r.done ? " ✓" : r.fired ? " (fired)" : "")).join("\n");
        }
        function remove(id: int): void { root.remove(id); }
        function done(): void { root.finishRing(); }
        function demo(): void {
            const r = { id: -1, title: "Позвонить маме", at: Date.now(), done: false, fired: true };
            root.ring(r);
            root.due(r);
        }
        function parse(text: string): string {
            const p = root.parse(text, null);
            return p ? p.title + " @ " + new Date(p.at).toString() : "empty";
        }
    }
}
