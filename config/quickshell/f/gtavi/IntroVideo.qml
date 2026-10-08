import QtQuick
import QtMultimedia

Item {
    id: v

    property url source
    property real startAt: 0
    property bool audio: true
    property real volume: 0.9

    readonly property real position: player.position
    readonly property real duration: player.duration
    readonly property bool playing: player.playbackState === MediaPlayer.PlayingState
    property bool hasFrame: false
    property bool started: false
    property bool stopping: false
    property string state_: "idle"

    signal failed(string why)
    signal ended()

    function begin() {
        if (started || stopping)
            return;
        state_ = "loading";
        player.source = v.source;
    }

    function fadeOutAndStop(ms) {
        if (stopping)
            return;
        stopping = true;
        ramp.stop();
        out.volume = out.volume;
        down.duration = Math.max(1, ms);
        down.from = out.volume;
        down.restart();
    }

    function stopNow() {
        stopping = true;
        ramp.stop();
        down.stop();
        out.volume = 0;
        player.stop();
        player.source = "";
        state_ = "stopped";
    }

    AudioOutput {
        id: out
        volume: 0
        muted: !v.audio
    }

    MediaPlayer {
        id: player
        audioOutput: out
        videoOutput: vo

        onMediaStatusChanged: {
            switch (mediaStatus) {
            case MediaPlayer.LoadedMedia:
                if (!v.started && !v.stopping) {
                    v.started = true;
                    if (v.startAt > 0)
                        player.position = v.startAt;
                    player.play();
                    v.state_ = "playing";
                }
                break;
            case MediaPlayer.EndOfMedia:
                v.state_ = "ended";
                v.ended();
                Qt.callLater(() => { player.source = ""; });
                break;
            case MediaPlayer.InvalidMedia:
                v.state_ = "invalid";
                v.failed("invalid media: " + v.source);
                break;
            }
        }

        onPlaybackStateChanged: {
            if (playbackState === MediaPlayer.PlayingState && !v.stopping && v.audio)
                ramp.restart();
        }

        onErrorOccurred: (error, errorString) => {
            v.state_ = "error";
            v.failed(errorString || ("media error " + error));
        }
    }

    NumberAnimation {
        id: ramp
        target: out; property: "volume"
        from: 0; to: v.volume; duration: 50
    }

    NumberAnimation {
        id: down
        target: out; property: "volume"
        to: 0
        onFinished: v.stopNow()
    }

    VideoOutput {
        id: vo
        anchors.fill: parent
        fillMode: VideoOutput.PreserveAspectCrop
    }

    Connections {
        target: vo.videoSink
        function onVideoFrameChanged() {
            if (!v.hasFrame && player.playbackState === MediaPlayer.PlayingState)
                v.hasFrame = true;
        }
    }

    Component.onDestruction: {
        player.stop();
        player.source = "";
    }
}
