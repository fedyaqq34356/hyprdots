pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick
import "root:/design"
import "root:/services"

Singleton {
    id: root

    readonly property string place: {
        const env = Quickshell.env("WEATHER_PLACE");
        return env && env !== "" ? env : "";
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

    function refresh() {
        fetch.running = false;
        fetch.running = true;
    }

    Process {
        id: fetch

        command: ["curl", "-sf", "--max-time", "12",
                  "https://wttr.in/" + root.place + "?format=j1"]
        running: true

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
                    root.save();
                } catch (e) {
                    root.error = I18n.t("weather.badParse");
                }
            }
        }
    }

    Timer {
        interval: 20 * 60 * 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    function save() {
        cache.temp = root.temp;
        cache.code = root.code;
        cache.text = root.text;
        cache.city = root.city;
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
        }
    }
}
