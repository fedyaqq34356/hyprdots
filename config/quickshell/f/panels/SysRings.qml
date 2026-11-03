import Quickshell
import Quickshell.Wayland
import QtQuick
import "root:/design"
import "root:/reusables"
import "root:/services"

Scope {
    id: root

    property bool shown: false

    function toggle() {
        root.shown = !root.shown;
    }

    function close() {
        root.shown = false;
    }

    function v(x) { return x < 0 ? 0 : Math.min(1, x); }

    component OrbFx: ShaderEffect {
        id: orb

        fragmentShader: "root:/design/shaders/orb.frag.qsb"
        blending: true

        property var coreLoads: []

        property vector2d size: Qt.vector2d(orb.width, orb.height)
        property real t: 0
        property real grow: 1
        property real level: 0
        property real load: 0
        property real heat: 0
        property real flash: 0
        property real spikes: 0
        property real ncores: 0

        property vector4d c0: orb.pack(0)
        property vector4d c1: orb.pack(4)
        property vector4d c2: orb.pack(8)
        property vector4d c3: orb.pack(12)
        Behavior on c0 { PropertyAnimation { duration: 900; easing.type: Easing.InOutCubic } }
        Behavior on c1 { PropertyAnimation { duration: 900; easing.type: Easing.InOutCubic } }
        Behavior on c2 { PropertyAnimation { duration: 900; easing.type: Easing.InOutCubic } }
        Behavior on c3 { PropertyAnimation { duration: 900; easing.type: Easing.InOutCubic } }

        property color tint: "white"
        property color hot: "red"

        function pack(i) {
            const a = orb.coreLoads || [];
            const v = k => Number(a[i + k] || 0);
            return Qt.vector4d(v(0), v(1), v(2), v(3));
        }

        function kick() {
            flashAnim.restart();
        }

        NumberAnimation {
            id: flashAnim
            target: orb
            property: "flash"
            from: 0
            to: 1
            duration: 1100
            easing.type: Easing.InOutCubic
            onFinished: orb.flash = 0
        }
}

    component OrbCell: Item {
        id: unit

        property string caption: ""
        property real load: 0
        property real level: 0
        property real heat: 0
        property real memTotal: -1
        property bool showLevel: false
        property real tempC: -1
        property real okBelow: 70
        property var cores: []
        property color tint: Colors.accent
        property real order: 0
        property real g: 0
        property real t: 0
        property bool live: false
        property bool tappable: false

        signal picked()

        width: 224
        height: 330

        readonly property real grow: {
            const k = Math.max(0, Math.min(1, (unit.g - 0.45 - unit.order * 0.08) / 0.39));
            return 1 - Math.pow(1 - k, 3);
        }

        property real sLoad: unit.live ? unit.load : 0
        Behavior on sLoad { NumberAnimation { duration: 900; easing.type: Easing.InOutCubic } }
        property real sLevel: unit.live ? unit.level : 0
        Behavior on sLevel { NumberAnimation { duration: 1500; easing.type: Easing.OutCubic } }
        property real sHeat: unit.heat
        Behavior on sHeat { NumberAnimation { duration: 1800; easing.type: Easing.InOutSine } }
        property real sSpikes: unit.live && unit.grow > 0.9 ? 1 : 0
        Behavior on sSpikes { NumberAnimation { duration: 1300; easing.type: Easing.OutCubic } }

        property real last: -1
        onLoadChanged: {
            if (unit.live && unit.last >= 0 && unit.load - unit.last > 0.2)
                orb.kick();
            unit.last = unit.load;
        }

        readonly property color hotTone: Colors.mix(Colors.warn, Colors.bad,
                                                    Math.max(0, Math.min(1, (unit.sHeat - 0.7) / 0.25)))
        readonly property color tone: Colors.mix(unit.tint, unit.hotTone,
                                                 Math.max(0, Math.min(1, (unit.sHeat - 0.35) / 0.6)))

        HoverHandler {
            id: hover
            cursorShape: unit.tappable ? Qt.PointingHandCursor : Qt.ArrowCursor
        }
        TapHandler {
            enabled: unit.tappable
            onTapped: unit.picked()
        }

        OrbFx {
            id: orb
            width: 220
            height: 220
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            visible: unit.grow > 0.001
            t: unit.t + unit.order * 17
            grow: unit.grow
            level: unit.sLevel
            load: unit.sLoad
            heat: unit.sHeat
            spikes: unit.sSpikes
            ncores: Math.min(16, unit.cores.length)
            coreLoads: unit.live ? unit.cores : []
            tint: unit.tint
            hot: unit.hotTone
        }

        Column {
            id: info
            anchors.top: orb.bottom
            anchors.topMargin: -6
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 2
            opacity: Math.max(0, (unit.grow - 0.5) / 0.5)
            transform: Translate { y: (1 - info.opacity) * 10 }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 2

                Text {
                    id: big
                    text: Math.round((unit.showLevel ? unit.sLevel : unit.sLoad) * 100)
                    color: Colors.fg
                    font.family: Fonts.display
                    font.features: Fonts.nums
                    font.pixelSize: Fonts.giant
                    font.weight: Font.Bold
                }
                Text {
                    text: "%"
                    anchors.baseline: big.baseline
                    color: Colors.alpha(Colors.fg, 0.4)
                    font.family: Fonts.display
                    font.features: Fonts.nums
                    font.pixelSize: Fonts.large
                    font.weight: Font.DemiBold
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: unit.caption
                color: hover.hovered ? unit.tone : Colors.alpha(Colors.fgDim, 0.45)
                font.family: Fonts.mono
                font.features: Fonts.nums
                font.pixelSize: Fonts.tiny
                font.weight: Font.DemiBold
                font.letterSpacing: 4
                Behavior on color { ColorAnimation { duration: 320 } }
            }

            Item { width: 1; height: 10 }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 14

                Text {
                    visible: unit.tempC >= 0
                    text: unit.tempC >= 0 ? Math.round(unit.tempC) + "°" : ""
                    color: unit.tempC < unit.okBelow ? Colors.alpha(Colors.fg, 0.85) : unit.tone
                    font.family: Fonts.display
                    font.features: Fonts.nums
                    font.pixelSize: Fonts.medium
                    font.weight: Font.DemiBold
                    Behavior on color { ColorAnimation { duration: 900 } }
                }

                Row {
                    spacing: 3
                    visible: unit.memTotal > 0
                    Text {
                        id: memNow
                        text: (unit.level * unit.memTotal).toFixed(unit.memTotal >= 100 ? 0 : 1)
                        color: Colors.alpha(Colors.fg, 0.85)
                        font.family: Fonts.display
                        font.features: Fonts.nums
                        font.pixelSize: Fonts.medium
                        font.weight: Font.DemiBold
                    }
                    Text {
                        anchors.baseline: memNow.baseline
                        text: "/ " + Math.round(unit.memTotal) + "G"
                        color: Colors.alpha(Colors.fgDim, 0.45)
                        font.family: Fonts.display
                        font.features: Fonts.nums
                        font.pixelSize: Fonts.small
                        font.weight: Font.Medium
                    }
                }
            }
        }
    }

    Loader {
        active: root.shown || closeDelay.running

        sourceComponent: Component {
            PanelWindow {
                id: win
                WlrLayershell.namespace: "qs-sysrings"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                screen: Focus.screen

                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }

                exclusiveZone: -1
                color: "transparent"

                Component.onCompleted: Sys.acquire()
                Component.onDestruction: Sys.release()

                property real t: 0
                FrameAnimation {
                    running: drip.living
                    onTriggered: win.t += frameTime
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.close()
                }

                FocusScope {
                    anchors.fill: parent
                    focus: true
                    Keys.onEscapePressed: root.close()
                    Component.onCompleted: forceActiveFocus()
                }

                Rectangle {
                    anchors.fill: parent
                    color: "black"
                    opacity: root.shown ? 0.22 : 0
                    Behavior on opacity { NumberAnimation { duration: 320; easing.type: Easing.InOutCubic } }
                }

                IsleDrip {
                    id: drip
                    anchors.fill: parent
                    open: root.shown
                    cardW: 700
                    cardH: 368
                    radius: 34
                    glow: Sys.temp >= Sys.gputemp ? cpu.tone : gpu.tone

                    MouseArea { anchors.fill: parent }

                    Row {
                        anchors.top: parent.top
                        anchors.topMargin: 14
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: 8

                        OrbCell {
                            id: cpu
                            caption: "CPU"
                            tappable: true
                            onPicked: {
                                IslandBus.procsOpen();
                                root.close();
                            }
                            order: 0
                            g: drip.g
                            t: win.t
                            live: root.shown
                            load: root.v(Sys.cpu)
                            level: root.v(Sys.mem)
                            heat: root.v(Sys.temp)
                            memTotal: Sys.memTotal
                            tempC: Sys.tempC
                            cores: Sys.cores
                            tint: Colors.accent
                        }

                        OrbCell {
                            id: ssd
                            caption: "SSD"
                            order: 1
                            g: drip.g
                            t: win.t
                            live: root.shown
                            load: root.v(Sys.diskIo)
                            level: root.v(Sys.disk)
                            showLevel: true
                            heat: Sys.diskTempC < 0 ? 0 : root.v((Sys.diskTempC - 35) / 40)
                            memTotal: Sys.diskTotal
                            tempC: Sys.diskTempC
                            okBelow: 60
                            cores: []
                            tint: Colors.mix(Colors.accent, Colors.accentAlt, 0.5)
                        }

                        OrbCell {
                            id: gpu
                            caption: "GPU"
                            order: 2
                            g: drip.g
                            t: win.t
                            live: root.shown
                            load: root.v(Sys.gpu)
                            level: root.v(Sys.vram)
                            heat: root.v(Sys.gputemp)
                            memTotal: Sys.vramTotal
                            tempC: Sys.gputempC
                            okBelow: 80
                            cores: []
                            tint: Colors.accentAlt
                        }
                    }
                }
            }
        }
    }

    Timer {
        id: closeDelay
        interval: 760
    }

    onShownChanged: {
        Sfx.panel(root.shown);
        if (!root.shown)
            closeDelay.restart();
        else
            closeDelay.stop();
    }
}
