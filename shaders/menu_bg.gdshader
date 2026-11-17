shader_type canvas_item;

uniform vec4 c1 : source_color = vec4(0.05, 0.08, 0.35, 1.0);
uniform vec4 c2 : source_color = vec4(0.95, 0.30, 0.55, 1.0);

void fragment() {
    vec2 uv = UV;
    float g = clamp(uv.y + 0.10 * sin(uv.x * 3.0 + TIME * 0.7), 0.0, 1.0);
    vec3 col = mix(c1.rgb, c2.rgb, g);
    vec2 p = uv - vec2(0.5);
    float a = atan(p.y, p.x);
    float r = length(p);
    float rays = smoothstep(0.55, 1.0, sin(a * 18.0 + TIME * 0.6));
    col += rays * 0.14 * r;
    col += 0.08 * smoothstep(0.35, 0.0, r);
    COLOR = vec4(col, 1.0);
}
