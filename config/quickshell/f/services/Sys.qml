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

    property var cores: []
    property real memTotal: -1
    property real vramTotal: -1
    property real tempC: -1
    property real gputempC: -1
    property real disk: -1
    property real diskTotal: -1
    property real diskIo: 0
    property real diskTempC: -1
    property real cpuW: -1
    property bool cpuWExact: false
    property real gpuW: -1
    property real totalW: -1
    property real vcore: -1
    property real gpuV: -1

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
        command: [Quickshell.env("HOME") + "/.local/bin/islandd", "sys"]

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

                root.cores = s.cores || [];
                root.memTotal = s.mem_total == null ? -1 : s.mem_total;
                root.vramTotal = s.vram_total == null ? -1 : s.vram_total;
                root.tempC = s.temp_c == null ? -1 : s.temp_c;
                root.gputempC = s.gputemp_c == null ? -1 : s.gputemp_c;
                root.disk = s.disk == null ? -1 : s.disk;
                root.diskTotal = s.disk_total == null ? -1 : s.disk_total;
                root.diskIo = s.disk_io == null ? 0 : s.disk_io;
                root.diskTempC = s.disk_temp_c == null ? -1 : s.disk_temp_c;
                root.cpuW = s.cpu_w == null ? -1 : s.cpu_w;
                root.cpuWExact = !!s.cpu_w_exact;
                root.gpuW = s.gpu_w == null ? -1 : s.gpu_w;
                root.totalW = s.total_w == null ? -1 : s.total_w;
                root.vcore = s.vcore == null ? -1 : s.vcore;
                root.gpuV = s.gpu_v == null ? -1 : s.gpu_v;

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
