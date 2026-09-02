pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property var freqs: [32, 64, 125, 250, 500, 1000, 2000, 4000, 8000, 16000]
    readonly property var labels: ["32", "64", "125", "250", "500", "1k", "2k", "4k", "8k", "16k"]
    readonly property int bands: root.freqs.length
    readonly property real range: 12

    property var gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
    property string preset: "flat"

    property int nodeId: -1
    readonly property bool available: root.nodeId >= 0

    readonly property var presets: ({
        "flat":    [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        "bass":    [6, 5, 4, 2, 0, 0, 0, 0, 1, 2],
        "treble":  [-2, -1, 0, 0, 0, 1, 3, 4, 5, 5],
        "vocal":   [-3, -2, -1, -3, 1, 3, 4, 3, 1, 0],
        "pop":     [-1, 1, 2, 3, 1, -1, -1, 1, 2, 3],
        "rock":    [4, 3, 1, -1, -2, 0, 2, 3, 4, 4],
        "jazz":    [3, 2, 1, 2, -1, -1, 0, 1, 2, 3],
        "classic": [4, 3, 2, 0, -1, -1, 0, 2, 3, 4],
        "night":   [-4, -3, -1, 0, 1, 2, 1, -1, -3, -5]
    })

    readonly property var presetNames: Object.keys(root.presets)

    function setGain(index, value) {
        const next = root.gains.slice();
        next[index] = Math.max(-root.range, Math.min(root.range, value));
        root.gains = next;
        root.preset = root.match(next);
        root.push();
        saveTimer.restart();
    }

    function apply(name) {
        const p = root.presets[name];
        if (!p)
            return;
        root.gains = p.slice();
        root.preset = name;
        root.push();
        saveTimer.restart();
    }

    function match(gains) {
        for (const name in root.presets) {
            const p = root.presets[name];
            let same = true;
            for (let i = 0; i < root.bands; i++) {
                if (Math.abs(p[i] - gains[i]) > 0.01) {
                    same = false;
                    break;
                }
            }
            if (same)
                return name;
        }
        return "custom";
    }

    function responseAt(hz) {
        let db = 0;
        for (let i = 0; i < root.bands; i++) {
            const octaves = Math.log(hz / root.freqs[i]) / Math.LN2;
            db += root.gains[i] * Math.exp(-(octaves * octaves) / 0.72);
        }
        return db;
    }

    function push() {
        if (!root.available)
            return;
        const parts = [];
        for (let i = 0; i < root.bands; i++)
            parts.push('"eq_band_' + (i + 1) + ':Gain" ' + root.gains[i].toFixed(2));
        setter.command = ["pw-cli", "s", String(root.nodeId), "Props",
                          "{ params = [ " + parts.join(" ") + " ] }"];
        setter.running = false;
        setter.running = true;
    }

    Process { id: setter }

    Process {
        id: finder
        running: true
        command: ["sh", "-c",
                  "pw-cli ls Node 2>/dev/null | grep -B12 'shell_eq_input' "
                  + "| grep -m1 '^\\s*id ' | tr -dc '0-9'"]
        stdout: StdioCollector {
            onStreamFinished: {
                const id = parseInt(text.trim());
                root.nodeId = isNaN(id) ? -1 : id;
                if (root.available)
                    root.push();
            }
        }
    }

    function rescan() {
        finder.running = false;
        finder.running = true;
    }

    Timer {
        id: saveTimer
        interval: 600
        onTriggered: root.save()
    }

    function save() {
        store.gains = root.gains;
        store.preset = root.preset;
        file.writeAdapter();
    }

    FileView {
        id: file
        path: Quickshell.statePath("equalizer.json")

        onLoaded: {
            const list = [];
            for (let i = 0; i < root.bands; i++)
                list.push(i < store.gains.length ? store.gains[i] : 0);
            root.gains = list;
            root.preset = store.preset === "" ? root.match(list) : store.preset;
            root.push();
        }

        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                root.save();
        }

        JsonAdapter {
            id: store
            property var gains: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
            property string preset: "flat"
        }
    }
}
