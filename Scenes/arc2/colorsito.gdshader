shader_type canvas_item;
uniform vec4 nuevo_color : source_color;

void fragment() {
    vec4 color_actual = texture(TEXTURE, UV);
    COLOR = vec4(nuevo_color.rgb, color_actual.a);
}
