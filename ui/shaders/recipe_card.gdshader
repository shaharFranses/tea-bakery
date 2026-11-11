// Recipe card "magic" (SPEC v1.3 §7 chapter end / Recipe Book): on an unlocked card the illustration inside the round
// medallion breathes (a slow 2.5% zoom that fades out before the medallion rim, so the frame never moves), its
// colours are lifted a little, and a glossy band of light sweeps diagonally across the whole card every few seconds.
// Coordinates are UV on the 240x320 card art; the medallion is centred at (119,126) with radius 90 (1x px).
shader_type canvas_item;

uniform float magic = 1.0;          // 0 = plain card (locked back), 1 = alive
uniform float time_s = 0.0;         // driven from GDScript (shared clock, deterministic in tests)
uniform float sweep_period = 4.2;   // seconds between shine sweeps
uniform float shine = 0.38;         // peak brightness of the sweep

const vec2 C = vec2(119.0 / 240.0, 126.0 / 320.0);
const vec2 R = vec2(90.0 / 240.0, 90.0 / 320.0);

// In fragment(), COLOR already holds texture * modulate; keep the bare vertex colour (modulate) so the art is
// sampled once (multiplying by COLOR again would square every colour and darken the card).
varying vec4 vcol;
void vertex() {
	vcol = COLOR;
}

void fragment() {
	vec2 uv = UV;
	float d = length((uv - C) / R);
	float inside = smoothstep(0.98, 0.72, d) * magic;          // 1 in the middle, 0 at the medallion rim
	float breathe = 0.5 + 0.5 * sin(time_s * 1.9);
	uv = C + (uv - C) * (1.0 - 0.025 * breathe * inside);
	vec4 col = texture(TEXTURE, uv);
	float lum = dot(col.rgb, vec3(0.299, 0.587, 0.114));
	col.rgb = mix(col.rgb, mix(vec3(lum), col.rgb, 1.15) * 1.03, inside);   // a touch more colour and warmth
	// diagonal shine sweep across the card (only where the card is opaque)
	float p = UV.x * 0.8 + UV.y * 0.6;
	float ph = fract(time_s / sweep_period) * 2.4 - 0.5;
	float band = smoothstep(0.10, 0.0, abs(p - ph)) + 0.6 * smoothstep(0.025, 0.0, abs(p - ph - 0.16));
	col.rgb += vec3(1.0, 0.96, 0.85) * band * shine * magic;
	COLOR = col * vcol;
}
