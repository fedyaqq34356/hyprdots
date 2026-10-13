#version 440

// Экран блокировки стекает в остров.
//
// Лист картинки уходит вверх, в остров, как жидкость в воронку: низ пустеет
// первым, отдельные струи отстают и висят каплями, а у самого острова лист
// сжимается вбок в узкую шейку и темнеет — он становится островом. Под ним
// открывается рабочий стол.
//
// Собирается в melt.frag.qsb:
//   /usr/lib/qt6/bin/qsb --glsl 100es,120,150,300es --hlsl 50 --msl 12 \
//       -o melt.frag.qsb melt.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D source;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    // 0 — экран на месте, 1 — весь в острове.
    float progress;
    // Куда стекать (доли экрана) и отношение ширины к высоте.
    vec2 sink;
    float aspect;
    vec4 rimColor;
};

void main() {
    vec2 uv = qt_TexCoord0;
    float e = clamp(progress, 0.0, 1.0);
    float ee = e * e * (3.0 - 2.0 * e);

    vec2 q = vec2(uv.x * aspect, uv.y);
    vec2 t = vec2(sink.x * aspect, sink.y);
    float dx = q.x - t.x;
    float dy = max(q.y - t.y, 0.0);

    // Струи: узкие, в двух частотах, — капли, а не волна.
    float nx = q.x;
    float drip = max(pow(0.5 + 0.5 * sin(nx * 13.0 + 1.7), 8.0),
                     pow(0.5 + 0.5 * sin(nx * 7.1 - 0.4), 10.0));

    // Лист уходит вверх; отстаёт только его хвост.
    float lift = ee * 1.08;
    float sy0 = dy + lift;
    float tail = clamp((sy0 - (1.0 - t.y) + 0.30) / 0.30, 0.0, 1.0);
    float sy = sy0 - 0.20 * drip * tail * sin(3.14159265 * clamp(ee * 1.3, 0.0, 1.0));

    // Воронка: у острова лист сжат вбок в шейку.
    float en = pow(ee, 1.6);
    float neck = 1.0 + en * 2.6 / (dy / 0.22 + 0.12) + en * 1.2;
    float sx = dx * neck;

    vec2 src = vec2((t.x + sx) / aspect, t.y + sy);

    float edge = min(min(src.x, 1.0 - src.x), min(src.y, 1.0 - src.y));
    float aa = max(fwidth(edge), 1e-4);
    float a = smoothstep(-aa, aa, edge);

    vec3 col = texture(source, clamp(src, 0.0, 1.0)).rgb;
    // У острова — в черноту.
    col *= (1.0 - 0.92 * exp(-dy / 0.10) * clamp(ee * 3.0, 0.0, 1.0)) * (1.0 - 0.25 * ee);
    // Тонкий свет по кромке листа, пока он течёт.
    float rim = (1.0 - smoothstep(0.0, aa * 3.0, abs(edge - aa * 1.5))) * step(0.02, ee);
    col += rimColor.rgb * rim * 0.35;

    fragColor = vec4(col * a, a) * qt_Opacity;
}
