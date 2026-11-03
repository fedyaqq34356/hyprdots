#version 440

// Живая сфера системного монитора.
//
// Чёрная ферро-капля: по кромке по шипу на ядро (длина = загрузка ядра),
// у видеокарты шипов нет — кромка колышется тем сильнее, чем выше нагрузка.
// Внутри жидкость: уровень = занятая память, волны = загрузка,
// цвет от акцента к жару по температуре, при жаре со дна идут пузырьки.
// flash — блик-полоса поперёк сферы при резком скачке нагрузки.
//
//   /usr/lib/qt6/bin/qsb --glsl 100es,120,150,300es --hlsl 50 --msl 12 \
//       -o orb.frag.qsb orb.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    vec2 size;
    float t;
    float grow;
    float level;
    float load;
    float heat;
    float flash;
    float spikes;
    float ncores;

    vec4 c0;
    vec4 c1;
    vec4 c2;
    vec4 c3;

    vec4 tint;
    vec4 hot;
};

const float PI = 3.14159265;

float core(int i) {
    vec4 v = i < 4 ? c0 : (i < 8 ? c1 : (i < 12 ? c2 : c3));
    int k = i - (i / 4) * 4;
    return k == 0 ? v.x : (k == 1 ? v.y : (k == 2 ? v.z : v.w));
}

float hash(float n) { return fract(sin(n * 12.9898) * 43758.5453); }

void main() {
    vec2 p = qt_TexCoord0 * size;
    vec2 c = size * 0.5;
    float m = min(size.x, size.y);
    float R = m * 0.30 * grow;
    vec2 d = p - c;
    float r = length(d);
    float a = atan(d.y, d.x);

    // Кромка: дыхание + рябь от нагрузки.
    float breathe = 1.0 + 0.012 * sin(t * 1.3);
    float wob = (0.006 + 0.05 * load * (ncores < 0.5 ? 1.0 : 0.35))
              * (sin(3.0 * a + t * 1.1) * 0.6 + sin(5.0 * a - t * 1.7) * 0.4);
    float edge = R * (breathe + wob);

    // Ферро-шипы: конусы с вогнутыми боками, медленно вращаются.
    float sp = 0.0;
    int n = int(ncores + 0.5);
    if (n > 0) {
        float step_ = 2.0 * PI / float(n);
        float w = step_ * 0.62;
        for (int i = 0; i < 16; i++) {
            if (i >= n) break;
            float th = float(i) * step_ - PI * 0.5 + t * 0.06;
            float da = abs(mod(a - th + PI, 2.0 * PI) - PI);
            float x = clamp(1.0 - da / w, 0.0, 1.0);
            float h = (0.08 + 0.92 * core(i)) * R * 0.55 * spikes;
            h *= 1.0 + 0.06 * sin(t * 2.3 + float(i) * 1.7);
            sp = max(sp, h * x * x * x);
        }
    }
    float sd = r - (edge + sp);
    float aa = max(fwidth(sd), 0.0001) * 1.2;
    float body = 1.0 - smoothstep(-aa, aa, sd);

    vec3 tone = mix(tint.rgb, hot.rgb, smoothstep(0.35, 0.95, heat));

    // Ореол снаружи.
    float halo = exp(-max(sd, 0.0) / (m * 0.06)) * (0.10 + 0.25 * load) * (1.0 - body)
               * (1.0 - smoothstep(m * 0.30, m * 0.49, r));

    // Тело — глянцевый чёрный.
    vec3 col = vec3(0.012);

    // Жидкость внутри круга (без шипов).
    float inner = R * breathe * 0.93;
    float ri = r - inner;
    float aai = max(fwidth(ri), 0.0001);
    float inCircle = 1.0 - smoothstep(-aai, aai, ri);
    float speed = 0.8 + load * 3.2;
    float amp = (1.2 + load * 7.0) * grow;
    float u = d.x / max(inner, 1.0);
    float surf = c.y + inner - 2.0 * inner * level
               + amp * sin(u * 3.2 + t * speed)
               + amp * 0.45 * sin(u * 7.1 - t * speed * 1.6);
    float ds = p.y - surf;
    float aas = max(fwidth(ds), 0.0001);
    float wet = smoothstep(-aas, aas, ds) * inCircle;
    float depth = clamp(ds / max(inner * 2.0, 1.0), 0.0, 1.0);
    vec3 liquid = mix(tone * 1.15, tone * 0.32, pow(depth, 0.7));
    col = mix(col, liquid, wet * 0.92);
    float crest = (1.0 - smoothstep(0.0, 1.6, abs(ds))) * inCircle * step(0.002, level);
    col += mix(tone, vec3(1.0), 0.5) * crest * 0.75;

    // Пузырьки при жаре.
    float boil = smoothstep(0.55, 0.85, heat);
    if (boil > 0.0) {
        for (int k = 0; k < 9; k++) {
            float fk = float(k);
            float life = fract(t * (0.22 + 0.18 * hash(fk + 3.0)) + hash(fk));
            vec2 bp = vec2(c.x + (hash(fk + 7.0) - 0.5) * inner * 1.3
                               + 3.0 * sin(t * 2.0 + fk),
                           c.y + inner - life * (c.y + inner - surf));
            float br = 1.2 + 1.8 * hash(fk + 11.0);
            float ring = 1.0 - smoothstep(0.0, 1.0, abs(length(p - bp) - br));
            col += vec3(1.0) * ring * wet * boil * 0.45 * sin(life * PI);
        }
    }

    // Подсветка кромки изнутри (ферро-блеск) — цвет жидкости.
    float rim = exp(sd / (m * 0.018)) * body;
    col += tone * rim * (0.55 + 0.6 * load);
    // Верхний-левый блик.
    vec2 hl = (p - (c + vec2(-0.38, -0.42) * R)) / (R * vec2(0.34, 0.20));
    col += vec3(1.0) * exp(-dot(hl, hl) * 2.2) * 0.10 * body;

    // Блик-полоса на скачке.
    if (flash > 0.0) {
        float band = (d.x + d.y) / (R * 2.8) - mix(-1.1, 1.1, flash);
        col += mix(tone, vec3(1.0), 0.6) * exp(-band * band * 40.0) * sin(flash * PI) * 0.6 * body;
    }

    vec3 rgb = col * body + tone * halo;
    float alpha = body + halo;
    fragColor = vec4(rgb, alpha) * qt_Opacity;
}
