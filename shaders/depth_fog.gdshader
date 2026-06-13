shader_type canvas_item;

uniform float fire_height : hint_range(0.0, 1.0) = 0.45;
uniform float fire_width : hint_range(0.0, 0.5) = 0.2;
uniform float horizon_y : hint_range(0.0, 1.0) = 0.4;
uniform float vanish_x : hint_range(0.0, 1.0) = 0.5;
uniform float fire_intensity : hint_range(0.0, 2.0) = 1.0;
uniform float fire_speed : hint_range(0.0, 3.0) = 1.0;
uniform vec4 fire_color_core : source_color = vec4(1.0, 0.9, 0.3, 1.0);
uniform vec4 fire_color_mid : source_color = vec4(1.0, 0.4, 0.05, 1.0);
uniform vec4 fire_color_edge : source_color = vec4(0.6, 0.05, 0.0, 1.0);
uniform float vignette_strength : hint_range(0.0, 1.0) = 0.4;

float hash21(vec2 p) {
	p = fract(p * vec2(123.34, 345.45));
	p += dot(p, p + 34.345);
	return fract(p.x * p.y);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for (int i = 0; i < 4; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;
	vec4 tex = texture(TEXTURE, uv);

	// Ruido animado, fluye hacia arriba
	vec2 fire_uv = vec2(uv.x, 1.0 - uv.y) * vec2(3.0, 4.0);
	fire_uv.y += TIME * fire_speed * 1.5;
	fire_uv.x += sin(uv.y * 6.0 + TIME * 0.5) * 0.3;

	float n = fbm(fire_uv);

	// t = 0 en el horizonte, 1 en la parte más baja
	float t = clamp((uv.y - horizon_y) / (1.0 - horizon_y), 0.0, 1.0);

	// Líneas de perspectiva hacia las esquinas inferiores
	float x_left  = mix(vanish_x, 0.0, t);
	float x_right = mix(vanish_x, 1.0, t);

	float local_width = fire_width * t + 0.01;

	float edge_l = (x_left - uv.x) / local_width;
	float edge_r = (uv.x - x_right) / local_width;

	float left_mask  = clamp(edge_l * 0.5 + 0.5, 0.0, 1.0) * t;
	float right_mask = clamp(edge_r * 0.5 + 0.5, 0.0, 1.0) * t;

	float bottom_mask = smoothstep(1.0 - fire_height, 1.0, uv.y);

	float height_mask = max(bottom_mask, max(left_mask, right_mask));
	float flame = n * height_mask * fire_intensity;

	// Color del fuego según intensidad
	vec3 fire_col = mix(fire_color_edge.rgb, fire_color_mid.rgb, smoothstep(0.2, 0.5, flame));
	fire_col = mix(fire_col, fire_color_core.rgb, smoothstep(0.55, 0.85, flame));

	vec3 base = tex.rgb * 0.5;
	vec3 color = mix(base, fire_col, clamp(flame, 0.0, 1.0));

	// Chispas
	float spark_noise = noise(uv * 40.0 + TIME * vec2(0.0, 2.0));
	float sparks = step(0.97, spark_noise) * height_mask;
	color += sparks * fire_color_core.rgb * 1.5;

	// Viñeta
	float dist = distance(uv, vec2(0.5, 0.8));
	float vignette = 1.0 - smoothstep(0.4, 0.9, dist) * vignette_strength;
	color *= vignette;

	COLOR = vec4(color, tex.a);
}