#version 440

// Края бегущей строки растворяются, а не обрезаются.
//
// Строка, упёршаяся в край, режется по букве — и читается обрубком. Здесь
// альфа просто уходит в ноль на ширине fadeL слева и fadeR справа (в долях
// ширины): буква не обрывается, а тает. Каждая сторона своя — левый край
// тает только пока строка едет, правый — пока за ним ещё есть текст.
//
// Собирается в edgefade.frag.qsb:
//   /usr/lib/qt6/bin/qsb --glsl 100es,120,150,300es --hlsl 50 --msl 12 \
//       -o edgefade.frag.qsb edgefade.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float fadeL;
    float fadeR;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    float x = qt_TexCoord0.x;
    float l = fadeL > 0.0001 ? smoothstep(0.0, fadeL, x) : 1.0;
    float r = fadeR > 0.0001 ? smoothstep(0.0, fadeR, 1.0 - x) : 1.0;
    fragColor = texture(source, qt_TexCoord0) * (l * r * qt_Opacity);
}
