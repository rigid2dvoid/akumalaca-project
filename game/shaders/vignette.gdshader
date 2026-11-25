shader_type canvas_item;

// Vignette + scanline halus supaya layar terasa seperti monitor
// cyberpunk. Dipasang di CanvasLayer paling atas (di bawah HUD).

uniform float vignette_strength : hint_range(0.0, 1.0) = 0.55;
uniform float scanline_strength : hint_range(0.0, 0.2) = 0.035;
uniform vec4 edge_color : source_color = vec4(0.0, 0.01, 0.03, 1.0);

void fragment() {
	vec2 uv = UV;
	float d = distance(uv, vec2(0.5));
	float v = smoothstep(0.34, 0.86, d) * vignette_strength;

	// Scanline tipis, bergerak perlahan.
	float scan = sin((uv.y + TIME * 0.015) * 720.0 * 1.6) * 0.5 + 0.5;
	float alpha = v + scan * scanline_strength * (1.0 - v);

	vec3 col = mix(vec3(0.0), edge_color.rgb, 0.6);
	COLOR = vec4(col, clamp(alpha, 0.0, 1.0));
}
