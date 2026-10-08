pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property string home: Quickshell.env("HOME")

    readonly property string releaseLocal: "2026-11-19 00:00:00"
    readonly property string timezone: "Europe/Kyiv"
    readonly property bool unlockTimeConfirmed: false

    readonly property real releaseFallbackMs: 1795039200000

    readonly property string videoPath: home + "/Downloads/Video/GTAVI_Official_Cover_Art_Landscape.mp4"
    readonly property real videoSeek: 3.0
    readonly property bool introEnabled: true
    readonly property bool introAudio: true
    readonly property real introVolume: 0.9

    readonly property real handoffAt: 22.0
    readonly property real dateBeatAt: 23.5

    readonly property real videoLogoScale: 0.6222
    readonly property real logoPivotX: 0.50015
    readonly property real logoPivotY: 0.48912

    readonly property string wallpaperPath: home + "/Pictures/Wallpapers/GTAVI_An_Extended_Look (2)-00:06:18.167-0024.png"
    readonly property bool applyWallpaper: true
    readonly property bool wallpaperTheme: false
    readonly property int themeDelayMs: 6000

    readonly property string cacheDir: home + "/.cache/gtavi"
    readonly property string clipPath: cacheDir + "/intro-" + videoSeek.toFixed(3) + ".mkv"
    readonly property string logoPath: cacheDir + "/logo.png"
    readonly property string logoMetaPath: cacheDir + "/logo.txt"
    readonly property string logPath: cacheDir + "/gtavi.log"

    readonly property string monitorRule: "focused"
    readonly property real speed: 1.0
    readonly property real debugNowOffsetMs: 0
}
