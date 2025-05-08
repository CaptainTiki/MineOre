shader_type spatial;
render_mode blend_add, unshaded;

uniform vec4 glow_color : source_color = vec4(0.2, 0.8, 1.0, 1.0);
uniform float pulse_speed = 2.0;
uniform float glow_intensity = 1.5;

void fragment() {
    float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
    vec4 color = glow_color;
    color.a *= pulse * glow_intensity;
    ALBEDO = color.rgb;
    ALPHA = color.a;
}