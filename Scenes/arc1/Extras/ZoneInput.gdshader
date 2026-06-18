shader_type canvas_item;

uniform vec4 color: source_color = vec4(0.29, 0.62, 1.0, 1.0);
uniform float scan_speed: hint_range(0.0, 2.0) = 0.4;
uniform float line_alpha: hint_range(0.0, 0.2) = 0.03;
uniform float line_gap: hint_range(1.0, 20.0) = 6.0;
uniform float band_alpha: hint_range(0.0, 0.5) = 0.12;
uniform float fresnel_alpha: hint_range(0.0, 0.5) = 0.18;
uniform float fresnel_size: hint_range(0.01, 0.3) = 0.08;
uniform float glitch_threshold: hint_range(0.9, 1.0) = 0.997;

float random(float x) {
    return fract(sin(x * 12.9898 + 78.233) * 43758.5453);
}

void fragment() {
    vec2 uv = UV;
    float W = 1.0;
    float H = 1.0;

    // Scan lines finas horizontales
    float lineH = 0.003;
    float gap = lineH * line_gap;
    float cycle = mod(uv.y, lineH + gap);
    float line = step(cycle, lineH);
    float line_brightness = line_alpha + sin(uv.y * 20.0 + TIME) * (line_alpha * 0.5);
    float lines = line * line_brightness;

    // Banda que baja lentamente
    float band_y = mod(TIME * scan_speed, 1.3) - 0.15;
    float dist = abs(uv.y - band_y);
    float band = smoothstep(0.06, 0.0, dist) * band_alpha;

    // Fresnel bordes horizontales
    float fx_left = smoothstep(fresnel_size, 0.0, uv.x) * fresnel_alpha;
    float fx_right = smoothstep(1.0 - fresnel_size, 1.0, uv.x) * fresnel_alpha;
    float fy_top = smoothstep(fresnel_size, 0.0, uv.y) * (fresnel_alpha * 0.7);
    float fy_bottom = smoothstep(1.0 - fresnel_size, 1.0, uv.y) * (fresnel_alpha * 0.7);
    float fresnel = fx_left + fx_right + fy_top + fy_bottom;

    // Glitch ocasional
    float rand_t = random(floor(TIME * 60.0));
    float glitch = step(glitch_threshold, rand_t);
    float glitch_y = random(floor(TIME * 30.0));
    float glitch_line = step(abs(uv.y - glitch_y), 0.004) * glitch * 0.3;

    // Combinar todo
    float alpha = lines + band + fresnel + glitch_line;
    alpha = clamp(alpha, 0.0, 0.9);

    COLOR = vec4(color.rgb, alpha);
}