#version 440

// Новая обоина выливается из острова.
//
// Фронт — не круг, а живая кромка: три синуса по углу, которые гуляют, пока
// жидкость течёт, и успокаиваются к концу. За фронтом картинка видна сквозь
// толщу: у кромки она выпирает линзой и по ней бегут затухающие кольца. По
// самой кромке — мениск, светлая нить, ярче с той стороны, где свет; снаружи —
// тонкая тень и отсвет цвета темы: у налитого есть толщина.
//
// Собирается в wallpour2.frag.qsb:
//   /usr/lib/qt6/bin/qsb --glsl 100es,120,150,300es --hlsl 50 --msl 12 \
//       -o wallpour2.frag.qsb wallpour2.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    vec2 size;
    // Размер загруженной картинки: обрезка под экран — здесь.
    vec2 picSize;
    // Откуда льётся, в пикселях.
    vec2 sink;
    float progress;
    vec4 tone;
};

vec3 pick(vec2 p) {
    float s = max(size.x / picSize.x, size.y / picSize.y);
    vec2 uv = ((p - size * 0.5) / s + picSize * 0.5) / picSize;
    return texture(source, clamp(uv, 0.0, 1.0)).rgb;
}

void main() {
    vec2 p = qt_TexCoord0 * size;
    float e = clamp(progress, 0.0, 1.0);
    float S = size.y / 1080.0;

    vec2 dv = p - sink;
    float r = length(dv);
    float a = atan(dv.y, dv.x);
    vec2 n = dv / max(r, 1e-3);

    float rmax = length(vec2(max(sink.x, size.x - sink.x), size.y - sink.y)) + 80.0 * S;
    float ee = 1.0 - pow(1.0 - e, 1.7);
    float R = ee * rmax;
    float mid = sin(3.14159265 * e);

    float wob = (sin(a * 5.0 + e * 7.0) * 0.55
               + sin(a * 9.0 - e * 11.0 + 1.3) * 0.30
               + sin(a * 2.0 + e * 3.0) * 0.60)
              * 28.0 * S * mid * clamp(R / (120.0 * S), 0.0, 1.0);
    float d = r - (R + wob);

    float inside = step(d, 0.0);
    float thick = exp(min(d, 0.0) / (34.0 * S)) * inside;
    float ripple = sin((r - R) / (9.0 * S) - e * 30.0)
                 * exp(min(d, 0.0) / (90.0 * S)) * inside * 4.0 * S * mid;
    vec3 col = pick(p - n * (thick * 22.0 * S + ripple));

    float men = exp(-pow((d + 3.0 * S) / (2.2 * S), 2.0));
    float light = 0.5 + 0.5 * cos(a + 2.2);
    col += men * (vec3(0.55) * light + tone.rgb * 0.35);
    col = col * (1.0 - 0.18 * thick) + thick * 0.06;

    float aa = max(fwidth(d), 0.8);
    float alpha = clamp(0.5 - d / aa, 0.0, 1.0);

    // Снаружи: тень толщины и отсвет.
    float band = exp(-max(d, 0.0) / (10.0 * S)) * (1.0 - alpha) * step(0.001, e) * (1.0 - smoothstep(0.85, 1.0, e));
    vec4 outer = vec4(tone.rgb * 0.08 * band, 0.35 * band);

    fragColor = (vec4(col * alpha, alpha) + outer * (1.0 - alpha)) * qt_Opacity;
}
