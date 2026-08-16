#version 330

in vec2 fragCoord;
out vec4 fragColor;

uniform float bars[512];

uniform int bars_count;

uniform vec3 u_resolution;

uniform vec3 bg_color;
uniform vec3 fg_color;

void main()
{
    int bar = int(bars_count * fragCoord.x);

    float bar_y = 1.0 - abs((fragCoord.y - 0.5)) * 2.0;
    float y = (bars[bar]) * bar_y;

    float bar_x = (fragCoord.x - float(bar) / float(bars_count)) * bars_count;
    float bar_r = 1.0 - abs((bar_x - 0.5)) * 2;

    bar_r = bar_r * bar_r * 2;

    fragColor.r = fg_color.x * y * bar_r;
    fragColor.g = fg_color.y * y * bar_r;
    fragColor.b = fg_color.z * y * bar_r;
}
