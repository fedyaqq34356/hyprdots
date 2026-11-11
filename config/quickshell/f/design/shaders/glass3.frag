#version 440

// Стекло блокировки оттаивает.
//
// Экран блокировки — размытое матовое стекло. После входа оно тает от центра:
// неровная кромка, как у тающего инея, расходится к краям, и за ней
// проступает чёткий рабочий стол. По самой кромке стекло чуть преломляет
// картинку и ловит тонкий блик; всё, что ещё не оттаяло, понемногу редеет.
//
// Собирается в glass3.frag.qsb:
//   /usr/lib/qt6/bin/qsb --glsl 100es,120,150,300es --hlsl 50 --msl 12 \
//       -o glass3.frag.qsb glass.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    // 0 — стекло целое, 1 — растаяло.
    float progress;
    // Откуда тает (доли экрана) и отношение ширины к высоте.
    vec2 origin;
    float aspect;
    vec4 rimColor;
};

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float vnoise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    return 0.55 * vnoise(p) + 0.30 * vnoise(p * 2.13 + 7.1) + 0.15 * vnoise(p * 4.37 - 3.3);
}

void main() {
    vec2 uv = qt_TexCoord0;
    float e = clamp(progress, 0.0, 1.0);
    // Трогается сразу, к краям замедляется: площадь растёт как r², поэтому
    // радиус идёт с выдохом, иначе к концу кажется, что всё ускоряется.
    float ee = mix(e, sin(e * 1.5707963), 0.6);

    vec2 q = vec2(uv.x * aspect, uv.y);
    vec2 o = vec2(origin.x * aspect, origin.y);
    vec2 v = q - o;
    float d = length(v);
    vec2 dir = v / max(d, 1e-4);

    // Неровная кромка инея, медленно живёт по ходу таяния.
    float n = fbm(q * 3.2 + vec2(ee * 0.3, -ee * 0.2)) - 0.5;
    float far = length(vec2(max(o.x, aspect - o.x), max(o.y, 1.0 - o.y)));
    float r = ee * (far + 0.20) - 0.14;
    float w = 0.04 + 0.05 * ee;
    float f = d + n * (0.10 + 0.06 * ee) - r;

    // Стекло: 0 — оттаяло, 1 — ещё матовое.
    float glass = smoothstep(-w, w, f);

    // Кромка: линза и блик.
    float band = exp(-(f * f) / (w * w * 0.9));
    vec2 src = uv - vec2(dir.x / aspect, dir.y) * band * 0.022 * (1.0 - e * 0.5);
    vec3 col = texture(source, clamp(src, 0.0, 1.0)).rgb;
    vec3 glint = mix(vec3(1.0), rimColor.rgb, 0.35);
    col += glint * band * 0.10 * glass;

    // Не оттаявшее редеет к концу, чтобы последние края не обрывались.
    float thin = 1.0 - 0.35 * smoothstep(0.55, 1.0, e);
    float a = glass * thin * (1.0 - smoothstep(0.92, 1.0, e));

    fragColor = vec4(col * a, a) * qt_Opacity;
}
