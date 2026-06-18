shader_type canvas_item;

uniform vec4 line_color: source_color = vec4(0.29, 0.62, 1.0, 0.03);
uniform float grid_size: hint_range(10.0, 100.0) = 40.0;
uniform vec2 screen_size = vec2(1152.0, 648.0);

void fragment() {
    vec2 uv = UV * screen_size;
    vec2 grid = mod(uv, grid_size);
    float line = step(grid_size - 1.0, grid.x) + step(grid_size - 1.0, grid.y);
    line = clamp(line, 0.0, 1.0);
    COLOR = vec4(line_color.rgb, line * line_color.a);
}