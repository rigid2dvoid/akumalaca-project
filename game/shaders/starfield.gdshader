shader_type canvas_item;
render_mode blend_add, unshaded;

// Lapisan bintang/nebula aditif di belakang parallax.
// Membuat latar Akumalaca terasa hidup tanpa mengedit gambar aslinya.

uniform float intensity : hint_range(0.0, 2.0) = 0.7;
uniform vec2 tile = vec2(52.0, 30.0);

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

void fragment() {
	vec2 uv = UV;
	float t = TIME;

	// Nebula lembut yang bergerak sangat lambat.
	float n1 = noise(uv * vec2(3.0, 1.8) + vec2(t * 0.012, t * 0.004));
	float n2 = noise(uv * vec2(6.0, 3.0) - vec2(t * 0.008, 0.0));
	float neb = smoothstep(0.52, 0.92, n1 * 0.65 + n2 * 0.35);
	vec3 nebula = mix(vec3(0.10, 0.22, 0.62), vec3(0.44, 0.16, 0.58), n2) * neb * 0.16;

	// Bintang berkelip.
	vec2 gp = uv * tile;
	vec2 cell = floor(gp);
	vec2 local = fract(gp) - 0.5;
	float h = hash(cell);
	float star = step(0.978, h);
	float twinkle = 0.55 + 0.45 * sin(t * (1.3 + h * 3.0) + h * 6.2831);
	float core = smoothstep(0.14, 0.0, length(local));
	vec3 star_col = mix(vec3(0.65, 0.82, 1.0), vec3(1.0, 0.78, 0.5), hash(cell + 3.7));
	vec3 col = nebula + star_col * star * core * twinkle * 0.9;

	// Kabut debu tipis di bagian bawah.
	float haze = smoothstep(0.45, 1.0, uv.y) * (0.04 + 0.02 * sin(t * 0.4 + uv.x * 6.0));
	col += vec3(0.28, 0.36, 0.55) * haze;

	COLOR = vec4(col * intensity, 1.0);
}
