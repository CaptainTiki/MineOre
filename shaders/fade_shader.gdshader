shader_type spatial;
render_mode blend_mix;

uniform float opacity : hint_range(0.0, 1.0) = 1.0;

void fragment() {
    ALBEDO = vec3(1.0, 1.0, 0.0); // Yellow—match your Alpha color
    ALPHA = opacity;
}