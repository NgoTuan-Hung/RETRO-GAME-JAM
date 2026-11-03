shader_type canvas_item;

// Dissolve progress: 0.0 is intact, 1.0 is completely disappeared
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Blow direction: 1.0 drifts right, -1.0 drifts left
uniform float direction : hint_range(-1.0, 1.0) = 1.0;

// Top-to-bottom delay spread (higher values cause top to dissolve earlier than bottom)
uniform float vertical_spread : hint_range(0.1, 0.8) = 0.8;

// Maximum shift distance along the X-axis
uniform float max_shift : hint_range(0.0, 0.3) = 0.15;

// Ghostly wave oscillation parameters during dissolve
uniform float wave_frequency : hint_range(1.0, 50.0) = 20.0;
uniform float wave_amplitude : hint_range(0.0, 0.05) = 0.02;

void fragment() {
    // 1. Calculate individual progress for each point along vertical UV.y
    float start_time = UV.y * vertical_spread;
    float duration = 1.0 - vertical_spread;
    float row_prog = clamp((progress - start_time) / duration, 0.0, 1.0);

    // 2. Calculate horizontal shift + eerie wave distortion
    float wave = sin(UV.y * wave_frequency + row_prog * 10.0) * wave_amplitude * row_prog;
    float shift_x = (row_prog * max_shift + wave) * -direction;

    // 3. Sample original texture color at distorted UV position
    vec2 distorted_uv = vec2(UV.x + shift_x, UV.y);
    vec4 tex_color = texture(TEXTURE, distorted_uv);

    // 4. Fade out each section based on row_prog
    tex_color.a *= (1.0 - row_prog);

    COLOR = tex_color;
}
