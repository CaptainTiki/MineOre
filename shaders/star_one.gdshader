shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Uniforms for customization
uniform float time_scale : hint_range(0.0, 1.0) = 0.15; // Animation speed
uniform float noise_scale : hint_range(0.1, 10.0) = 3.0; // Base noise detail
uniform float detail_scale : hint_range(0.1, 5.0) = 1.5; // Small-scale detail
uniform float contrast : hint_range(0.1, 2.0) = 1.2; // Color contrast
uniform vec3 color_dark = vec3(0.8, 0.2, 0.0); // Dark red/orange
uniform vec3 color_core = vec3(1.0, 0.6, 0.1); // Bright orange
uniform vec3 color_hot = vec3(1.0, 1.0, 0.8); // Near-white hot spots
uniform float emission_strength : hint_range(0.0, 5.0) = 3.0; // Glow intensity
uniform float corona_strength : hint_range(0.0, 1.0) = 0.2; // Corona glow
uniform float swirl_strength : hint_range(0.0, 1.0) = 0.3; // Swirling motion

// Simple 2D noise function
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
        mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x),
        u.y);
}

// Fractional Brownian Motion with domain warping
float fbm(vec2 p, int octaves) {
    float v = 0.0;
    float a = 0.5;
    vec2 shift = vec2(100.0);
    for (int i = 0; i < octaves; ++i) {
        v += a * noise(p);
        p = p * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

// Warped noise for turbulence
float warped_noise(vec2 p, int octaves) {
    vec2 offset = vec2(
        fbm(p + vec2(0.0, 0.0), octaves),
        fbm(p + vec2(5.2, 1.3), octaves)
    );
    return fbm(p + offset * 2.0, octaves);
}

void fragment() {
    // Swirling UV animation
    float swirl = TIME * time_scale * swirl_strength;
    vec2 swirl_offset = vec2(cos(swirl), sin(swirl)) * 0.5;
    vec2 uv = UV + swirl_offset + TIME * time_scale;
    vec2 uv_detail = UV + TIME * time_scale * 0.7; // Secondary layer for detail
    
    // Base turbulent noise
    float n = warped_noise(uv * noise_scale, 5);
    
    // Detail noise for granules/bubbles
    float n_detail = fbm(uv_detail * noise_scale * detail_scale, 3);
    
    // Combine noises
    float noise_value = mix(n, n_detail, 0.3);
    
    // Apply contrast (sharpen bright/dark areas)
    noise_value = pow(noise_value, contrast);
    noise_value = smoothstep(0.2, 0.8, noise_value);
    
    // Color gradient
    vec3 color;
    if (noise_value < 0.4) {
        color = mix(color_dark, color_core, noise_value / 0.4);
    } else {
        color = mix(color_core, color_hot, (noise_value - 0.4) / 0.6);
    }
    
    // Emission for glowing hot spots
    vec3 emission = color * emission_strength * smoothstep(0.5, 1.0, noise_value);
    
    // Corona effect (subtle glow at edges)
    float corona = pow(1.0 - dot(NORMAL, VIEW), 3.0) * corona_strength;
    emission += vec3(1.0, 0.9, 0.7) * corona;
    
    // Output
    ALBEDO = color;
    EMISSION = emission;
}