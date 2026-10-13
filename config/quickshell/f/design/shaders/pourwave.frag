#version 440

// Маска проявления панели: жидкость, льющаяся из острова.
//
// Граница идёт сверху вниз, но не ровной чертой: середина, куда льётся из
// острова, впереди, края догоняют, а по фронту бежит мелкая рябь. Белое —
// уже налито, прозрачное — ещё нет; мягкая полоса между ними — пена фронта.
//
// Собирается в pourwave.frag.qsb:
//   /usr/lib/qt6/bin/qsb --glsl 100es,120,150,300es --hlsl 50 --msl 12 \
//       -o pourwave.frag.qsb pourwave.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    // 0 — пусто, 1 — налито целиком.
    float pour;
    // Отношение ширины к высоте: рябь не растягивается вместе с панелью.
    float aspect;
};

void main() {
    vec2 p = qt_TexCoord0;

    float c = 2.0 * p.x - 1.0;
    // Горб и рябь живут только посреди налива: в начале и в конце фронт
    // ровный, поэтому пустая панель пуста, а налитая налита до последней
    // строки.
    float mid = sin(3.14159265 * clamp(pour, 0.0, 1.0));
    // Горб посередине — там струя из острова, края догоняют.
    float hump = 0.24 * (1.0 - c * c) * mid;
    // Рябь бежит по фронту.
    float k = 9.0 * max(aspect, 0.4);
    float ripple = (0.020 * sin(p.x * k + pour * 7.0)
                  + 0.011 * sin(p.x * k * 1.9 - pour * 11.0)) * mid;

    float feather = 0.16;
    float edge = -0.3 + pour * (1.3 + feather + 0.05) + hump + ripple;

    float a = 1.0 - smoothstep(edge - feather, edge, p.y);
    fragColor = vec4(a) * qt_Opacity;
}
