shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D noise_texture : source_color;
uniform vec3 color_a : source_color = vec3(1.0, 0.8, 0.2); // Yellow
uniform vec3 color_b : source_color = vec3(1.0, 0.1, 0.0); // Red

uniform float noise_scale : hint_range(0.1, 10.0) = 2.0;
uniform float time_scale : hint_range(0.0, 5.0) = 0.5;
uniform float swirl_strength : hint_range(0.0, 2.0) = 0.5;
uniform float glow_intensity : hint_range(0.1, 5.0) = 1.5;
uniform float noise_contrast : hint_range(0.1, 5.0) = 1.5; // new!
uniform float mix_strength : hint_range(0.0, 2.0) = 1.0; // <<< NEW CONTROL!

void fragment() {
    vec2 uv = UV * noise_scale;
    float t = TIME * time_scale;

    // Animate UV offsets
    vec2 uv_r = uv + vec2(0.0, t * swirl_strength);
    vec2 uv_g = uv + vec2(t * swirl_strength, 0.0);
    vec2 uv_b = uv + vec2(-t * swirl_strength, 0.0);

    // Sample noise
    float r = texture(noise_texture, uv_r).r;
    float g = texture(noise_texture, uv_g).g;
    float b = texture(noise_texture, uv_b).b;

    float n = (r + g + b) / 3.0;

		// Stretch contrast before mix
	n = pow(n, noise_contrast); // >1 makes it darker, <1 makes it brighter
	n = clamp(n * mix_strength, 0.0, 1.0); // still clamp after stretching

    // Adjust noise mix strength
    n *= mix_strength;
    n = clamp(n, 0.0, 1.0); // Prevent it from going over 1

    // Blend colors
    vec3 color = mix(color_a, color_b, n);

    ALBEDO = color;
    EMISSION = color * glow_intensity;
}
