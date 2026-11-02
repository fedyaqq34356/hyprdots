pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    property var lines: []
    property bool wordSynced: false
    property int index: -1
    property int word: -1
    property string key: ""

    readonly property bool has: root.lines.length > 0
    readonly property var line: root.index >= 0 && root.index < root.lines.length
        ? root.lines[root.index] : null
    readonly property string current: root.line ? root.line.text : ""

    readonly property var wordAt: root.line && root.word >= 0 && root.word < root.line.words.length
        ? root.line.words[root.word] : null
    readonly property real wordStart: root.wordAt ? root.wordAt.t : 0
    readonly property real wordLength: root.wordAt ? Math.max(0.05, root.wordAt.e - root.wordAt.t) : 0

    property int watchers: 0
    readonly property bool running: root.watchers > 0 && Media.playing && root.has && !Stage.gaming

    property real basePos: 0
    property double baseAt: 0
    property real pendingJump: -1

    function now() {
        return Media.playing ? root.basePos + (Date.now() - root.baseAt) / 1000 : root.basePos;
    }

    function sync() {
        if (!Media.has)
            return;
        const raw = Media.player.position;
        if (!isFinite(raw) || raw < 0)
            return;
        const drift = raw - root.now();
        if (Math.abs(drift) > 1.2 && root.baseAt > 0) {
            if (root.pendingJump < 0 || Math.abs(raw - root.pendingJump) > 1.2) {
                root.pendingJump = raw;
                return;
            }
        }
        root.pendingJump = -1;
        root.basePos = raw;
        root.baseAt = Date.now();
        root.step();
    }

    function step() {
        const p = root.now();
        const ls = root.lines;
        let i = -1;
        for (let n = 0; n < ls.length; n++) {
            if (ls[n].t <= p + 0.08) i = n;
            else break;
        }

        let next = i + 1 < ls.length ? ls[i + 1].t : Infinity;

        if (i >= 0 && p > ls[i].end) {
            if (next - ls[i].end > 2.5)
                i = -1;
        }

        let w = -1;
        if (i >= 0) {
            const words = ls[i].words;
            for (let n = 0; n < words.length; n++) {
                if (words[n].t <= p + 0.04) w = n;
                if (words[n].t > p + 0.04) { next = Math.min(next, words[n].t); break; }
            }
            if (p <= ls[i].end)
                next = Math.min(next, ls[i].end + 0.01);
        } else if (ls.length > 0) {
            for (let n = 0; n < ls.length; n++)
                if (ls[n].t > p) { next = Math.min(next, ls[n].t); break; }
        }

        if (i !== root.index) {
            root.word = -1;
            root.index = i;
        }
        root.word = w;

        if (root.running && isFinite(next)) {
            alarm.interval = Math.max(16, Math.round((next - p) * 1000));
            alarm.restart();
        } else {
            alarm.stop();
        }
    }

    Timer {
        id: alarm
        repeat: false
        onTriggered: root.step()
    }

    Timer {
        interval: 500
        repeat: true
        running: root.running
        triggeredOnStart: true
        onTriggered: root.sync()
    }

    onRunningChanged: {
        root.baseAt = 0;
        if (root.running)
            root.sync();
        else
            alarm.stop();
    }

    function credit(text) {
        return /^\s*[^\s:：]{1,24}\s*[:：]/.test(text)
            && (/[㐀-鿿]/.test(text) || /^(producer|composer|lyricist|written|mixed|mastered)/i.test(text));
    }

    function spread(text, t, nextT) {
        const parts = text.split(/\s+/).filter(s => s !== "");
        const span = Math.min(5, Math.max(0.6, ((isFinite(nextT) ? nextT : t + 4) - t) * 0.8));
        const total = parts.reduce((a, s) => a + s.length + 1, 0);
        const words = [];
        let at = t;
        for (const s of parts) {
            const d = span * (s.length + 1) / total;
            words.push({ t: at, e: at + d, text: s });
            at += d;
        }
        return words;
    }

    function finish(list) {
        list = list.filter(l => l.text !== "" && !root.credit(l.text));
        list.sort((a, b) => a.t - b.t);
        for (let n = 0; n < list.length; n++) {
            const l = list[n];
            const nextT = n + 1 < list.length ? list[n + 1].t : Infinity;
            if (!l.words || l.words.length === 0)
                l.words = root.spread(l.text, l.t, nextT);
            const last = l.words[l.words.length - 1];
            l.end = Math.min(isFinite(nextT) ? nextT : Infinity, last.e + 0.6);
        }
        return list;
    }

    function parseYrc(text) {
        const out = [];
        for (const raw of text.split("\n")) {
            const head = raw.match(/^\[(\d+),(\d+)\]/);
            if (!head)
                continue;
            const words = [];
            const re = /\((\d+),(\d+),\d+\)([^(]*)/g;
            let m;
            while ((m = re.exec(raw)) !== null) {
                const s = m[3];
                if (s.trim() === "") continue;
                const t = parseInt(m[1]) / 1000;
                words.push({ t: t, e: t + parseInt(m[2]) / 1000, text: s.trim() });
            }
            const text2 = words.map(w => w.text).join(" ");
            out.push({ t: parseInt(head[1]) / 1000, text: text2, words: words });
        }
        return root.finish(out);
    }

    function parseLrc(text) {
        const stamp = (m, s) => parseInt(m) * 60 + parseFloat(s);
        const out = [];
        for (const raw of text.split("\n")) {
            const m = raw.match(/^\[(\d+):(\d+(?:\.\d+)?)\]\s*(.*)$/);
            if (!m)
                continue;
            const body = m[3];
            let words = [];
            if (/<\d+:\d+(?:\.\d+)?>/.test(body)) {
                const re = /<(\d+):(\d+(?:\.\d+)?)>\s*([^<]*)/g;
                let w;
                while ((w = re.exec(body)) !== null) {
                    if (w[3].trim() === "") continue;
                    words.push({ t: stamp(w[1], w[2]), e: 0, text: w[3].trim() });
                }
                for (let n = 0; n < words.length; n++)
                    words[n].e = n + 1 < words.length ? words[n + 1].t : words[n].t + 0.6;
            }
            const plain = body.replace(/<\d+:\d+(?:\.\d+)?>/g, "").replace(/\s+/g, " ").trim();
            out.push({ t: stamp(m[1], m[2]), text: plain, words: words });
        }
        return root.finish(out);
    }

    function clean(s) {
        return s.replace(/\s*[\(\[][^\)\]]*(feat|ft\.|from|remaster|version|edit|live)[^\)\]]*[\)\]]/gi, "")
                .replace(/\s+-\s+.*(remaster|version|edit).*$/i, "")
                .trim();
    }

    function norm(s) {
        return root.clean(s).toLowerCase().replace(/[\s\-_'’.,!?&()\[\]"«»:;\/]+/g, "");
    }

    function get(url, headers, done) {
        const xhr = new XMLHttpRequest();
        xhr.onreadystatechange = () => {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            let data = null;
            if (xhr.status === 200) {
                try { data = JSON.parse(xhr.responseText); } catch (e) { data = null; }
            }
            done(data);
        };
        xhr.open("GET", url);
        for (const h in headers)
            xhr.setRequestHeader(h, headers[h]);
        xhr.send();
    }

    readonly property var netease: ({ "Referer": "https://music.163.com" })

    function fetch() {
        const artist = Media.artist.split(",")[0].trim();
        const title = root.clean(Media.title);
        const k = artist + "\u0001" + title;
        if (k === root.key)
            return;
        root.key = k;
        root.lines = [];
        root.wordSynced = false;
        root.index = -1;
        root.word = -1;
        alarm.stop();
        if (artist === "" || title === "")
            return;

        const hit = cache.map[k];
        if (hit !== undefined) {
            root.apply(k, hit.lines, hit.word, false);
            return;
        }

        const len = Media.hasPosition ? Media.player.length : 0;
        const s = { key: k, ease: null, easeDone: false, lrc: null, lrcDone: false };
        const settle = () => {
            if (s.key !== root.key)
                return;
            const easeWords = s.ease && s.ease.word;
            const lrcWords = s.lrc && s.lrc.word;
            if (easeWords) return root.apply(k, s.ease.lines, true, true);
            if (lrcWords && s.easeDone) return root.apply(k, s.lrc.lines, true, true);
            if (!s.easeDone || !s.lrcDone) return;
            const best = s.lrc || s.ease;
            root.apply(k, best ? best.lines : [], false, true);
        };

        root.get("https://music.163.com/api/cloudsearch/pc?type=1&limit=8&s="
                 + encodeURIComponent(artist + " " + title), root.netease, (d) => {
            const songs = d && d.result && d.result.songs ? d.result.songs : [];
            const want = root.norm(title);
            const who = root.norm(artist);
            let pick = null;
            for (const so of songs) {
                const name = root.norm(so.name);
                const byName = name === want || name.indexOf(want) === 0 || want.indexOf(name) === 0;
                const byArtist = (so.ar || []).some(a => root.norm(a.name) === who);
                const byLen = len <= 0 || Math.abs(so.dt / 1000 - len) < 4;
                if (byName && byArtist && byLen) { pick = so; break; }
            }
            if (!pick) { s.easeDone = true; settle(); return; }
            root.get("https://music.163.com/api/song/lyric/v1?lv=1&kv=1&tv=-1&yv=1&rv=1&id="
                     + pick.id, root.netease, (ly) => {
                const yrc = ly && ly.yrc && ly.yrc.lyric ? root.parseYrc(ly.yrc.lyric) : [];
                const lrc = ly && ly.lrc && ly.lrc.lyric ? root.parseLrc(ly.lrc.lyric) : [];
                if (yrc.length > 0) s.ease = { lines: yrc, word: true };
                else if (lrc.length > 0) s.ease = { lines: lrc, word: false };
                s.easeDone = true;
                settle();
            });
        });

        const takeLrc = (text) => {
            const ls = root.parseLrc(text);
            const word = /<\d+:\d+/.test(text);
            s.lrc = ls.length > 0 ? { lines: ls, word: word } : null;
            s.lrcDone = true;
            settle();
        };
        root.get("https://lrclib.net/api/get?artist_name=" + encodeURIComponent(artist)
                 + "&track_name=" + encodeURIComponent(title)
                 + (len > 0 ? "&duration=" + Math.round(len) : ""), {}, (d) => {
            if (d && d.syncedLyrics) { takeLrc(d.syncedLyrics); return; }
            root.get("https://lrclib.net/api/search?q=" + encodeURIComponent(artist + " " + title), {}, (list) => {
                for (const x of (list || []))
                    if (x.syncedLyrics) { takeLrc(x.syncedLyrics); return; }
                s.lrcDone = true;
                settle();
            });
        });
    }

    function apply(k, lines, word, store) {
        if (k !== root.key)
            return;
        root.lines = lines;
        root.wordSynced = word;
        if (store)
            cache.put(k, lines, word);
        root.baseAt = 0;
        root.sync();
    }

    Connections {
        target: Media
        function onTitleChanged() { root.fetch(); }
        function onArtistChanged() { root.fetch(); }
        function onPlayingChanged() { root.baseAt = 0; root.sync(); }
    }

    QtObject {
        id: cache

        property var map: ({})
        property var order: []

        function put(k, lines, word) {
            map[k] = { lines: lines, word: word };
            order = order.filter(x => x !== k).concat([k]);
            while (order.length > 300)
                delete map[order.shift()];
            saver.restart();
        }
    }

    Timer {
        id: saver
        interval: 2000
        onTriggered: file.setText(JSON.stringify({ order: cache.order, map: cache.map }))
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.cache/f-lyrics.json"
        blockLoading: true
        onLoaded: {
            try {
                const d = JSON.parse(file.text());
                cache.map = d.map || {};
                cache.order = d.order || [];
            } catch (e) {}
        }
    }

    Component.onCompleted: fetch()
}
