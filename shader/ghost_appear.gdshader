shader_type canvas_item;

// Main control variable: 0.0 is starting, 1.0 is fully appeared
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Wave customization parameters
uniform float wave_frequency : hint_range(1.0, 50.0) = 15.0; // Wave ripple frequency (wave density)
uniform float wave_speed : hint_range(0.0, 20.0) = 8.0;      // Wave oscillation speed over time
uniform float max_amplitude : hint_range(0.0, 0.2) = 0.08;   // Maximum wave amplitude (when progress = 0)

void fragment() {
    // 1. Calculate wave amplitude based on progress
    // When progress = 0 -> wave_strength = max_amplitude
    // When progress = 1 -> wave_strength = 0.0
    float wave_strength = max_amplitude * (1.0 - progress);

    // 2. Calculate horizontal offset (offset X) using a sine wave along the vertical axis (UV.y)
    float wave_offset = sin(UV.y * wave_frequency + TIME * wave_speed) * wave_strength;

    // 3. Create new distorted UV coordinates
    vec2 distorted_uv = vec2(UV.x + wave_offset, UV.y);

    // 4. Sample original sprite texture at distorted UV coordinates
    vec4 tex_color = texture(TEXTURE, distorted_uv);

    // 5. Calculate alpha: multiply original texture alpha by progress for fade-in
    tex_color.a *= progress;

    COLOR = tex_color;
}