pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/services"

Singleton {
    id: root

    readonly property string scripts: Quickshell.env("HOME") + "/.config/hypr/scripts/"

    property int users: 0

    function acquire() { root.users++; }
    function release() { root.users = Math.max(0, root.users - 1); }

    property int lurkers: 0

    function watch()   { root.lurkers++; }
    function unwatch() { root.lurkers = Math.max(0, root.lurkers - 1); }

    readonly property bool awake: root.users > 0 || root.lurkers > 0

    property bool cups: false
    property var printers: []
    property var jobs: []
    property var capt: ({ needed: false })
    property string selected: ""

    readonly property var current: {
        for (const p of root.printers)
            if (p.name === root.selected)
                return p;
        return null;
    }

    readonly property string health: {
        if (!root.cups)
            return "nocups";
        if (!root.current)
            return "noprinter";
        if (root.capt.needed && !root.capt.device)
            return "offline";
        if (root.capt.needed && (!root.capt.daemon || root.capt.stale))
            return "stale";
        if (root.current.state === "stopped" || !root.current.accepting)
            return "stopped";
        if (root.faulted)
            return "fault";
        if (root.current.state === "printing")
            return "busy";
        if (root.busyCodes.indexOf(root.alert.code) !== -1)
            return "busy";
        if (root.alert.code === "CNSleep")
            return "sleep";
        return "ready";
    }

    readonly property bool ready: root.health === "ready" || root.health === "busy"
                                  || root.health === "stale" || root.health === "sleep"

    Process {
        id: status
        command: [root.scripts + "print-status.sh"]

        stdout: StdioCollector {
            onStreamFinished: {
                let p;
                try {
                    p = JSON.parse(this.text);
                } catch (e) {
                    root.cups = false;
                    return;
                }

                root.cups = p.cups === true;
                root.printers = p.printers || [];
                root.jobs = p.jobs || [];
                root.capt = p.capt || ({ needed: false });

                const known = root.printers.some(x => x.name === root.selected);
                if (!known)
                    root.selected = p.default || (root.printers[0]?.name ?? "");
            }
        }
    }

    property var alert: ({ code: "", text: "" })

    Process {
        id: captProc
        stdout: StdioCollector {
            onStreamFinished: {
                let p;
                try {
                    p = JSON.parse(this.text);
                } catch (e) {
                    root.alert = ({ code: "", text: "" });
                    return;
                }
                root.alert = p.ok
                    ? ({ code: p.code || "", text: p.text || "" })
                    : ({ code: "", text: "" });
            }
        }
    }

    readonly property var faultCodes: [
        "CNJam", "CNJam2", "CNCoverOpen", "CNCoverOpen2", "CNCoverOpen3",
        "CNFuCoverOpen", "CNCassetteOpen", "CNOutputOpen", "CNOutputTrayFull",
        "CNInputMediaSupplyEmpty", "CNInputMediaSupplyEmpty2", "CNCheckPaper",
        "CNChangePaperSize", "CNTonerOut", "CNNoTonerCartridge", "CNNoDrum",
        "CNDrumOut", "CNWasteFull", "CNNoWaste", "CNServiceError",
        "CNFuserError", "CNPrinterCommError", "CNPrinterNotReady",
        "CNNoMemory", "CNMissPrint", "CNTonnerError"
    ]

    readonly property var busyCodes: [
        "CNPrinting", "CNWaitPrinting", "CNWaiting", "CNCleaning",
        "CNCleaningPaper", "CNWaitCleaning", "CNCoolDown", "CNCalibError"
    ]

    readonly property bool faulted:
        root.alert.code !== "" && root.faultCodes.indexOf(root.alert.code) !== -1

    function refresh() {
        if (!root.awake)
            return;
        status.running = true;
        if (root.capt.needed && root.selected !== "") {
            captProc.running = false;
            captProc.command = [root.scripts + "print-capt-status.py", root.selected];
            captProc.running = true;
        }
    }

    onUsersChanged: if (root.users > 0) root.refresh()
    onLurkersChanged: if (root.lurkers > 0) root.refresh()

    Timer {
        running: root.awake
        interval: root.jobs.length > 0 ? 1500
                                       : (root.users > 0 ? 5000 : 20000)
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    property var doc: null
    property bool preparing: false
    property string error: ""

    Process {
        id: prep
        stdout: StdioCollector {
            onStreamFinished: {
                root.preparing = false;
                let p;
                try {
                    p = JSON.parse(this.text);
                } catch (e) {
                    root.error = I18n.t("print.err.prepare");
                    return;
                }
                if (!p.ok) {
                    root.error = p.code
                        ? I18n.t("print.err." + p.code)
                        : (p.error || I18n.t("print.err.prepare"));
                    root.doc = null;
                    return;
                }
                root.error = "";
                root.doc = p;
                root.range = "";
                root.tuneHalftone();
            }
        }
    }

    function prepare(path) {
        root.error = "";
        root.doc = null;
        root.preparing = true;
        prep.running = false;
        prep.command = [root.scripts + "print-prepare.sh", path];
        prep.running = true;
    }

    function drop() {
        root.doc = null;
        root.error = "";
        root.lastJob = "";
    }

    property int copies: 1
    property string range: ""
    property int nup: 1

    readonly property var nupChoices: [
        { value: "1", label: "1" },
        { value: "2", label: "2" },
        { value: "4", label: "4" },
        { value: "6", label: "6" },
        { value: "9", label: "9" }
    ]

    property var caps: ({})
    property var opts: ({})

    Process {
        id: capsProc
        stdout: StdioCollector {
            onStreamFinished: {
                let p;
                try {
                    p = JSON.parse(this.text);
                } catch (e) {
                    root.caps = ({});
                    return;
                }
                root.caps = p.options || ({});

                const next = {};
                for (const id in root.caps)
                    next[id] = root.caps[id].current;
                root.opts = next;

                root.applyQuality(root.quality);
            }
        }
    }

    onSelectedChanged: {
        if (root.selected === "") {
            root.caps = ({});
            root.opts = ({});
            return;
        }
        capsProc.running = false;
        capsProc.command = [root.scripts + "print-caps.sh", root.selected];
        capsProc.running = true;
    }

    function has(id) {
        return root.caps[id] !== undefined;
    }

    function optionOf(id) {
        return root.opts[id] !== undefined
            ? root.opts[id]
            : (root.caps[id] ? root.caps[id].current : "");
    }

    function setOption(id, value) {
        const next = Object.assign({}, root.opts);
        next[id] = value;
        root.opts = next;
    }

    readonly property var knobs: [
        { id: "PageSize",       label: "print.media",     kind: "choice",
          prefer: ["A4", "A5", "Letter", "Legal", "A3"] },
        { id: "MediaType",      label: "print.paperType", kind: "choice",
          prefer: ["PlainPaper", "ThickPaper", "LABELS", "Envelope"] },
        { id: "Duplex",         label: "print.sides",     kind: "choice",
          prefer: ["None", "DuplexNoTumble", "DuplexTumble"] },
        { id: "ColorModel",     label: "print.color",     kind: "choice",
          prefer: ["Gray", "RGB", "CMYK"] },
        { id: "CNHalftone",     label: "print.halftone",  kind: "choice",
          prefer: ["Gradation", "Resolution", "Off"] },
        { id: "CNTonerDensity", label: "print.density",   kind: "slider" },
        { id: "CNDraftMode",    label: "print.tonerSave", kind: "toggle" },
        { id: "CNSkipBlank",    label: "print.skipBlank", kind: "toggle" },
        { id: "CNSuperSmooth",  label: "print.refine",    kind: "toggle" },
        { id: "Collate",        label: "print.collate",   kind: "toggle" },

        { id: "CNSpecialPrintAdjustmentA", label: "print.adjustA", kind: "choice",
          advanced: true, prefer: ["Off", "Mode1", "Mode2", "Mode3", "Mode4"] },
        { id: "CNSpecialPrintAdjustmentB", label: "print.adjustB", kind: "choice",
          advanced: true, prefer: ["Off", "Mode1", "Mode2", "Mode3"] },
        { id: "CNSpecialPrintingModeA", label: "print.modeA", kind: "choice",
          advanced: true, prefer: ["None", "Settings1", "Settings2"] },
        { id: "CNSpecialPrintingModeB", label: "print.modeB", kind: "choice",
          advanced: true, prefer: ["None", "Settings1"] },
        { id: "CNOutputAdjustment",  label: "print.outAdjust",  kind: "toggle", advanced: true },
        { id: "CNDetectPaperSize",   label: "print.detectSize", kind: "toggle", advanced: true },
        { id: "CNRotatePrint",       label: "print.rotate",     kind: "toggle", advanced: true },
        { id: "BindEdge",            label: "print.bindEdge",   kind: "choice",
          advanced: true, prefer: ["Left", "Top"] },
        { id: "InputSlot",           label: "print.source",     kind: "choice",
          advanced: true, prefer: ["Auto", "Cassette", "Manual", "MF"] }
    ]

    readonly property var liveKnobs: {
        const out = [];
        for (const k of root.knobs) {
            const cap = root.caps[k.id];
            if (!cap)
                continue;
            if (k.kind !== "slider" && cap.values.length < 2)
                continue;

            const entry = {
                id: k.id,
                kind: k.kind,
                advanced: k.advanced === true,
                label: I18n.t(k.label),
                values: cap.values
            };

            if (k.kind === "choice") {
                const order = k.prefer || [];
                const kept = order.filter(v => cap.values.indexOf(v) !== -1);
                const list = kept.length > 0 ? kept : cap.values;
                entry.options = list.map(v => ({
                    value: v,
                    label: root.valueLabel(k.id, v)
                }));
            }

            if (k.kind === "slider") {
                const nums = cap.values.map(v => parseInt(v, 10))
                                       .filter(n => isFinite(n));
                if (nums.length < 2)
                    continue;
                entry.min = Math.min.apply(null, nums);
                entry.max = Math.max.apply(null, nums);
            }

            out.push(entry);
        }
        return out;
    }

    readonly property var plainKnobs: root.liveKnobs.filter(k => !k.advanced)
    readonly property var deepKnobs: root.liveKnobs.filter(k => k.advanced)

    function valueLabel(id, value) {
        const key = "print.val." + value;
        const text = I18n.t(key);
        return text === key ? value.toLowerCase() : text;
    }

    function isOn(id) {
        return root.optionOf(id) === "True";
    }

    readonly property var paperSizes: ({
        "A4":     [595.28, 841.89],
        "A5":     [419.53, 595.28],
        "A3":     [841.89, 1190.55],
        "Letter": [612, 792],
        "Legal":  [612, 1008],
        "B5":     [498.90, 708.66],
        "Executive": [521.86, 756]
    })

    readonly property bool needsFit: {
        if (!root.doc)
            return false;
        const size = root.paperSizes[root.optionOf("PageSize")];
        if (!size)
            return false;

        const w = root.doc.wpt || 0;
        const h = root.doc.hpt || 0;
        if (w <= 0 || h <= 0)
            return false;

        const near = (a, b) => Math.abs(a - b) <= 3;
        const fits = (near(w, size[0]) && near(h, size[1]))
                  || (near(w, size[1]) && near(h, size[0]));
        return !fits;
    }

    readonly property var optionPairs: {
        const out = [];
        for (const id in root.opts) {
            const cap = root.caps[id];
            if (!cap || root.opts[id] === cap.current)
                continue;
            out.push(id + "=" + root.opts[id]);
        }
        if (root.nup > 1)
            out.push("number-up=" + root.nup);
        if (root.needsFit)
            out.push("fit-to-page=true");
        return out;
    }

    property string quality: "best"

    readonly property var qualityChoices: [
        { value: "draft",  label: I18n.t("print.q.draft") },
        { value: "normal", label: I18n.t("print.q.normal") },
        { value: "best",   label: I18n.t("print.q.best") }
    ]

    function applyQuality(name) {
        root.quality = name;

        const next = Object.assign({}, root.opts);
        const put = (id, value) => {
            if (root.caps[id] && root.caps[id].values.indexOf(value) !== -1)
                next[id] = value;
        };
        const density = (value) => {
            const cap = root.caps["CNTonerDensity"];
            if (!cap)
                return;
            const nums = cap.values.map(v => parseInt(v, 10)).filter(n => isFinite(n));
            if (nums.length === 0)
                return;
            const lo = Math.min.apply(null, nums);
            const hi = Math.max.apply(null, nums);
            next["CNTonerDensity"] = String(
                Math.max(lo, Math.min(hi, Math.round(lo + (hi - lo) * value))));
        };

        switch (name) {
        case "draft":
            put("CNDraftMode", "True");
            put("CNSuperSmooth", "False");
            density(0.45);
            break;
        case "normal":
            put("CNDraftMode", "False");
            put("CNSuperSmooth", "True");
            density(0.75);
            break;
        default:
            put("CNDraftMode", "False");
            put("CNSuperSmooth", "True");
            density(1.0);
            break;
        }

        root.opts = next;
        root.tuneHalftone();
    }

    function tuneHalftone() {
        if (!root.doc || !root.caps["CNHalftone"])
            return;
        const want = root.doc.kind === "image" ? "Gradation" : "Resolution";
        if (root.caps["CNHalftone"].values.indexOf(want) === -1)
            return;
        root.setOption("CNHalftone", want);
    }

    readonly property bool duplexing: {
        const d = root.optionOf("Duplex");
        return d !== "" && d !== "None";
    }

    readonly property bool rangeValid: {
        const r = root.range.trim();
        if (r === "")
            return true;
        return /^[0-9]+(-[0-9]*)?(,[0-9]+(-[0-9]*)?)*$/.test(r);
    }

    readonly property int sheets: {
        if (!root.doc)
            return 0;
        let pages = root.pagesInRange;
        pages = Math.ceil(pages / Math.max(1, root.nup));
        if (root.duplexing)
            pages = Math.ceil(pages / 2);
        return pages * Math.max(1, root.copies);
    }

    readonly property int pagesInRange: {
        if (!root.doc)
            return 0;
        const total = root.doc.pages || 1;
        const r = root.range.trim();
        if (r === "" || !root.rangeValid)
            return total;

        let n = 0;
        for (const part of r.split(",")) {
            const bits = part.split("-");
            const from = parseInt(bits[0], 10);
            if (!isFinite(from))
                continue;
            if (bits.length === 1) {
                if (from <= total) n += 1;
                continue;
            }
            const to = bits[1] === "" ? total : parseInt(bits[1], 10);
            if (!isFinite(to))
                continue;
            n += Math.max(0, Math.min(total, to) - from + 1);
        }
        return Math.max(0, Math.min(total, n));
    }

    property bool sending: false
    property string lastJob: ""

    signal sent(string id)
    signal failed(string message)

    Process {
        id: sender
        stdout: StdioCollector {
            onStreamFinished: {
                root.sending = false;
                let p;
                try {
                    p = JSON.parse(this.text);
                } catch (e) {
                    root.error = I18n.t("print.err.noAnswer");
                    root.failed(root.error);
                    return;
                }
                if (!p.ok) {
                    root.error = p.code
                        ? I18n.t("print.err." + p.code)
                        : (p.error || I18n.t("print.err.lp"));
                    root.failed(root.error);
                    return;
                }
                root.error = "";
                root.lastJob = p.id || "";
                root.sent(root.lastJob);
                root.refresh();
            }
        }
    }

    function submit() {
        if (!root.doc || root.sending || !root.selected || !root.rangeValid)
            return;

        root.sending = true;
        sender.running = false;
        sender.command = [
            root.scripts + "print-send.sh",
            root.doc.pdf,
            root.selected,
            String(root.copies),
            root.range.trim(),
            root.doc.name
        ].concat(root.optionPairs);
        sender.running = true;
    }

    Process { id: canceller }

    function cancel(id) {
        canceller.running = false;
        canceller.command = ["cancel", id];
        canceller.running = true;
        root.refresh();
    }

    function cancelAll() {
        canceller.running = false;
        canceller.command = ["cancel", "-a", root.selected];
        canceller.running = true;
        root.refresh();
    }

    property bool repairing: false

    Process {
        id: doctorProc
        onExited: {
            root.repairing = false;
            root.refresh();
        }
    }

    function doctor() {
        if (root.repairing)
            return;
        root.repairing = true;
        doctorProc.running = false;
        doctorProc.command = [root.scripts + "print-doctor.sh", "--quiet"];
        doctorProc.running = true;
    }

    function glyphFor(kind) {
        switch (kind) {
        case "pdf":    return "󰈦";
        case "word":   return "󰈬";
        case "slides": return "󰈧";
        case "sheet":  return "󰈛";
        case "image":  return "󰋩";
        case "text":   return "󰈙";
        case "code":   return "󰈮";
        case "web":    return "󰖟";
        case "ps":     return "󰈟";
        case "dir":    return "󰉋";
        default:       return "󰈤";
        }
    }
}
