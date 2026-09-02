pragma Singleton

import Quickshell
import Quickshell.Hyprland

Singleton {
    readonly property var screen: {
        const m = Hyprland.focusedMonitor;
        if (!m)
            return null;
        for (const s of Quickshell.screens) {
            if (s.name === m.name)
                return s;
        }
        return null;
    }
}
