pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property int users: 0

    property real cpu: -1
    property real mem: -1
    property real temp: -1
    property real gpu: -1
    property real vram: -1
    property real gputemp: -1

    property string cpuLabel: ""
    property string memLabel: ""
    property string tempLabel: ""
    property string gpuLabel: ""
    property string vramLabel: ""
    property string gputempLabel: ""

    function acquire() { root.users++; }
    function release() { root.users = Math.max(0, root.users - 1); }

    Process {
        running: root.users > 0
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/sysmon.py"]

        stdout: SplitParser {
            onRead: function (line) {
                let s;
                try {
                    s = JSON.parse(line);
                } catch (e) {
                    return;
                }

                root.cpu = s.cpu === null ? -1 : s.cpu;
                root.mem = s.mem === null ? -1 : s.mem;
                root.temp = s.temp === null ? -1 : s.temp;
                root.gpu = s.gpu === null ? -1 : s.gpu;
                root.vram = s.vram === null ? -1 : s.vram;
                root.gputemp = s.gputemp === null ? -1 : s.gputemp;

                root.cpuLabel = s.cpu_label || "";
                root.memLabel = s.mem_label || "";
                root.tempLabel = s.temp_label || "";
                root.gpuLabel = s.gpu_label || "";
                root.vramLabel = s.vram_label || "";
                root.gputempLabel = s.gputemp_label || "";
            }
        }
    }
}
