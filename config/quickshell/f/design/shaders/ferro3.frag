#version 440

// Феррожидкость: чёрная ртутная капля с шипами.
//
// Тело — купол, шипы — конусы по кругу, высота каждого своя и живёт со
// временем, а общий рост задают музыка (`amp`, `bass`). Нормаль берётся из
// карты высот тремя выборками, свет — отражение двух софтбоксов и цветного
// контрового: настоящая феррожидкость сама почти не светит, её видно по
// отражениям. Рядом с островом капля сливается с его пилюлей (`neck`) —
// smooth-min двух полей расстояния, — и шейка рвётся сама, когда капля
// отходит дальше радиуса слияния.
//
// Собирается в ferro3.frag.qsb:
//   /usr/lib/qt6/bin/qsb --glsl 100es,120,150,300es --hlsl 50 --msl 12 \
//       -o ferro3.frag.qsb ferro3.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    vec2 size;
    // Центр и радиус тела, в пикселях элемента.
    vec2 center;
    float radius;
    // Пилюля острова: центр и полный размер.
    vec2 isle;
    vec2 isleSize;
    // 0 — без слияния, 1 — полное.
    float neck;
    // Рост шипов (0..1) и удар баса.
    float amp;
    float bass;
    float time;
    vec4 tone;
    float shadowAlpha;
    float isleHide;
    // Цвет обложки в игре: 0 — тишина, 1 — удар. Тон приходит в `tone`.
    float glow;
};

const float PI = 3.14159265;
const float SPIKES = 19.0;

float smin(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (b - a) / k, 0.0, 1.0);
    return mix(b, a, h) - k * h * (1.0 - h);
}

