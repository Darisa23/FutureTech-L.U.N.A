shader_type canvas_item;

uniform float speed: hint_range(0.1, 2.0) = 0.4;
uniform float alpha: hint_range(0.0, 0.2) = 0.04;

void fragment() {
    float scan = mod(UV.y - TIME * speed, 1.3);
    float band = smoothstep(0.06, 0.0, abs(scan - 0.15)) * alpha;
    COLOR = vec4(0.29, 0.62, 1.0, band);
}