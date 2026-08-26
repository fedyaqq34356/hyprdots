#version 320 es
precision highp float;

in vec2 v_texcoord;
uniform sampler2D tex;
out vec4 fragColor;

const float GAIN = 1.85;
const float LIFT = 0.045;

void main() {
    vec4 c = texture(tex, v_texcoord);

    vec3 rgb = (c.rgb + LIFT) * GAIN;

    fragColor = vec4(clamp(rgb, 0.0, 1.0), c.a);
}
