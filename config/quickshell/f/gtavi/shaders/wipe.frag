#version 440
// Diagonal wipe with a soft edge: the incoming image is revealed from the
// left as `progress` goes 0 → 1, through a feathered band `softness` wide.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float progress;
    float softness;
    float slant;
};
layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    float d = (qt_TexCoord0.x + slant * (1.0 - qt_TexCoord0.y)) / (1.0 + slant);
    float edge = progress * (1.0 + softness) - softness;
    float a = 1.0 - smoothstep(edge, edge + softness, d);
    fragColor = c * a * qt_Opacity;
}
