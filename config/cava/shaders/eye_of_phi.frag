#version 330

#define SCALE 8.0
#define PI radians(180.0)
#define TAU (PI * 2.0)
#define CS(a) vec2(cos(a), sin(a))
#define PT(u, r) smoothstep(0.0, r, r - length(u))

in vec2 fragCoord;
out vec4 fragColor;

uniform float bars[512];

uniform int bars_count;
uniform float shader_time;
uniform int bar_width;
uniform int bar_spacing;

uniform vec3 u_resolution;

uniform vec3 bg_color;
uniform vec3 fg_color;

uniform int gradient_count;
uniform vec3 gradient_colors[8];

vec3 gm(vec3 c, float n, float t, float w, float d, bool i) {
  float g = min(abs(n), 1.0 / abs(n));
  float s = abs(sin(n * PI - t));
  if (i)
    s = min(s, abs(sin(PI / n + t)));
  return (1.0 - pow(abs(s), w)) * c * pow(g, d) * 6.0;
}

float ds(vec2 u, float e, float n, float w, float h, float ro) {
  float ur = length(u);
  float sr = pow(ur, e);
  float a = round(sr) * n * TAU;
  vec2 xy = CS(a + ro) * ur;
  float l = PT(u - xy, w);
  float s = mod(sr + 0.5, 1.0);
  s = min(s, 1.0 - s);
  return l * s * h;
}

void main() {
  float t = shader_time / PI * 2.0;
  vec4 m = vec4(0, 0, 0, 0);
  m.xy = m.xy * 2.0 / u_resolution.xy - 1.0;
  if (m.z > 0.0)
    t += m.y * SCALE;
  float z = (m.z > 0.0) ? pow(1.0 - abs(m.y), sign(m.y)) : 1.0;
  float e = (m.z > 0.0) ? pow(1.0 - abs(m.x), -sign(m.x))
                        : 1.0;
  float se = (m.z > 0.0) ? e * -sign(m.y) : 1.0;
  vec3 bg = vec3(0);

  float aa = 3.0;

  for (float j = 0.0; j < aa; j++)
    for (float k = 0.0; k < aa; k++) {
      vec3 c = vec3(0);
      vec2 o = vec2(j, k) / aa;
      vec2 uv = (fragCoord * u_resolution.xy - 0.5 * u_resolution.xy + o) /
                u_resolution.y * SCALE * z;
      if (m.z > 0.0)
        uv =
            exp(log(abs(uv)) * e) * sign(uv);

      float px = length(fwidth(uv));
      float x = uv.x;
      float y = uv.y;
      float l = length(uv);

      float mc = (x * x + y * y - 1.0) / y;
      float g = min(abs(mc), 1.0 / abs(mc));
      vec3 gold = vec3(1.0, 0.6, 0.0) * g * l;
      vec3 blue = vec3(0.3, 0.5, 0.9) * (1.0 - g);
      vec3 rgb = max(gold, blue);

      float w = 0.1;
      float d = 0.4;
      c = max(c, gm(rgb, mc, -t, w * bars[0], d, false));
      c = max(c, gm(rgb, abs(y / x) * sign(y), -t, w * bars[1], d,
                    false));
      c = max(c, gm(rgb, (x * x) / (y * y) * sign(y), -t, w * bars[2], d,
                    false));
      c = max(c, gm(rgb, (x * x) + (y * y), t, w * bars[3], d,
                    true));

      c += rgb * ds(uv, se, t / TAU, px * 2.0 * bars[4], 2.0, 0.0);
      c += rgb * ds(uv, se, t / TAU, px * 2.0 * bars[5], 2.0, PI);
      c +=
          rgb * ds(uv, -se, t / TAU, px * 2.0 * bars[6], 2.0, 0.0);
      c += rgb * ds(uv, -se, t / TAU, px * 2.0 * bars[7], 2.0, PI);
      c = max(c, 0.0);

      c += pow(max(1.0 - l, 0.0), 3.0 / z);

      if (m.z > 0.0)
      {
        vec2 xyg = abs(fract(uv + 0.5) - 0.5) / px;
        c.gb += 0.2 * (1.0 - min(min(xyg.x, xyg.y), 1.0));
      }
      bg += c;
    }
  bg /= aa * aa;
  bg *= sqrt(bg) * 1.5;

  fragColor = vec4(bg, 1.0);
}
