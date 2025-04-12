shader_type spatial;

render_mode blend_mix, depth_draw_alpha_prepass, cull_back, unshaded;

uniform sampler2D main_texture : source_color;
uniform float transparency : hint_range(0.0, 1.0) = 0.5;
uniform float glow_strength : hint_range(0.0, 1.0) = 0.2;
uniform vec4 hologram_tint : source_color = vec4(0.0, 1.0, 1.0, 1.0); // cyan by default

void fragment() {
    vec4 tex_color = texture(main_texture, UV);
    
    // Optional: blend with tint to give that 'hologram' look
    vec3 hologram_color = mix(tex_color.rgb, hologram_tint.rgb, glow_strength);

    ALBEDO = hologram_color;
    ALPHA = tex_color.a * transparency;
}
