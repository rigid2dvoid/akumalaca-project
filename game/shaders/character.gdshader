shader_type canvas_item;
render_mode unshaded;

// Digunakan oleh Jack & Monoseeds.
// Animasi gerak dilakukan lewat transform node, shader ini menangani
// flash saat kena hit, aura, dan dissolve saat mati.

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 flash_color : source_color = vec4(1.0, 0.92, 0.78, 1.0);
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;
uniform float aura : hint_range(0.0, 1.0) = 0.0;
uniform vec4 aura_color : source_color = vec4(1.0, 0.42, 0.12, 1.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	vec4 c = tex * COLOR;

	// Flash warna saat menerima damage.
	c.rgb = mix(c.rgb, flash_color.rgb, clamp(flash, 0.0, 1.0));

	// Aura hangat tipis di tepi siluet (dipakai fase 2 Monoseeds).
	if (aura > 0.001) {
		float a = tex.a;
		float edge = smoothstep(0.02, 0.55, a) * (1.0 - smoothstep(0.55, 1.0, a));
		c.rgb += aura_color.rgb * edge * aura * 0.55;
	}

	// Dissolve berbasis noise saat karakter hancur.
	if (dissolve > 0.001) {
		vec2 cell = floor(UV * vec2(90.0, 120.0));
		float n = hash(cell);
		if (n < dissolve) {
			discard;
		}
		c.rgb += aura_color.rgb * (1.0 - smoothstep(dissolve, dissolve + 0.08, n)) * 0.9;
	}

	COLOR = c;
}