float sdBox(vec2 p, vec2 c, vec2 hs, float r) {
    vec2 q = abs(p - c) - hs + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// r — расстояние до центра, rs — край в этом направлении, f — место внутри
// шипа (0.5 — его ось), sp — высота шипа.
void shape(vec2 p, out float r, out float rs, out float a, out float f, out float sp) {
    vec2 d = p - center;
    r = length(d);
    a = atan(d.y, d.x);
    float ph = a * SPIKES / (2.0 * PI) + time * 0.04;
    float cell = floor(ph);
    f = ph - cell;
    float hv = 0.6 + 0.4 * sin(cell * 12.9898 + time * 1.3) * cos(cell * 5.3 - time * 0.7);
    float cone = clamp(1.0 - abs(f - 0.5) * 2.0, 0.0, 1.0);
    cone = cone * cone * (3.0 - 2.0 * cone);
    cone = pow(cone, 1.6);
    float wob = radius * (0.035 * sin(3.0 * a + time * 0.8) + 0.025 * sin(5.0 * a - time * 1.1));
    sp = radius * 0.7 * amp * hv * (0.55 + 0.6 * bass) * cone;
    rs = radius + wob + sp;
}

float height(vec2 p) {
    float r, rs, a, f, sp;
    shape(p, r, rs, a, f, sp);
    float q = clamp(r / radius, 0.0, 1.0);
    float hb = sqrt(max(0.0, 1.0 - q * q)) * radius * 0.6;
    float ramp = clamp((r - radius * 0.45) / (radius * 0.4), 0.0, 1.0);
    ramp = ramp * ramp * (3.0 - 2.0 * ramp);
    float hs = max(rs - r, 0.0) * 0.85 * ramp;
    float k = 6.0;
    float hh = max(hb, hs);
    return hh + log(exp((hb - hh) / k) + exp((hs - hh) / k)) * k * 0.5;
}

float box(vec3 rv, vec3 dir, float size, float sharp) {
    float c = cos(size);
    return pow(clamp((dot(rv, normalize(dir)) - c) / (1.0 - c), 0.0, 1.0), sharp);
}

void main() {
    vec2 p = qt_TexCoord0 * size;

    float r, rs, a, f, sp;
    shape(p, r, rs, a, f, sp);
    float dm = r - rs;
    float db = sdBox(p, isle, isleSize * 0.5, isleSize.y * 0.5);
    float dd = neck > 0.001 ? smin(dm, db, 70.0 * neck) : dm;

    float aa = max(fwidth(dd), 0.75);
    float alpha = clamp(0.5 - dd / (aa * 1.4), 0.0, 1.0);
    // Внутри живой пилюли — её собственный рисунок.
    alpha *= 1.0 - isleHide * clamp(0.5 - (db + 1.0) / 1.2, 0.0, 1.0);

    float h = height(p);
    float hx = height(p + vec2(1.0, 0.0));
    float hy = height(p + vec2(0.0, 1.0));
    vec3 n = normalize(vec3(-(hx - h), -(hy - h), 1.0));
    vec3 rv = vec3(2.0 * n.z * n.x, 2.0 * n.z * n.y, 2.0 * n.z * n.z - 1.0);

    vec3 tc = tone.rgb;
    vec3 env = box(rv, vec3(-0.35, -0.45, 0.82), 0.42, 1.2) * vec3(1.1);
    env += box(rv, vec3(-0.6, -0.5, 0.62), 0.18, 1.0) * vec3(1.6);
    env += box(rv, vec3(0.6, 0.55, 0.55), 0.6, 1.6) * tc * 0.9;
    env += box(rv, vec3(0.0, -0.9, 0.4), 0.7, 3.0) * vec3(0.55, 0.6, 0.75) * 0.35;
    float fres = 0.04 + 0.96 * pow(1.0 - clamp(n.z, 0.0, 1.0), 5.0);
    vec3 col = vec3(0.008, 0.008, 0.012) + env * (0.25 + 0.75 * fres);

    // Контровой свет по краю силуэта.
    col += clamp(1.0 - abs(dd + 1.2) / 2.0, 0.0, 1.0) * tc * 0.22;

    // Блики по рёбрам шипов: с подветренной стороны — цветом.
    float ridge = pow(clamp(1.0 - abs(f - 0.5) * 2.0, 0.0, 1.0), 10.0)
                * clamp((r - radius * 0.7) / (radius * 0.3), 0.0, 1.0)
                * step(1.0, sp);
    float lit = 0.5 + 0.5 * cos(a + 2.3);
    float tipFade = clamp((rs - r) / (radius * 0.5), 0.0, 1.0);
    col += ridge * tipFade * (lit * vec3(0.9, 0.9, 0.95) * 0.55 + (1.0 - lit) * tc * 0.45);

    // Цвет обложки внутри: снизу, из глубины, как свет сквозь ртуть, —
    // и по краю. В тишине — намёк, на ударе — разгорается.
    float g = 0.35 + 0.65 * glow;
    float depth = clamp((p.y - center.y) / radius * 0.5 + 0.5, 0.0, 1.0);
    col += tc * fres * 0.30 * g;
    col += tc * pow(depth, 3.0) * (1.0 - fres) * 0.10 * g * step(dm, 0.0);
    col += clamp(1.0 - abs(dd + 1.2) / 2.0, 0.0, 1.0) * tc * 0.25 * g;

    // Мягкая тень вокруг — капля лежит над экраном, а не вырезана в нём.
    float sh = exp(-max(dd, 0.0) / 30.0) * shadowAlpha;
    // Аура цвета обложки: дышит басом.
    float halo = exp(-max(dd, 0.0) / (radius * 0.55)) * (0.10 + 0.32 * glow) * shadowAlpha * 2.0;

    vec4 body = vec4(col * alpha, alpha);
    // Поле шейдера — прямоугольник вокруг капли: свет и тень гаснут к его
    // краям, иначе на экране видна рамка.
    float border = min(min(p.x, p.y), min(size.x - p.x, size.y - p.y));
    float edgeFade = smoothstep(0.0, radius * 0.9, border);
    vec4 outer = vec4(tc * halo, sh + halo * 0.6) * (1.0 - alpha) * edgeFade;
    fragColor = (body + outer) * qt_Opacity;
}
