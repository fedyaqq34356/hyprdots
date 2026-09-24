import QtQuick
import "root:/design"

Item {
    id: sp

    visible: false

    property real target: 0
    property real value: 0
    property real velocity: 0

    property real response: Motion.isleOpenResponse
    property real damping:  Motion.isleOpenDamping
    property int  closeMs:  Motion.isleCloseMs
    property bool springBack: false
    property bool softClose: false

    property bool enabled: true

    property real epsilon: 0.0005

    readonly property bool running: tick.running

    property bool closing: false
    property real closeFrom: 0
    property real closeStart: 0

    onTargetChanged: sp.kick()

    onEnabledChanged: {
        if (sp.enabled)
            return;
        tick.running = false;
        sp.closing = false;
        sp.velocity = 0;
        sp.value = sp.target;
    }

    function settle(v) {
        tick.running = false;
        sp.closing = false;
        sp.velocity = 0;
        sp.target = v;
        sp.value = v;
    }

    function land() {
        tick.running = false;
        sp.closing = false;
        sp.velocity = 0;
        sp.value = sp.target;
    }

    function kick() {
        if (!sp.enabled) {
            sp.value = sp.target;
            return;
        }
        const down = sp.target < sp.value;
        sp.closing = down && !sp.springBack;
        if (sp.closing) {
            sp.closeFrom = sp.value;
            sp.closeStart = Date.now();
            sp.velocity = 0;
        }
        tick.running = true;
    }

    Timer {
        interval: 0
        running: true
        repeat: false
        onTriggered: if (sp.value !== sp.target) sp.kick()
    }

    FrameAnimation {
        id: tick
        running: false

        onTriggered: {
            if (sp.closing) {
                const k = Math.min(1, (Date.now() - sp.closeStart)
                                      / Math.max(1, sp.closeMs));
                const e = sp.softClose
                    ? (k < 0.5 ? 4 * k * k * k : 1 - Math.pow(-2 * k + 2, 3) / 2)
                    : 1 - Math.pow(1 - k, 3);
                sp.value = sp.closeFrom + (sp.target - sp.closeFrom) * e;
                if (k >= 1) {
                    sp.value = sp.target;
                    sp.closing = false;
                    running = false;
                }
                return;
            }

            const w = 2 * Math.PI / Math.max(0.05, sp.response);
            const z = sp.damping;

            const dt = Math.min(frameTime, 0.05);
            const steps = Math.max(1, Math.ceil(dt / 0.004));
            const h = dt / steps;

            for (let i = 0; i < steps; i++) {
                const a = -w * w * (sp.value - sp.target) - 2 * z * w * sp.velocity;
                sp.velocity += a * h;
                sp.value += sp.velocity * h;
            }

            if (Math.abs(sp.value - sp.target) < sp.epsilon
                && Math.abs(sp.velocity) < sp.epsilon * w) {
                sp.value = sp.target;
                sp.velocity = 0;
                running = false;
            }
        }
    }
}
