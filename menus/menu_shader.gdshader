shader_type canvas_item;

uniform float flicker_speed = 2.0;
uniform float scanline_density = 50.0;
uniform vec4 hologram_color : source_color = vec4(0.0, 0.5, 1.0, 0.3);

void fragment() {
    vec2 uv = UV;
    // Flicker effect
    float flicker = sin(TIME * flicker_speed) * 0.05 + 0.95;
    // Scanlines
    float scanline = sin(uv.y * scanline_density + TIME) * 0.1;
    // Combine
    vec4 color = hologram_color;
    color.a *= flicker + scanline;
    COLOR = color;
}