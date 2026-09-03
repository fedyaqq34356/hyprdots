pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    property var items: []
    property int seq: 1

    property double now: Date.now()

    readonly property int running: root.items.filter(t => t.running).length
    readonly property bool anyRunning: root.running > 0
    readonly property bool anyRinging: root.items.some(t => t.ringing)

    readonly property var soonest: {
        let best = null;
        for (const t of root.items) {
            if (t.ringing)
                return t;
            if (!t.running)
                continue;
            if (!best || t.endsAt < best.endsAt)
                best = t;
        }
        return best || (root.items.length > 0 ? root.items[0] : null);
    }

    function left(t) {
        if (!t)
            return 0;
        if (!t.running)
            return t.left;
        return Math.max(0, Math.ceil((t.endsAt - root.now) / 1000));
    }

    function progress(t) {
        if (!t || t.total <= 0)
            return 0;
        return Math.max(0, Math.min(1, root.left(t) / t.total));
    }

    function find(id) {
        return root.items.find(t => t.id === id) || null;
    }

    function clock(seconds) {
        const s = Math.max(0, Math.round(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;
        const pad = (n) => String(n).padStart(2, "0");
        return h > 0 ? h + ":" + pad(m) + ":" + pad(sec)
                     : pad(m) + ":" + pad(sec);
    }

    function human(seconds) {
        const s = Math.max(0, Math.round(seconds));
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        const sec = s % 60;
        let out = "";
        if (h > 0) out += h + "h";
        if (m > 0) out += m + "m";
        if (sec > 0 || out === "") out += sec + "s";
        return out;
    }

    function start(seconds, label) {
        const total = Math.max(1, Math.round(seconds));
        const t = {
            id: root.seq++,
            label: label || "",
            total: total,
            endsAt: Date.now() + total * 1000,
            left: total,
            running: true,
            ringing: false,
            muted: false,
            lastSec: total,
            halfDone: false,
            handle: -1
        };
        const next = root.items.slice();
        next.push(t);
        root.items = next;
        root.persist();
        return t.id;
    }

    function pause(id) {
        const t = root.find(id);
        if (!t || !t.running)
            return;
        t.left = root.left(t);
        t.running = false;
        root.commit(true);
    }

    function resume(id) {
        const t = root.find(id);
        if (!t || t.running || t.ringing)
            return;
        t.endsAt = Date.now() + Math.max(1, t.left) * 1000;
        t.lastSec = t.left;
        t.running = true;
        root.commit(true);
    }

    function toggle(id) {
        const t = root.find(id);
        if (!t)
            return;
        if (t.ringing)
            root.dismiss(id);
        else if (t.running)
            root.pause(id);
        else
            root.resume(id);
    }

    function nudge(id, seconds) {
        const t = root.find(id);
        if (!t)
            return;
        if (t.ringing) {
            root.silence(t);
            t.ringing = false;
            t.left = 0;
        }
        const rest = Math.max(0, root.left(t) + seconds);
        if (rest <= 0) {
            root.cancel(id);
            return;
        }
        t.total = Math.max(t.total + seconds, rest);
        t.left = rest;
        t.lastSec = rest;
        t.halfDone = t.halfDone && rest < t.total / 2;
        if (t.running)
            t.endsAt = Date.now() + rest * 1000;
        root.commit(true);
    }

    function restart(id) {
        const t = root.find(id);
        if (!t)
            return;
        root.silence(t);
        t.ringing = false;
        t.left = t.total;
        t.lastSec = t.total;
        t.halfDone = false;
        t.endsAt = Date.now() + t.total * 1000;
        t.running = true;
        root.commit(true);
    }

    function cancel(id) {
        const t = root.find(id);
        if (t)
            root.silence(t);
        root.items = root.items.filter(x => x.id !== id);
        root.persist();
    }

    function clearFinished() {
        for (const t of root.items)
            if (t.ringing)
                root.silence(t);
        root.items = root.items.filter(t => t.running || (!t.ringing && t.left > 0));
        root.persist();
    }

    function dismiss(id) {
        const t = root.find(id);
        if (!t)
            return;
        root.silence(t);
        root.cancel(id);
    }

    function dismissAll() {
        for (const t of root.items.slice())
            if (t.ringing)
                root.dismiss(t.id);
    }

    function snooze(id, seconds) {
        const t = root.find(id);
        if (!t)
            return;
        root.silence(t);
        const extra = Math.max(1, Math.round(seconds || Prefs.timerSnoozeSec));
        t.ringing = false;
        t.total = extra;
        t.left = extra;
        t.lastSec = extra;
        t.halfDone = false;
        t.endsAt = Date.now() + extra * 1000;
        t.running = true;
        root.commit(true);
    }

    Timer {
        running: root.anyRunning || root.stopwatchRunning || root.anyRinging
        interval: 250
        repeat: true
        onTriggered: root.pulse()
    }

    function pulse() {
        root.now = Date.now();

        let changed = false;
        let structural = false;
        for (const t of root.items) {
            if (t.ringing) {
                if (Prefs.timerRingSec > 0
                    && root.now - t.rangAt > Prefs.timerRingSec * 1000) {
                    root.silence(t);
                    root.items = root.items.filter(x => x.id !== t.id);
                    root.persist();
                    return;
                }
                continue;
            }
            if (!t.running)
                continue;

            const rest = Math.ceil((t.endsAt - root.now) / 1000);
            if (rest === t.lastSec)
                continue;
            t.lastSec = rest;
            changed = true;

            if (rest <= 0) {
                root.fire(t);
                structural = true;
                continue;
            }

            if (Prefs.timerTicking && rest <= Prefs.timerTickSec)
                Sfx.timerTick();

            if (Prefs.timerHalfway && !t.halfDone && rest <= t.total / 2) {
                t.halfDone = true;
                Sfx.timerHalf();
            }
        }

        if (changed || structural)
            root.commit(structural);
    }

    function fire(t) {
        t.running = false;
        t.ringing = true;
        t.left = 0;
        t.rangAt = Date.now();

        const sound = Prefs.timerSound;
        if (sound !== "none" && !t.muted) {
            if (Prefs.timerLoop)
                t.handle = Sfx.timerAlarmLoop(sound);
            else
                Sfx.timerAlarm(sound);
        }

        if (Prefs.timerNotify) {
            const name = t.label !== "" ? t.label : I18n.t("timer.title");
            Quickshell.execDetached([
                "notify-send", "-u", "critical", "-a", "quickshell",
                name, I18n.t("timer.done") + " · " + root.human(t.total)
            ]);
        }

        if (Prefs.timerCommand !== "")
            Quickshell.execDetached(["sh", "-c", Prefs.timerCommand]);
    }

    function silence(t) {
        if (!t || t.handle === undefined || t.handle < 0)
            return;
        Sfx.stop(t.handle);
        t.handle = -1;
    }

    function hush() {
        for (const t of root.items)
            if (t.ringing)
                root.silence(t);
        root.commit(false);
    }

    property bool stopwatchRunning: false
    property double stopwatchFrom: 0
    property double stopwatchAccum: 0
    property var laps: []

    readonly property double stopwatchMs:
        root.stopwatchAccum + (root.stopwatchRunning
                               ? root.now - root.stopwatchFrom : 0)

    function stopwatchToggle() {
        if (root.stopwatchRunning) {
            root.stopwatchAccum += Date.now() - root.stopwatchFrom;
            root.stopwatchRunning = false;
        } else {
            root.stopwatchFrom = Date.now();
            root.now = root.stopwatchFrom;
            root.stopwatchRunning = true;
        }
    }

    function stopwatchReset() {
        root.stopwatchRunning = false;
        root.stopwatchAccum = 0;
        root.laps = [];
    }

    function lap() {
        const at = root.stopwatchMs;
        const prev = root.laps.length > 0 ? root.laps[0].at : 0;
        const next = root.laps.slice();
        next.unshift({ index: root.laps.length + 1, at: at, split: at - prev });
        root.laps = next;
    }

    function stopwatchText(ms) {
        const total = Math.max(0, Math.floor(ms));
        const h = Math.floor(total / 3600000);
        const m = Math.floor((total % 3600000) / 60000);
        const s = Math.floor((total % 60000) / 1000);
        const cs = Math.floor((total % 1000) / 10);
        const pad = (n) => String(n).padStart(2, "0");
        return (h > 0 ? h + ":" : "") + pad(m) + ":" + pad(s) + "." + pad(cs);
    }

    readonly property var presets: {
        const out = [];
        for (const part of String(adapter.presets).split(",")) {
            const n = parseInt(part, 10);
            if (!isNaN(n) && n > 0)
                out.push(n);
        }
        return out;
    }

    function savePresets(list) {
        const sorted = list.slice().sort((a, b) => a - b);
        adapter.presets = sorted.join(",");
        view.writeAdapter();
    }

    function addPreset(seconds) {
        const s = Math.round(seconds);
        if (s <= 0 || root.presets.indexOf(s) >= 0)
            return false;
        root.savePresets(root.presets.concat([s]));
        return true;
    }

    function removePreset(seconds) {
        root.savePresets(root.presets.filter(x => x !== seconds));
    }

    function commit(structural) {
        root.items = root.items.map(t => Object.assign({}, t));
        if (structural)
            root.persist();
    }

    function persist() {
        const rows = root.items.filter(t => !t.ringing).map(t => ({
            id: t.id,
            label: t.label,
            total: t.total,
            endsAt: t.endsAt,
            left: root.left(t),
            running: t.running
        }));
        adapter.live = JSON.stringify(rows);
        view.writeAdapter();
    }

    function restore() {
        let rows;
        try {
            rows = JSON.parse(adapter.live || "[]");
        } catch (e) {
            return;
        }
        if (!rows || rows.length === 0)
            return;

        const now = Date.now();
        const out = [];
        for (const r of rows) {
            const rest = r.running
                ? Math.ceil((r.endsAt - now) / 1000)
                : r.left;
            if (rest <= 0)
                continue;
            out.push({
                id: r.id, label: r.label || "", total: r.total,
                endsAt: r.running ? r.endsAt : now + rest * 1000,
                left: rest, running: !!r.running, ringing: false,
                muted: false, lastSec: rest,
                halfDone: rest < r.total / 2, handle: -1
            });
            root.seq = Math.max(root.seq, r.id + 1);
        }
        root.items = out;
    }

    FileView {
        id: view

        path: Quickshell.statePath("timers.json")
        watchChanges: false
        onLoaded: root.restore()
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                view.writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property string presets: "60,300,600,900,1500,3600"
            property string live: "[]"
        }
    }
}
