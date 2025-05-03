shader_type spatial;

varying float y_pos;

void vertex() {
    y_pos = VERTEX.y;
}

uniform float progress : hint_range(0, 1);
uniform float min_y = -1.0;
uniform float max_y = 1.0;
uniform sampler2D hologram_texture;
uniform sampler2D final_texture;
uniform float blend_range = 0.1;

void fragment() {
    float y_normalized = (y_pos - min_y) / (max_y - min_y);
    float threshold = progress;
    float blend_factor = smoothstep(threshold, threshold + blend_range, y_normalized);
    vec4 final_color = texture(final_texture, UV);
    vec4 hologram_color = texture(hologram_texture, UV);
    ALBEDO = mix(final_color.rgb, hologram_color.rgb, blend_factor);
    ALPHA = mix(1.0, hologram_color.a, blend_factor);
}