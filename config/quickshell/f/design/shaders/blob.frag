#version 440

// Слияние островков бара в один жидкий силуэт.
//
// Каждый островок — signed distance field скруглённого прямоугольника.
// Соседние поля сливаются через circular smin: фаска между ними — настоящая
// дуга окружности радиуса fuse, касательная к обеим поверхностям, а не
// полиномиальное приближение. Островки сближаются — между ними натягивается
// перемычка; расходятся — она рвётся.
//
// Данные о прямоугольниках приходят отдельными uniform'ами r0..r11, а не
// массивом: ShaderEffect надёжно отображает на QML только скаляры и векторы.
// Двенадцати островков на зону хватает с запасом.
//
// Собирается в blob.frag.qsb:
//   /usr/lib/qt6/bin/qsb --glsl 100es,120,150,300es --hlsl 50 --msl 12 \
//       -o blob.frag.qsb blob.frag

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;

    // Размер эффекта в пикселях: qt_TexCoord0 нормализован, а SDF считается
    // в пикселях, иначе фаска растягивалась бы вместе с баром.
    vec2 size;

    // Радиус фаски между соседними островками.
    float fuse;
    // Радиус собственных углов островка.
    float corner;
    // Толщина обводки по краю силуэта, 0 — без обводки.
    float stroke;
    // Сила подсветки наведённого островка, 0..1.
    float hoverMix;

    // Цвета приходят непрозрачными, прозрачность — отдельными числами:
    // ShaderEffect отдаёт QColor с предумноженной альфой, и смешивать такие
    // цвета между собой нельзя.
    vec4 fillColor;
    vec4 hoverColor;
    vec4 strokeColor;
    float fillAlpha;
    float hoverAlpha;
    float strokeAlpha;

    int count;
    int hoverIndex;

    // cx, cy, hw, hh в пикселях.
    vec4 r0;
    vec4 r1;
    vec4 r2;
    vec4 r3;
    vec4 r4;
    vec4 r5;
    vec4 r6;
    vec4 r7;
    vec4 r8;
    vec4 r9;
    vec4 r10;
    vec4 r11;
};

float sdRoundBox(vec2 p, vec4 rect) {
    // Радиус угла не может превышать половину меньшей стороны, иначе поле
    // выворачивается наизнанку на узких островках.
    float rad = min(corner, min(rect.z, rect.w));
    vec2 d = abs(p - rect.xy) - rect.zw + vec2(rad);
    return length(max(d, vec2(0.0))) + min(max(d.x, d.y), 0.0) - rad;
}

// Circular smooth min. Отклоняется от min(a, b) только там, где оба поля
// ближе fuse — то есть ровно в углу стыка, а не во всей полосе |a - b| < k,
// как у кубического варианта. Глубина слияния при a == b: (sqrt(2) - 1) * k.
float smin(float a, float b, float k) {
    return max(k, min(a, b)) - length(max(vec2(k) - vec2(a, b), vec2(0.0)));
}

void main() {
    vec2 p = qt_TexCoord0 * size;

    vec4 R[12] = vec4[12](r0, r1, r2, r3, r4, r5, r6, r7, r8, r9, r10, r11);

    // 1e9 — нейтральный элемент для smin: сливаться не с чем, остаётся сам
    // прямоугольник.
    float d = 1e9;
    float dHover = 1e9;

    for (int i = 0; i < 12; i++) {
        if (i >= count)
            break;

        float di = sdRoundBox(p, R[i]);
        d = smin(d, di, max(fuse, 0.001));

        if (i == hoverIndex)
            dHover = di;
    }

    // Сглаживание по производной поля: у SDF она равна единице, поэтому
    // ширина перехода выходит ровно в один пиксель на любом масштабе.
    float aa = max(fwidth(d), 0.0001);

    float inside = 1.0 - smoothstep(-aa, aa, d);
    if (inside <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }

    // Подсветка не обрезается по границе островка, а гаснет вокруг него:
    // иначе на перемычке между наведённым и соседним был бы шов.
    float falloff = fuse * 3.0 + 12.0;
    float hv = (hoverIndex >= 0)
        ? (1.0 - smoothstep(0.0, falloff, dHover)) * hoverMix
        : 0.0;

    vec3 rgb = mix(fillColor.rgb, hoverColor.rgb, hv);
    float alpha = mix(fillAlpha, hoverAlpha, hv);

    // Обводка идёт по самому силуэту, а не по каждому прямоугольнику, —
    // поэтому она обходит и перемычки.
    if (stroke > 0.0) {
        float band = smoothstep(-stroke - aa, -stroke + aa, d);
        rgb = mix(rgb, strokeColor.rgb, band * strokeAlpha);
        alpha = mix(alpha, max(alpha, strokeAlpha), band);
    }

    alpha *= inside * qt_Opacity;
    fragColor = vec4(rgb * alpha, alpha);
}
