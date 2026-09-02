pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root

    function of(n) {
        if (!n)
            return "default";

        const app = (n.appName || "").toLowerCase();
        const summary = (n.summary || "").toLowerCase();
        const body = (n.body || "").toLowerCase();

        if (root.shotPath(n) !== "")
            return "screenshot";

        if (app.indexOf("pacman") !== -1 || app.indexOf("paru") !== -1
            || app.indexOf("yay") !== -1
            || summary.indexOf("update") !== -1
            || summary.indexOf("upgrade") !== -1
            || summary.indexOf("package") !== -1
            || summary.indexOf("обновлен") !== -1
            || summary.indexOf("пакет") !== -1)
            return "update";

        if (app.indexOf("weather") !== -1 || app.indexOf("погода") !== -1
            || summary.indexOf("weather") !== -1
            || summary.indexOf("погода") !== -1)
            return "weather";

        if (body.indexOf("%") !== -1
            && (summary.indexOf("batter") !== -1 || summary.indexOf("батаре") !== -1))
            return "default";

        return "default";
    }

    function shotPath(n) {
        if (!n)
            return "";

        const app = (n.appName || "").toLowerCase();
        const shotApp = app.indexOf("grim") !== -1
                     || app.indexOf("shot") !== -1
                     || app.indexOf("screenshot") !== -1
                     || app.indexOf("spectacle") !== -1;

        const candidates = [n.image || "", n.body || "", n.summary || ""];
        for (const c of candidates) {
            const m = c.match(/(\/[^\s"'<>]*\.(?:png|jpe?g|webp))/i);
            if (!m)
                continue;
            let path = m[1];
            const home = path.lastIndexOf("/home/");
            if (home > 0)
                path = path.substring(home);
            return path.replace(/\/{2,}/g, "/");
        }
        return "";
    }
}
