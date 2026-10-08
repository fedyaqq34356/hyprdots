#version 440
// Rockstar's GTA VI text gradient, as the site writes it in CSS:
//   radial-gradient(62.79% 100% at 50% 0%, c0 0%, c1 50%, c2 100%)
// An ellipse centred on the top edge, 62.79% of the width wide and the full
// height tall. The item's alpha is the mask.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 c0;
    vec4 c1;
    vec4 c2;
    vec2 radius;
    vec2 center;
    float shift;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 s = texture(source, qt_TexCoord0);
    vec2 p = (qt_TexCoord0 - center - vec2(shift, 0.0)) / radius;
    float d = clamp(length(p), 0.0, 1.0);
    vec3 col = d < 0.5 ? mix(c0.rgb, c1.rgb, d / 0.5)
                       : mix(c1.rgb, c2.rgb, (d - 0.5) / 0.5);
    fragColor = vec4(col, 1.0) * s.a * qt_Opacity;
}
