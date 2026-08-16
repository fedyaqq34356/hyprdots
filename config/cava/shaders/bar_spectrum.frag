#version 330

in vec2 fragCoord;
out vec4 fragColor;

uniform float bars[512];

uniform int bars_count;
uniform int bar_width;
uniform int bar_spacing;

uniform vec3 u_resolution;

uniform vec3 bg_color;
uniform vec3 fg_color;

uniform int gradient_count;
uniform vec3 gradient_colors[8];

uniform float shader_time;

uniform sampler2D inputTexture;

vec3 normalize_C(float y, vec3 col_1, vec3 col_2, float y_min, float y_max) {
    float yr = (y - y_min) / (y_max - y_min);
    return col_1 * (1.0 - yr) + col_2 * yr;
}

void main() {
    float x = u_resolution.x * fragCoord.x;
    int bar = int(bars_count * fragCoord.x);

    float bar_size = u_resolution.x / bars_count;

    float y = bars[bar];

    if (y * u_resolution.y < 1.0) {
        y = 1.0 / u_resolution.y;
    }

    if (y > fragCoord.y) {
        if (x > (bar + 1) * (bar_size)-bar_spacing) {
            fragColor = vec4(bg_color, 1.0);
        } else {
            if (gradient_count == 0) {
                fragColor = vec4(fg_color, 1.0);
            } else {
                int color = int((gradient_count - 1) * fragCoord.y);

                float y_min = color / (gradient_count - 1.0);
                float y_max = (color + 1.0) / (gradient_count - 1.0);

                fragColor = vec4(normalize_C(fragCoord.y, gradient_colors[color],
                                             gradient_colors[color + 1], y_min, y_max),
                                 1.0);
            }
        }
    } else {
        fragColor = vec4(bg_color, 1.0);
    }
}
