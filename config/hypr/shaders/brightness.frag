#version 320 es
precision highp float;

// Software brightness boost.
//
// Stopgap for a panel whose backlight cannot be controlled: acpi_backlight=native
// created /sys/class/backlight/nvidia_0, but writes to it are ignored and the
// value stays pinned, so the panel sits at its minimum. This cannot make the
// backlight brighter - it lifts the image instead, which helps read a dim
// screen but washes out dark tones.
//
// Remove with: hyprctl keyword decoration:screen_shader "[[EMPTY]]"

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float GAIN = 1.85;
const float LIFT = 0.045;

void main() {
    vec4 c = texture(tex, v_texcoord);

    // Lift the black point a little, then gain. Doing it in this order keeps
    // dark detail visible instead of crushing it against zero.
    vec3 rgb = (c.rgb + LIFT) * GAIN;

    fragColor = vec4(clamp(rgb, 0.0, 1.0), c.a);
}
