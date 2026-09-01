pragma Singleton

import Quickshell
import Quickshell.Bluetooth
import QtQuick

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool present: adapter !== null
    readonly property bool powered: present && adapter.enabled
    readonly property bool scanning: present && adapter.discovering

    property string error: ""

    property var devices: []

    readonly property int connectedCount: {
        let n = 0;
        for (const d of root.devices) if (d.connected) n++;
        return n;
    }

    readonly property var primary: {
        for (const d of root.devices) if (d.connected) return d;
        return null;
    }

    readonly property string glyph: {
        if (!root.present) return "󰂲";
        if (!root.powered) return "󰂲";
        if (root.connectedCount > 0) return "󰂱";
        return "󰂯";
    }

    function icon(dev) {
        const i = dev && dev.icon ? String(dev.icon) : "";
        if (i.indexOf("headset") >= 0 || i.indexOf("headphone") >= 0) return "󰋋";
        if (i.indexOf("audio") >= 0 || i.indexOf("speaker") >= 0) return "󰓃";
        if (i.indexOf("phone") >= 0) return "󰄞";
        if (i.indexOf("mouse") >= 0) return "󰍽";
        if (i.indexOf("keyboard") >= 0) return "󰌌";
        if (i.indexOf("gaming") >= 0 || i.indexOf("joystick") >= 0) return "󰊴";
        if (i.indexOf("computer") >= 0 || i.indexOf("laptop") >= 0) return "󰌢";
        if (i.indexOf("watch") >= 0) return "󰖉";
        if (i.indexOf("printer") >= 0) return "󰐪";
        if (i.indexOf("display") >= 0 || i.indexOf("video") >= 0) return "󰍹";
        return "󰂯";
    }

    function label(dev) {
        if (!dev) return "";
        return dev.name || dev.deviceName || dev.address || "устройство";
    }

    Timer {
        id: rebuild
        interval: 120
        onTriggered: root.collect()
    }

    function collect() {
        if (!root.adapter || !root.adapter.devices) {
            root.devices = [];
            return;
        }
        const src = root.adapter.devices.values || root.adapter.devices;
        const count = src.length !== undefined ? src.length
                    : (src.count !== undefined ? src.count : 0);
        const list = [];
        for (let i = 0; i < count; i++) {
            const d = src[i] !== undefined ? src[i] : (src.get ? src.get(i) : null);
            if (d) list.push(d);
        }

        list.sort((a, b) => {
            const rank = d => (d.connected ? 0 : d.paired || d.bonded ? 1 : 2);
            if (rank(a) !== rank(b)) return rank(a) - rank(b);
            const named = d => (d.name || d.deviceName) ? 0 : 1;
            if (named(a) !== named(b)) return named(a) - named(b);
            return root.label(a).localeCompare(root.label(b));
        });
        root.devices = list;
    }

    function refresh() { rebuild.restart(); }

    Connections {
        target: Bluetooth
        ignoreUnknownSignals: true
        function onDefaultAdapterChanged() { root.refresh(); }
    }

    Connections {
        target: root.adapter
        ignoreUnknownSignals: true
        function onEnabledChanged() { root.refresh(); }
        function onDiscoveringChanged() { root.refresh(); }
    }

    Connections {
        target: root.adapter ? root.adapter.devices : null
        ignoreUnknownSignals: true
        function onObjectInsertedPost() { root.refresh(); }
        function onObjectRemovedPost() { root.refresh(); }
    }

    Instantiator {
        model: root.devices
        delegate: QtObject {
            required property var modelData
            readonly property var conn: Connections {
                target: modelData
                ignoreUnknownSignals: true
                function onConnectedChanged() { root.refresh(); }
                function onStateChanged() { root.refresh(); }
                function onPairedChanged() { root.refresh(); }
                function onBondedChanged() { root.refresh(); }
                function onBatteryChanged() { root.refresh(); }
                function onNameChanged() { root.refresh(); }
            }
        }
    }

    function setPowered(on) {
        if (!root.adapter) return;
        root.adapter.enabled = on;
    }

    function togglePower() { root.setPowered(!root.powered); }

    function setScanning(on) {
        if (!root.adapter || !root.adapter.enabled) return;
        root.adapter.discovering = on;
    }

    function toggleDevice(dev) {
        if (!dev) return;
        root.error = "";
        if (dev.connected || dev.state === BluetoothDeviceState.Connecting) {
            dev.disconnect();
            return;
        }
        if (!dev.paired && !dev.bonded) {
            dev.pair();
            return;
        }
        if (!dev.trusted) dev.trusted = true;
        dev.connect();
    }

    function forget(dev) {
        if (!dev) return;
        dev.forget();
        root.refresh();
    }

    Component.onCompleted: root.collect()
}
