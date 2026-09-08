pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/design"
import "root:/services"

Singleton {
    id: root

    readonly property bool enabled: Prefs.weatherEnabled

    readonly property int every:
        Math.max(5, Prefs.weatherEveryMin) * 60 * 1000

    property int watchers: 0

    function hold()    { root.watchers++; }
    function release() { root.watchers = Math.max(0, root.watchers - 1); }

    readonly property bool wanted: root.enabled && root.watchers > 0

    property real fetchedAt: 0

    function fresh() {
        return root.fetchedAt > 0 && (Date.now() - root.fetchedAt) < root.every;
    }

    onWantedChanged: if (root.wanted) root.refresh(false)

    readonly property string place: {
        const env = Quickshell.env("WEATHER_PLACE");
        if (env && env !== "")
            return encodeURIComponent(env);
        return Prefs.weatherPlace !== "" ? encodeURIComponent(Prefs.weatherPlace) : "";
    }

    onPlaceChanged: if (root.wanted) refetch.restart()

    Timer {
        id: refetch
        interval: 400
        onTriggered: root.refresh(true)
    }

    property real temp: 0
    property real feels: 0
    property int humidity: 0
    property real wind: 0
    property string text: ""
    property string city: ""
    property int code: 113
    property bool day: true
    property var forecast: []
    property bool ready: false
    property string error: ""

    function glyphFor(code, daylight) {
        const c = code;
        if (c === 113) return daylight ? "󰖙" : "󰖔";
        if (c === 116 || c === 119) return daylight ? "󰖕" : "󰼱";
        if (c === 122 || c === 143) return "󰖐";
        if (c >= 176 && c <= 293) return "󰖗";
        if (c >= 296 && c <= 314) return "󰖖";
        if (c >= 317 && c <= 377) return "󰖘";
        if (c >= 386 && c <= 395) return "󰙾";
        if (c === 248 || c === 260) return "󰖑";
        return "󰖐";
    }

    readonly property string glyph: {
        const c = root.code;
        if (c === 113) return root.day ? "󰖙" : "󰖔";
        if (c === 116 || c === 119) return root.day ? "󰖕" : "󰼱";
        if (c === 122 || c === 143) return "󰖐";
        if (c >= 176 && c <= 293) return "󰖗";
        if (c >= 296 && c <= 314) return "󰖖";
        if (c >= 317 && c <= 377) return "󰖘";
        if (c >= 386 && c <= 395) return "󰙾";
        if (c === 248 || c === 260) return "󰖑";
        return "󰖐";
    }

    readonly property color tint: {
        const c = root.code;
        if (!root.day) return Colors.accentAlt;
        if (c === 113) return Colors.warn;
        if (c >= 386) return Colors.bad;
        if (c >= 176) return Colors.accentAlt;
        return Colors.fgDim;
    }

    function refresh(force) {
        if (!root.enabled)
            return;
        if (!force && root.fresh())
            return;
        fetch.running = false;
        fetch.running = true;
    }

    Process {
        id: fetch

        command: ["curl", "-sf", "--max-time", "12",
                  "https://wttr.in/" + root.place + "?format=j1"]

        stdout: StdioCollector {
            onStreamFinished: {
                if (text.trim() === "") {
                    root.error = I18n.t("weather.noAnswer");
                    return;
                }
                try {
                    const j = JSON.parse(text);
                    const cur = j.current_condition[0];
                    const area = j.nearest_area && j.nearest_area[0];

                    root.temp = Number(cur.temp_C);
                    root.feels = Number(cur.FeelsLikeC);
                    root.humidity = Number(cur.humidity);
                    root.wind = Number(cur.windspeedKmph);
                    root.code = Number(cur.weatherCode);
                    root.text = cur.weatherDesc && cur.weatherDesc[0]
                        ? cur.weatherDesc[0].value : "";
                    root.city = area && area.areaName && area.areaName[0]
                        ? area.areaName[0].value : "";

                    const hour = new Date().getHours();
                    root.day = hour >= 6 && hour < 21;

                    const days = [];
                    for (const d of j.weather.slice(0, 3)) {
                        days.push({
                            date: d.date,
                            min: Number(d.mintempC),
                            max: Number(d.maxtempC),
                            code: Number(d.hourly[4].weatherCode)
                        });
                    }
                    root.forecast = days;

                    root.error = "";
                    root.ready = true;
                    root.fetchedAt = Date.now();
                    root.save();
                } catch (e) {
                    root.error = I18n.t("weather.badParse");
                }
            }
        }
    }

    Timer {
        interval: root.every
        running: root.wanted
        repeat: true
        onTriggered: root.refresh(true)
    }

    function save() {
        cache.temp = root.temp;
        cache.code = root.code;
        cache.text = root.text;
        cache.city = root.city;
        cache.fetchedAt = root.fetchedAt;
        store.writeAdapter();
    }

    FileView {
        id: store
        path: Quickshell.statePath("weather.json")
        onLoaded: {
            if (root.ready || cache.text === "")
                return;
            root.temp = cache.temp;
            root.code = cache.code;
            root.text = cache.text;
            root.city = cache.city;
            root.fetchedAt = cache.fetchedAt;
            root.ready = true;
        }
        onLoadFailed: (error) => {
            if (error === FileViewError.FileNotFound)
                store.writeAdapter();
        }

        JsonAdapter {
            id: cache
            property real temp: 0
            property int code: 113
            property string text: ""
            property string city: ""
            property real fetchedAt: 0
        }
    }
}
