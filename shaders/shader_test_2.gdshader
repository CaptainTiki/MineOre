shader_type spatial;
render_mode unshaded; // We'll handle lighting manually for stylization

// Uniforms for customization
uniform float noise_scale : hint_range(1.0, 10.0) = 3.0; // Controls size of landmasses
uniform float noise_detail : hint_range(0.0, 5.0) = 2.0; // Adds detail to noise
uniform float glow_scale : hint_range(1.0, 20.0) = 8.0; // Size of glowing spots
uniform float glow_intensity : hint_range(0.0, 5.0) = 1.0; // Brightness of glowing spots
uniform vec3 ocean_color = vec3(0.29, 0.0, 0.51); // Purple (#4B0082)
uniform vec3 land_color = vec3(1.0, 0.65, 0.0); // Orange (#FFA500)
uniform vec3 glow_color = vec3(1.0, 0.27, 0.0); // Bright orange (#FF4500)

// Simple 2D noise function (Godot doesn't have built-in noise, so we implement our own)
float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i + vec2(0.0, 0.0)), hash(i + vec2(1.0, 0.0)), u.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p *= 2.0;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    // Use UVs for spherical mapping (CSGSphere3D UVs are already spherical)
    vec2 uv = UV * noise_scale;
    
    // Generate base noise for landmasses
    float n = fbm(uv + vec2(TIME * 0.01)); // Slight animation for a living planet
    n = fbm(uv + vec2(n)); // Add distortion for organic shapes
    float land = step(0.4, n); // Sharp cutoff for land/ocean (0.4 threshold)
    
    // Base color: mix ocean and land
    vec3 color = mix(ocean_color, land_color, land);
    
    // Generate noise for glowing spots
    float glow_noise = fbm(uv * glow_scale + vec2(TIME * 0.02));
    float glow = smoothstep(0.7, 0.9, glow_noise); // Glowing spots in brightest areas
    vec3 emission = glow_color * glow * glow_intensity;
    
    // Simulate terrain with a fake normal (poor man's normal map)
    float height_noise = fbm(uv * 10.0); // Higher frequency for terrain details
    vec3 fake_normal = normalize(vec3(dFdx(height_noise), dFdy(height_noise), 1.0));
    vec3 light_dir = normalize(vec3(1.0, 1.0, 1.0)); // Simulate sun direction
    float diffuse = max(0.0, dot(fake_normal, light_dir));
    
    // Apply lighting (stylized, not physically accurate)
    color *= (0.3 + 0.7 * diffuse); // Ambient + diffuse lighting
    
    // Output
    ALBEDO = color;
    EMISSION = emission;
    ROUGHNESS = mix(0.3, 0.8, land); // Glossy oceans, matte land
}