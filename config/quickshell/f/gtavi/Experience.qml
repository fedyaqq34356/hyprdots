import Quickshell
import Quickshell.Io
import QtQuick

FocusScope {
    id: sc

    property var ctl
    property int session: 0

    anchors.fill: parent
    focus: true

    component Group: Item {
        id: grp
        property real p: 0
        property int count: 2
        property int value: 0
        readonly property string text: String(value).padStart(count, "0")
        width: count * digits.cellBig
        height: bigMetrics.height

        Item {
            id: win
            y: digits.capTop
            width: parent.width
            height: digits.capH
            clip: true

        Row {
            y: -win.y + (1 - grp.p) * win.height * 1.1
            opacity: Math.min(1, grp.p * 1.6)
            Repeater {
                model: grp.count
                DigitCell {
                    required property int index
                    value: grp.text[index] ?? "0"
                    family: "Barlow Condensed"
                    weight: Font.ExtraBold
                    pixelSize: digits.big
                    cellWidth: digits.cellBig
                    color: sc.cream
                }
            }
        }
        }
    }

    component Colon: Item {
        id: col
        property real p: 0
        width: digits.colonW
        height: bigMetrics.height
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            y: -(0.70 * digits.big - bigMetrics.xHeight) / 2
            text: ":"
            color: sc.pink
            opacity: 0.75 * col.p
            font.family: "Barlow Condensed"
            font.weight: Font.Bold
            font.pixelSize: digits.big
        }
    }

    property string stage: "intro"
    property real remainingMs: 0
    property string displayText: ""
    readonly property string mediaState: video.item ? video.item.state_
                                       : (video.status === Loader.Error ? "unavailable" : "none")
    property bool leaving: false
    property bool introFailed: false
    property string introNote: ""

    readonly property real sp: Math.max(0.05, GtaConfig.speed)
    readonly property real u: Math.max(0.45, Math.min(height / 1080, width / 1500))
    readonly property real fs: Math.max(width / 1920, height / 1080)
    readonly property real fw: 1920 * fs
    readonly property real fh: 1080 * fs
    readonly property real fx: (width - fw) / 2
    readonly property real fy: (height - fh) / 2
    readonly property real pivotX: fx + GtaConfig.logoPivotX * fw
    readonly property real pivotY: fy + GtaConfig.logoPivotY * fh

    readonly property var easeOut: [0.32, 0.72, 0, 1, 1, 1]
    readonly property var easeInOut: [0.645, 0.045, 0.355, 1, 1, 1]
    readonly property var easeQuad: [0.455, 0.03, 0.515, 0.955, 1, 1]
    readonly property var easeIn: [0.55, 0.085, 0.68, 0.53, 1, 1]

    readonly property color cream: "#fff9cb"
    readonly property color lilac: "#e5ddff"
    readonly property color blush: "#ffb2c6"
    readonly property color pink: "#f976b0"
    readonly property color slate: "#1f1d29"
    readonly property color navyDeep: "#0b0a15"

    property real enterP: 0
    property real camera: 1.10
    property real videoOpacity: 1
    property real logoOpacity: 0
    property real logoK: GtaConfig.videoLogoScale
    property real logoLift: 0
    property real floatY: 0
    property real gradeP: 0
    property real glowP: 0
    property real glowBreath: 1
    property real eyebrowP: 0
    property real sublineP: 0
    property real ruleP: 0
    property real g0: 0; property real g1: 0; property real g2: 0; property real g3: 0; property real g4: 0
    property real labelsP: 0
    property real chromeP: 0
    property real skipP: 0
    property real uiOut: 0
    property real sceneOut: 0
    property real swapP: 0

    readonly property real logoKFinal: 0.47
    readonly property real logoCenterFrac: 0.285
    readonly property real logoLiftFinal: {
        const cy = fy + (logoBox.fy + logoBox.fh / 2) * fh;
        const scaled = pivotY + logoKFinal * (cy - pivotY);
        return logoCenterFrac * height - scaled;
    }

    property int days: 0
    property int hours: 0
    property int minutes: 0
    property int seconds: 0
    property int millis: 0
    readonly property bool released: remainingMs <= 0

    function pad(n, w) { return String(n).padStart(w, "0"); }

    function tick() {
        const now = Date.now() + ctl.nowOffset;
        const rem = Math.max(0, ctl.releaseMs - now);
        remainingMs = rem;
        days = Math.floor(rem / 86400000);
        hours = Math.floor(rem / 3600000) % 24;
        minutes = Math.floor(rem / 60000) % 60;
        seconds = Math.floor(rem / 1000) % 60;
        millis = rem % 1000;
        displayText = pad(days, 2) + ":" + pad(hours, 2) + ":" + pad(minutes, 2) + ":"
                    + pad(seconds, 2) + "." + pad(millis, 3);
    }

    FrameAnimation {
        running: !sc.sceneDone
        onTriggered: sc.tick()
    }
    property bool sceneDone: false

    Component.onCompleted: {
        tick();
        enterFade.start();
        enter.start();
        if (!GtaConfig.introEnabled) {
            introNote = "";
            startWithoutFilm();
        } else {
            filmWatchdog.start();
        }
    }

    QtObject {
        id: logoBox
        property real fx: 0.258073
        property real fy: 0.200926
        property real fw: 0.427604
        property real fh: 0.584722
        property bool keyed: false
    }

    FileView {
        path: GtaConfig.logoMetaPath
        onLoaded: {
            const p = text().trim().split(/\s+/);
            if (p.length >= 4 && p.slice(0, 4).every(v => isFinite(Number(v)))) {
                logoBox.fx = Number(p[0]); logoBox.fy = Number(p[1]);
                logoBox.fw = Number(p[2]); logoBox.fh = Number(p[3]);
                logoBox.keyed = true;
            }
        }
        onLoadFailed: logoBox.keyed = false
    }

    MouseArea {
        anchors.fill: parent
        z: 1000
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.BlankCursor
    }

    Keys.onEscapePressed: ctl.close()
    Keys.onSpacePressed: skipIntro()
    Keys.onReturnPressed: skipIntro()

    Item {
        id: stageRoot
        anchors.fill: parent
        clip: true
        opacity: sc.enterP * (1 - sc.sceneOut)

        Rectangle {
            anchors.fill: parent
            color: sc.slate
        }

        Rectangle {
            anchors.fill: parent
            opacity: sc.gradeP
            gradient: Gradient {
                GradientStop { position: 0.0; color: "#1d1c2f" }
                GradientStop { position: 0.45; color: "#17162a" }
                GradientStop { position: 1.0; color: sc.navyDeep }
            }
        }

        Canvas {
            id: glow
            anchors.fill: parent
            opacity: 0.2 * sc.glowP * sc.glowBreath
            scale: 0.92 + 0.08 * sc.glowP
            transformOrigin: Item.Top
            renderStrategy: Canvas.Cooperative
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                const h = height, cx = width / 2, cy = -0.30 * h;
                c.reset();
                const g = c.createRadialGradient(cx, cy, 0, cx, cy, 1.5 * h);
                g.addColorStop(0.0, "#ffd687");
                g.addColorStop(0.5 / 1.5, "#fc5243");
                g.addColorStop(0.9 / 1.5, "#9d2f6a");
                g.addColorStop(1.0, "rgba(32,31,66,0)");
                c.fillStyle = g;
                c.fillRect(0, 0, width, height);
            }
        }

        Item {
            id: cameraRig
            anchors.fill: parent
            transform: Scale {
                origin.x: sc.pivotX; origin.y: sc.pivotY
                xScale: sc.camera; yScale: sc.camera
            }

            Loader {
                id: video
                x: sc.fx; y: sc.fy; width: sc.fw; height: sc.fh
                active: GtaConfig.introEnabled && !sc.introFailed
                asynchronous: false
                opacity: (item && item.hasFrame ? 1 : 0) * sc.videoOpacity
                visible: opacity > 0.001
                Behavior on opacity {
                    enabled: !sc.leaving
                    NumberAnimation { duration: 280 * sc.sp; easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeQuad }
                }

                Component.onCompleted: {
                    const clip = GtaConfig.clipPath;
                    const src = GtaConfig.videoPath;
                    filmProbe.command = ["sh", "-c",
                        "if [ -s \"$1\" ]; then echo clip; elif [ -f \"$2\" ]; then echo source; else echo none; fi",
                        "sh", clip, src];
                    filmProbe.running = true;
                }

                onStatusChanged: {
                    if (status === Loader.Error) {
                        sc.ctl.log("intro: Qt Multimedia unavailable (install qt6-multimedia qt6-multimedia-ffmpeg)");
                        sc.filmUnavailable("Intro video unavailable — Qt Multimedia is not installed");
                    }
                }
            }

            Item {
                id: logo
                property bool keyedFailed: false
                readonly property bool useKeyed: logoBox.keyed && !keyedFailed
                x: useKeyed ? sc.fx + logoBox.fx * sc.fw : sc.fx
                y: useKeyed ? sc.fy + logoBox.fy * sc.fh : sc.fy
                width: useKeyed ? logoBox.fw * sc.fw : sc.fw
                height: useKeyed ? logoBox.fh * sc.fh : sc.fh
                opacity: sc.logoOpacity
                visible: opacity > 0.001

                transform: [
                    Scale {
                        origin.x: sc.pivotX - logo.x
                        origin.y: sc.pivotY - logo.y
                        xScale: sc.logoK; yScale: sc.logoK
                    },
                    Translate { y: sc.logoLift + sc.floatY }
                ]

                Image {
                    id: logoImg
                    anchors.fill: parent
                    source: "file://" + (logo.useKeyed ? GtaConfig.logoPath : GtaConfig.wallpaperPath)
                    sourceSize.width: Math.min(2400, Math.ceil(parent.width * 1.1))
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    smooth: true
                    mipmap: true
                    cache: false
                    onStatusChanged: {
                        if (status !== Image.Error)
                            return;
                        sc.ctl.log("logo: cannot load " + source);
                        if (logo.useKeyed)
                            logo.keyedFailed = true;
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: logoImg.status === Image.Error && !logo.useKeyed
                    text: "GRAND THEFT AUTO VI"
                    color: sc.cream
                    font.family: "Barlow Condensed"
                    font.weight: Font.Black
                    font.pixelSize: parent.height * 0.18
                }
            }
        }

        Canvas {
            anchors.fill: parent
            renderStrategy: Canvas.Cooperative
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const c = getContext("2d");
                c.reset();
                const r = Math.hypot(width, height) / 2;
                const g = c.createRadialGradient(width / 2, height * 0.46, r * 0.35, width / 2, height * 0.46, r * 1.05);
                g.addColorStop(0, "rgba(6,5,12,0)");
                g.addColorStop(1, "rgba(6,5,12,0.55)");
                c.fillStyle = g;
                c.fillRect(0, 0, width, height);
            }
        }
    }

    Item {
        id: ui
        anchors.fill: parent
        opacity: (1 - sc.uiOut) * sc.enterP
        transform: Translate { y: 18 * sc.u * sc.uiOut }

        Item {
            id: eyebrow
            anchors.horizontalCenter: parent.horizontalCenter
            y: sc.height * 0.535
            width: eyebrowText.implicitWidth
            height: eyebrowText.implicitHeight
            opacity: sc.eyebrowP
            readonly property real track: (0.42 + 0.9 * (1 - sc.eyebrowP)) * 21 * sc.u

            Text {
                id: eyebrowText
                x: eyebrow.track / 2
                text: sc.released && sc.swapP > 0.5 ? "GRAND THEFT AUTO VI" : "NOVEMBER 19, 2026"
                color: "#ffffff"
                font.family: "Lexend"
                font.weight: Font.DemiBold
                font.pixelSize: 21 * sc.u
                font.letterSpacing: eyebrow.track
            }
        }

        Item {
            id: subline
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: eyebrow.bottom
            anchors.topMargin: 7 * sc.u
            width: sublineText.implicitWidth
            height: sublineText.implicitHeight
            opacity: sc.sublineP
            readonly property real track: (0.36 + 0.6 * (1 - sc.sublineP)) * 12 * sc.u
            layer.enabled: true
            layer.effect: SunsetFx {}

            Text {
                id: sublineText
                x: subline.track / 2
                text: sc.released && sc.swapP > 0.5
                      ? "AVAILABLE NOW ON PLAYSTATION 5"
                      : "UNLOCKS AT MIDNIGHT  ·  KYIV TIME"
                color: "#ffffff"
                font.family: "Lexend"
                font.weight: Font.Bold
                font.pixelSize: 12 * sc.u
                font.letterSpacing: subline.track
            }
        }

        FontMetrics {
            id: bigMetrics
            font.family: "Barlow Condensed"
            font.weight: Font.ExtraBold
            font.pixelSize: digits.big
        }
        FontMetrics {
            id: smallMetrics
            font.family: "Barlow Condensed"
            font.weight: Font.Bold
            font.pixelSize: digits.small
        }

        Item {
            id: digits
            readonly property real big: 176 * sc.u
            readonly property real small: 76 * sc.u
            readonly property real cellBig: maxAdvance(bigMetrics) + 2 * sc.u
            readonly property real cellSmall: maxAdvance(smallMetrics) + 1 * sc.u
            readonly property real colonW: 52 * sc.u
            readonly property real capH: 0.70 * big + 0.10 * big
            readonly property real capTop: bigMetrics.ascent - 0.70 * big - 0.05 * big
            readonly property int dayCells: Math.max(2, String(sc.days).length)

            function maxAdvance(m) {
                let w = 0;
                for (let d = 0; d <= 9; d++)
                    w = Math.max(w, m.advanceWidth(String(d)));
                return Math.ceil(w);
            }

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: subline.bottom
            anchors.topMargin: 6 * sc.u
            width: row.width
            height: row.height + labelGap + 20 * sc.u
            readonly property real labelGap: 4 * sc.u
            opacity: 1 - sc.swapP
            visible: opacity > 0.001

            Row {
                id: row
                spacing: 0

                Group { p: sc.g0; count: digits.dayCells; value: sc.days }
                Colon { p: sc.g0 }
                Group { p: sc.g1; count: 2; value: sc.hours }
                Colon { p: sc.g1 }
                Group { p: sc.g2; count: 2; value: sc.minutes }
                Colon { p: sc.g2 }
                Group { p: sc.g3; count: 2; value: sc.seconds }

                Item {
                    id: msGroup
                    width: msRow.width + 10 * sc.u
                    height: bigMetrics.height

                    Item {
                        id: msWin
                        y: digits.capTop
                        width: parent.width
                        height: digits.capH
                        clip: true

                    Item {
                        id: msInner
                        width: parent.width
                        height: bigMetrics.height
                        y: -msWin.y + (1 - sc.g4) * msWin.height * 1.1
                        opacity: Math.min(1, sc.g4 * 1.6)

                        Item {
                            id: msRow
                            x: 10 * sc.u
                            y: bigMetrics.ascent - smallMetrics.ascent
                            readonly property real dotW: smallMetrics.advanceWidth(".") + 2 * sc.u
                            width: dotW + 3 * digits.cellSmall
                            height: smallMetrics.height

                            Repeater {
                                id: glyphs
                                model: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "."]
                                Item {
                                    required property string modelData
                                    readonly property alias tex: src
                                    width: digits.cellSmall
                                    height: smallMetrics.height
                                    Text {
                                        id: glyph
                                        width: parent.width
                                        horizontalAlignment: Text.AlignHCenter
                                        text: parent.modelData
                                        color: "#ffffff"
                                        font.family: "Barlow Condensed"
                                        font.weight: Font.Bold
                                        font.pixelSize: digits.small
                                    }
                                    ShaderEffectSource {
                                        id: src
                                        sourceItem: glyph
                                        hideSource: true
                                        visible: false
                                        width: parent.width
                                        height: parent.height
                                    }
                                }
                            }

                            Repeater {
                                model: 4
                                SunsetFx {
                                    required property int index
                                    readonly property string ch: index === 0 ? "."
                                        : String(sc.millis).padStart(3, "0")[index - 1]
                                    readonly property int gi: ch === "." ? 10 : Number(ch)
                                    x: index === 0 ? msRow.dotW / 2 - digits.cellSmall / 2
                                                   : msRow.dotW + (index - 1) * digits.cellSmall
                                    width: digits.cellSmall
                                    height: smallMetrics.height
                                    source: glyphs.count === 11 ? glyphs.itemAt(gi).tex : null
                                    radius: Qt.point(0.6279 * msRow.width / width, 1.0)
                                    center: Qt.point((msRow.width / 2 - x) / width, 0.0)
                                }
                            }
                        }
                    }
                    }
                }
            }

            Item {
                id: labels
                anchors.top: row.bottom
                anchors.topMargin: digits.labelGap
                width: row.width
                height: 16 * sc.u
                opacity: sc.labelsP
                transform: Translate { y: 8 * sc.u * (1 - sc.labelsP) }

                Repeater {
                    model: [
                        { at: 0, cells: -1, text: sc.days === 1 ? "DAY" : "DAYS" },
                        { at: 1, cells: 2, text: "HOURS" },
                        { at: 2, cells: 2, text: "MINUTES" },
                        { at: 3, cells: 2, text: "SECONDS" },
                        { at: 4, cells: 3, text: "MS" }
                    ]
                    Text {
                        required property var modelData
                        readonly property real centre: {
                            const dc = digits.dayCells * digits.cellBig;
                            const unit = 2 * digits.cellBig + digits.colonW;
                            switch (modelData.at) {
                            case 0: return dc / 2;
                            case 1: return dc + digits.colonW + digits.cellBig;
                            case 2: return dc + digits.colonW + unit + digits.cellBig;
                            case 3: return dc + digits.colonW + 2 * unit + digits.cellBig;
                            default: return msGroup.x + 10 * sc.u + msRow.width / 2;
                            }
                        }
                        x: centre - implicitWidth / 2 + font.letterSpacing / 2
                        text: modelData.text
                        color: sc.lilac
                        opacity: 0.62
                        font.family: "Lexend"
                        font.weight: Font.DemiBold
                        font.pixelSize: 12 * sc.u
                        font.letterSpacing: 0.32 * 12 * sc.u
                    }
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: labels.bottom
                anchors.topMargin: 14 * sc.u
                width: row.width * 1.08 * sc.ruleP
                height: Math.max(1, sc.u)
                opacity: 0.85
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 0.25; color: Qt.rgba(0.976, 0.463, 0.69, 0.55) }
                    GradientStop { position: 0.5; color: Qt.rgba(1, 0.86, 0.6, 0.75) }
                    GradientStop { position: 0.75; color: Qt.rgba(0.976, 0.463, 0.69, 0.55) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }
        }

        Item {
            id: releasedBlock
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: subline.bottom
            anchors.topMargin: 2 * sc.u
            width: outNow.implicitWidth
            height: outNow.implicitHeight
            clip: true
            visible: sc.swapP > 0.001

            Text {
                id: outNow
                y: (1 - sc.swapP) * height * 0.95
                opacity: Math.min(1, sc.swapP * 1.5)
                text: "OUT NOW"
                color: sc.cream
                font.family: "Barlow Condensed"
                font.weight: Font.ExtraBold
                font.pixelSize: 210 * sc.u
                font.letterSpacing: -0.01 * 210 * sc.u
            }
        }

        Image {
            id: mark
            x: 56 * sc.u
            y: 36 * sc.u
            height: 64 * sc.u
            width: height * sourceSize.width / Math.max(1, sourceSize.height)
            source: Qt.resolvedUrl("assets/vi-mark.png")
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            opacity: Math.max(sc.chromeP, sc.skipP * 0.9)
        }

        Text {
            x: 56 * sc.u
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 40 * sc.u
            opacity: 0.55 * sc.chromeP
            text: sc.introNote
            color: sc.lilac
            font.family: "Lexend"
            font.pixelSize: 12 * sc.u
            font.letterSpacing: 0.01 * 12 * sc.u
        }

    }

    Image {
        id: grain
        x: -grainJitter.dx
        y: -grainJitter.dy
        width: parent.width + 128
        height: parent.height + 128
        source: Qt.resolvedUrl("../assets/grain.png")
        fillMode: Image.Tile
        horizontalAlignment: Image.AlignLeft
        verticalAlignment: Image.AlignTop
        opacity: 0.045 * sc.enterP * (1 - sc.sceneOut)
        smooth: false
        asynchronous: true

        Timer {
            id: grainJitter
            property int dx: 0
            property int dy: 0
            interval: 42
            repeat: true
            running: !sc.sceneDone
            onTriggered: { dx = Math.floor(Math.random() * 128); dy = Math.floor(Math.random() * 128); }
        }
    }

    Process {
        id: filmProbe
        stdout: StdioCollector {
            onStreamFinished: {
                const what = text.trim();
                if (sc.leaving || sc.stage !== "intro")
                    return;
                if (what === "clip") {
                    sc.filmOffset = GtaConfig.videoSeek * 1000;
                    sc.startFilm("file://" + GtaConfig.clipPath, 0);
                } else if (what === "source") {
                    sc.filmOffset = 0;
                    sc.ctl.log("intro: cached clip missing, playing source with seek");
                    sc.startFilm("file://" + GtaConfig.videoPath, GtaConfig.videoSeek * 1000);
                } else {
                    sc.ctl.log("intro: video missing at " + GtaConfig.videoPath);
                    sc.filmUnavailable("Intro video not found");
                }
            }
        }
    }

    property real filmOffset: 0
    readonly property real sourceMs: video.item ? video.item.position + filmOffset : 0

    function startFilm(url, startAt) {
        video.setSource(Qt.resolvedUrl("IntroVideo.qml"), {
            source: url, startAt: startAt,
            audio: GtaConfig.introAudio, volume: GtaConfig.introVolume
        });
    }

    Component.onDestruction: {
        sceneDone = true;
        if (video.item && video.item.stopNow)
            video.item.stopNow();
    }

    Connections {
        target: video.item
        ignoreUnknownSignals: true
        function onFailed(why) {
            sc.ctl.log("intro: " + why);
            sc.filmUnavailable("Intro video could not be played");
        }
        function onHasFrameChanged() {
            if (video.item.hasFrame && sc.stage === "intro")
                skipAppear.start();
        }
    }

    Connections {
        target: video
        function onLoaded() {
            if (video.item && video.item.begin)
                video.item.begin();
        }
    }

    onSourceMsChanged: {
        if (stage === "intro" && !leaving && video.item && video.item.hasFrame
                && sourceMs >= GtaConfig.handoffAt * 1000)
            handoff(true);
    }

    Timer {
        id: filmWatchdog
        interval: 4000
        onTriggered: {
            if (sc.stage === "intro" && !(video.item && video.item.hasFrame)) {
                sc.ctl.log("intro: no frame after " + interval + " ms (" + sc.mediaState + ")");
                sc.filmUnavailable("Intro video could not be played");
            }
        }
    }

    function filmUnavailable(note) {
        if (introFailed || leaving)
            return;
        ctl.log("intro: unavailable (" + note + ")");
        introFailed = true;
        introNote = note;
        if (stage === "intro")
            startWithoutFilm();
    }

    function startWithoutFilm() {
        logoOpacity = 0;
        handoff(false);
    }

    function skipIntro() {
        if (stage !== "intro" || leaving)
            return;
        if (video.item && video.item.fadeOutAndStop)
            video.item.fadeOutAndStop(260 * sp);
        handoff(false);
    }

    function handoff(fromFilm) {
        if (stage !== "intro" || leaving)
            return;
        stage = "handoff";
        ctl.log("handoff " + (fromFilm ? "from film at " + Math.round(sourceMs) + " ms" : "without film"));
        filmWatchdog.stop();
        skipAppear.stop();
        ctl.applyWallpaper();
        reveal.fromFilm = fromFilm;
        reveal.start();
    }

    NumberAnimation {
        id: enterFade
        target: sc; property: "enterP"; to: 1; duration: 420 * sc.sp
        easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut
    }

    SequentialAnimation {
        id: enter
        NumberAnimation { target: sc; property: "camera"; from: 1.10; to: 1.0; duration: 1600 * sc.sp
                          easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        NumberAnimation { target: sc; property: "camera"; to: 1.035; duration: 17000 * sc.sp
                          easing.type: Easing.InOutSine }
    }

    NumberAnimation {
        id: skipAppear
        target: sc; property: "skipP"; to: 1
        duration: 900 * sc.sp
        easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut
    }

    ParallelAnimation {
        id: reveal
        property bool fromFilm: true

        onStarted: enter.stop()

        NumberAnimation { target: sc; property: "skipP"; to: 0; duration: 300 * sc.sp
                          easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeQuad }

        NumberAnimation { target: sc; property: "logoOpacity"; to: 1
                          duration: (reveal.fromFilm ? 220 : 900) * sc.sp
                          easing.type: Easing.BezierSpline; easing.bezierCurve: reveal.fromFilm ? sc.easeQuad : sc.easeOut }

        SequentialAnimation {
            PauseAnimation { duration: (reveal.fromFilm ? 240 : 0) * sc.sp }
            NumberAnimation { target: sc; property: "videoOpacity"; to: 0
                              duration: (reveal.fromFilm ? 260 : 380) * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeQuad }
        }

        SequentialAnimation {
            PauseAnimation { duration: 320 * sc.sp }
            ParallelAnimation {
                NumberAnimation { target: sc; property: "camera"; to: 1.0; duration: 1500 * sc.sp
                                  easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeInOut }
                NumberAnimation { target: sc; property: "logoK"; to: sc.logoKFinal; duration: 1500 * sc.sp
                                  easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeInOut }
                NumberAnimation { target: sc; property: "logoLift"; to: sc.logoLiftFinal; duration: 1500 * sc.sp
                                  easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeInOut }
            }
        }

        SequentialAnimation {
            PauseAnimation { duration: 420 * sc.sp }
            NumberAnimation { target: sc; property: "gradeP"; to: 1; duration: 1800 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeInOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 700 * sc.sp }
            NumberAnimation { target: sc; property: "glowP"; to: 1; duration: 2400 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }

        SequentialAnimation {
            PauseAnimation { duration: (GtaConfig.dateBeatAt - GtaConfig.handoffAt) * 1000 * sc.sp }
            NumberAnimation { target: sc; property: "eyebrowP"; to: 1; duration: 1300 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: ((GtaConfig.dateBeatAt - GtaConfig.handoffAt) * 1000 + 160) * sc.sp }
            NumberAnimation { target: sc; property: "sublineP"; to: 1; duration: 1200 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }

        SequentialAnimation {
            PauseAnimation { duration: 1800 * sc.sp }
            NumberAnimation { target: sc; property: "g0"; to: 1; duration: 1100 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 1890 * sc.sp }
            NumberAnimation { target: sc; property: "g1"; to: 1; duration: 1100 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 1980 * sc.sp }
            NumberAnimation { target: sc; property: "g2"; to: 1; duration: 1100 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 2070 * sc.sp }
            NumberAnimation { target: sc; property: "g3"; to: 1; duration: 1100 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 2160 * sc.sp }
            NumberAnimation { target: sc; property: "g4"; to: 1; duration: 1100 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 2200 * sc.sp }
            NumberAnimation { target: sc; property: "ruleP"; to: 1; duration: 1400 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeInOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 2500 * sc.sp }
            NumberAnimation { target: sc; property: "labelsP"; to: 1; duration: 900 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 2900 * sc.sp }
            NumberAnimation { target: sc; property: "chromeP"; to: 1; duration: 900 * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeOut }
        }
        SequentialAnimation {
            PauseAnimation { duration: 1800 * sc.sp }
            ScriptAction { script: if (sc.released) releaseSwap.start(); }
        }

        onFinished: {
            if (!sc.leaving) {
                sc.stage = sc.released ? "released" : "countdown";
                if (sc.released && sc.swapP < 1 && !releaseSwap.running)
                    releaseSwap.start();
                idle.start();
            }
        }
    }

    ParallelAnimation {
        id: idle
        loops: Animation.Infinite
        SequentialAnimation {
            NumberAnimation { target: sc; property: "floatY"; to: -5 * sc.u; duration: 4600; easing.type: Easing.InOutSine }
            NumberAnimation { target: sc; property: "floatY"; to: 0; duration: 4600; easing.type: Easing.InOutSine }
        }
        SequentialAnimation {
            NumberAnimation { target: sc; property: "glowBreath"; to: 0.82; duration: 6200; easing.type: Easing.InOutSine }
            NumberAnimation { target: sc; property: "glowBreath"; to: 1; duration: 6200; easing.type: Easing.InOutSine }
        }
    }

    onReleasedChanged: {
        if (released && (stage === "countdown") && !leaving) {
            stage = "released";
            releaseSwap.start();
        }
    }

    NumberAnimation {
        id: releaseSwap
        target: sc; property: "swapP"; to: 1
        duration: 1400 * sc.sp
        easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeInOut
    }

    function leave() {
        if (leaving)
            return;
        leaving = true;
        ctl.log("leave from stage " + stage);
        enter.stop();
        reveal.stop();
        idle.stop();
        skipAppear.stop();
        filmWatchdog.stop();
        if (video.item && video.item.fadeOutAndStop)
            video.item.fadeOutAndStop(110);
        exitAnim.landOnWallpaper = logoOpacity > 0.5;
        exitAnim.cameraTo = stage === "intro" ? camera * 1.03 : 1.0;
        exitAnim.start();
    }

    ParallelAnimation {
        id: exitAnim
        property bool landOnWallpaper: false
        property real cameraTo: 1.0

        NumberAnimation { target: sc; property: "uiOut"; to: 1; duration: 260 * sc.sp
                          easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeIn }
        NumberAnimation { target: sc; property: "skipP"; to: 0; duration: 200 * sc.sp }

        NumberAnimation { target: sc; property: "logoK"; to: 1.0
                          duration: 560 * sc.sp
                          easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeInOut }
        NumberAnimation { target: sc; property: "logoLift"; to: 0
                          duration: 560 * sc.sp
                          easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeInOut }
        NumberAnimation { target: sc; property: "floatY"; to: 0; duration: 400 * sc.sp }
        NumberAnimation { target: sc; property: "camera"; to: exitAnim.cameraTo
                          duration: 560 * sc.sp
                          easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeInOut }

        SequentialAnimation {
            PauseAnimation { duration: (exitAnim.landOnWallpaper ? 300 : 120) * sc.sp }
            NumberAnimation { target: sc; property: "sceneOut"; to: 1
                              duration: (exitAnim.landOnWallpaper ? 420 : 340) * sc.sp
                              easing.type: Easing.BezierSpline; easing.bezierCurve: sc.easeQuad }
        }

        onFinished: {
            sc.sceneDone = true;
            sc.ctl.finished();
        }
    }
}
