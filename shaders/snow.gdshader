shader_type spatial;
// Nieve: blanco con zonas azuladas suaves y destellos que brillan al moverse.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 color_high : source_color = vec3(0.8, 0.84, 0.9);
uniform vec3 color_low : source_color = vec3(0.6, 0.68, 0.84);
uniform float scale = 0.35;
uniform float sparkle_density = 0.996;
uniform float sparkle_strength = 1.6;

varying vec3 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 p = world_pos.xz + world_pos.y;
	float h = fbm(p * scale);
	float fine = value_noise(p * 6.0);
	ALBEDO = mix(color_low, color_high, smoothstep(0.25, 0.75, h)) * (0.94 + 0.06 * fine);
	ROUGHNESS = 0.55 + 0.25 * fine;
	SPECULAR = 0.6;
	// Destellos: unos pocos puntos que se encienden según desde dónde se miren.
	vec3 cell = floor(world_pos * 45.0);
	float r = hash13(cell);
	if (r > sparkle_density) {
		vec3 dir = normalize(hash33(cell) - 0.5);
		float facing = pow(max(dot(dir, VIEW), 0.0), 24.0);
		EMISSION = vec3(0.85, 0.92, 1.0) * facing * sparkle_strength;
	}
}
