#version 440

// Вода в острове: таймер, громкость, зарядка.
//
// Раньше её рисовала векторная фигура: каждый кадр JavaScript собирал
// гребень из двух десятков точек, а Shape заново раскраивал его на
// треугольники — на процессоре, в главном потоке. Здесь та же картинка
// считается на видеокарте: поверхность — сумма двух синусов, под ней
// градиент, по самой поверхности — светлая кромка.
//
// axis 0 — вода стоит снизу (уровень — доля высоты), 1 — наливается слева
// (уровень — доля ширины, фронт волнится по вертикали).
//
// Собирается в water.frag.qsb:
//   /usr/lib/qt6/bin/qsb --glsl 100es,120,150,300es --hlsl 50 --msl 12 \
//       -o water.frag.qsb water.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    vec2 size;
    float axis;
    // Положение поверхности в пикселях от «дна» (снизу или слева).
    float level;

    // Две волны: спокойная и быстрая (рябь, голос, жар).
    float phase1;
    float amp1;
    float waves1;
    float phase2;
    float amp2;
    float waves2;

    // Градиент тела: у поверхности и у дна. Цвета приходят непрозрачными,
    // прозрачность — отдельно (ShaderEffect отдаёт предумноженные цвета).
    vec4 nearColor;
    float nearAlpha;
    vec4 farColor;
    float farAlpha;

    vec4 crestColor;
    float crestAlpha;
    float crestWidth;
};

void main() {
    vec2 p = qt_TexCoord0 * size;

    // Вдоль поверхности (u, 0..1) и поперёк неё (d, пиксели от дна).
    float u = axis < 0.5 ? qt_TexCoord0.x : qt_TexCoord0.y;
    float d = axis < 0.5 ? size.y - p.y : p.x;

    float surf = level
        + amp1 * sin(phase1 + u * 6.2831853 * waves1)
        + amp2 * sin(phase2 + u * 6.2831853 * waves2);

    // Расстояние до поверхности: внутри воды отрицательное.
    float dist = d - surf;
    float aa = max(fwidth(dist), 0.0001);

    float inside = 1.0 - smoothstep(-aa, aa, dist);

    // Градиент: у поверхности nearColor, к дну — farColor.
    float depth = clamp(-dist / max(surf, 1.0), 0.0, 1.0);
    vec3 body = mix(nearColor.rgb, farColor.rgb, depth);
    float bodyA = mix(nearAlpha, farAlpha, depth) * inside;

    // Кромка по самой поверхности.
    float crest = 1.0 - smoothstep(crestWidth * 0.5 - aa, crestWidth * 0.5 + aa, abs(dist));
    crest *= crestAlpha * step(0.5, surf);

    vec3 rgb = body * bodyA + crestColor.rgb * crest * (1.0 - bodyA);
    float a = bodyA + crest * (1.0 - bodyA);
    // Кромка поверх воды светит сильнее, чем поверх пустоты.
    rgb = mix(rgb, crestColor.rgb * max(a, 1e-4), crest * bodyA);

    fragColor = vec4(rgb, a) * qt_Opacity;
}
