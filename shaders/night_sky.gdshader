shader_type canvas_item;

uniform vec4 color_top : source_color = vec4(0.298, 0.169, 0.412, 1.0);
uniform vec4 color_mid : source_color = vec4(0.651, 0.380, 0.678, 1.0);
uniform vec4 color_bottom : source_color = vec4(0.651, 0.710, 0.992, 1.0);
uniform vec4 nebula_color_a : source_color = vec4(0.988, 0.651, 0.820, 1.0); // rosa #fca6d1
uniform vec4 nebula_color_b : source_color = vec4(0.714, 0.937, 0.984, 1.0); // cian #b6effb
uniform float star_density : hint_range(0.0, 1.0) = 0.6;
uniform float nebula_strength : hint_range(0.0, 1.0) = 0.35;

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
	for (int i = 0; i < 5; i++) {
		value += amplitude * noise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV;

	vec3 color;
	if (uv.y < 0.5) {
		color = mix(color_top.rgb, color_mid.rgb, uv.y * 2.0);
	} else {
		color = mix(color_mid.rgb, color_bottom.rgb, (uv.y - 0.5) * 2.0);
	}

	// Nebulosa: dos capas de FBM con movimiento lento, colores distintos
	vec2 neb_uv1 = uv * 2.5 + vec2(TIME * 0.008, TIME * 0.004);
	float neb1 = fbm(neb_uv1);
	vec2 neb_uv2 = uv * 3.2 - vec2(TIME * 0.006, TIME * 0.01);
	float neb2 = fbm(neb_uv2 + 10.0);

	color = mix(color, nebula_color_a.rgb, smoothstep(0.45, 0.8, neb1) * nebula_strength);
	color = mix(color, nebula_color_b.rgb, smoothstep(0.5, 0.85, neb2) * nebula_strength * 0.7);

	// Estrellas de fondo: puntos suaves
	vec2 grid_size = vec2(90.0);
	vec2 grid = floor(uv * grid_size);
	vec2 cell_uv = fract(uv * grid_size);
	float star_seed = hash21(grid);

	if (star_seed > (1.0 - star_density * 0.06)) {
		vec2 star_pos = vec2(hash21(grid + 0.5), hash21(grid + 1.5));
		float dist = distance(cell_uv, star_pos);
		float twinkle = 0.5 + 0.5 * sin(TIME * 2.0 + star_seed * 30.0);
		float glow = smoothstep(0.15, 0.0, dist) * twinkle;
		color += vec3(glow);
	}

	COLOR = vec4(color, 1.0);
}