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

vec3 normalize_C(float y,vec3 col_1, vec3 col_2, float y_min, float y_max)
{
    float yr = (y - y_min) / (y_max - y_min);
    return col_1 * (1.0 - yr) + col_2 * yr;
}

void main()
{
    float x = u_resolution.x * fragCoord.x;
    int bar = int(bars_count * fragCoord.x);

    float bar_size = u_resolution.x / bars_count;

    float y =  min(bars[bar] * 4.0, 1.0);

    if (y * u_resolution.y < 1.0)
    {
      y = 1.0 / u_resolution.y;
    }

    vec4 bar_color;

    if (gradient_count == 0)
    {
        bar_color = vec4(fg_color,1.0);
    }
    else
    {
        int color = int((gradient_count - 1) * y);

        float y_min = float(color) / (gradient_count - 1.0);
        float y_max = float(color + 1) / (gradient_count - 1.0);

        bar_color = vec4(normalize_C(y, gradient_colors[color], gradient_colors[color + 1], y_min, y_max), 1.0);
    }

    if (y > fragCoord.y)
    {
        if (x > (bar + 1) * (bar_size) - bar_spacing)
        {
            fragColor = vec4(bg_color,1.0);
        }
        else
        {
            fragColor = bar_color;
        }
    }
    else
    {
        fragColor = vec4(bg_color,1.0);
    }
}
