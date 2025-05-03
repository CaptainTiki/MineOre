shader_type spatial;

varying float y_pos;

void vertex() {
    y_pos = VERTEX.y;
}

uniform float progress : hint_range(0, 1) = 0.0;
uniform float min_y = -1.0;
uniform float max_y = 1.0;
uniform vec4 hologram_color : source_color = vec4(0.0, 0.5, 1.0, 0.5);
uniform float glow_intensity : hint_range(0, 5) = 1.0;
uniform float scanline_speed : hint_range(0, 10) = 2.0;
uniform float scanline_density : hint_range(0, 20) = 10.0;
uniform float flicker_frequency : hint_range(0, 10) = 1.0;
uniform sampler2D final_texture;
uniform vec4 final_color : source_color = vec4(1.0, 1.0, 1.0, 1.0); // Fallback color
uniform float blend_range = 0.1;

void fragment() {
    float y_normalized = (y_pos - min_y) / (max_y - min_y);
    float threshold = progress;
    float blend_factor = smoothstep(threshold, threshold + blend_range, y_normalized);
    
    // Final material color
    vec4 tex_color = texture(final_texture, UV);
    if (tex_color.a == 0.0) {
        tex_color = final_color; // Use fallback color if texture is missing
    } else {
        tex_color *= final_color; // Combine texture with material color
    }
    
    // Hologram effect with scanlines
    float scanline = sin(y_normalized * scanline_density + TIME * scanline_speed) * 0.5 + 0.5;
    float flicker = abs(sin(TIME * flicker_frequency + fract(TIME * 0.1))) > 0.8 ? 1.2 : 1.0;
    vec4 hologram = hologram_color * (1.0 + scanline * 0.3) * flicker * glow_intensity;
    
    // Blend hologram and final material
    ALBEDO = mix(tex_color.rgb, hologram.rgb, blend_factor);
    ALPHA = mix(tex_color.a, hologram.a, blend_factor);
    EMISSION = hologram.rgb * blend_factor * glow_intensity;
}