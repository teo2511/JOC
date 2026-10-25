shader_type spatial;
// Tablones de madera calculados en coordenadas del mundo: sirve para suelos, paredes y vallas
// sin necesitar UV ni texturas. En superficies horizontales los tablones van a lo largo de X.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 color_a : source_color = vec3(0.45, 0.27, 0.15);
uniform vec3 color_b : source_color = vec3(0.6, 0.38, 0.2);
uniform float plank_width = 0.3;
uniform float plank_length = 2.4;
uniform float seam_width = 0.012;
uniform float grain = 0.35;
// En paredes: tablones verticales (valla) en vez de horizontales.
uniform bool vertical = false;
// Franja más oscura abajo de las paredes (zócalo), en metros. 0 = sin zócalo.
uniform float baseboard_height = 0.0;

varying vec3 world_pos;
varying vec3 world_normal;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n = abs(world_normal);
	vec2 uv;
	if (n.y > 0.5) {
		uv = world_pos.xz;
	} else if (n.x > n.z) {
		uv = world_pos.zy;
	} else {
		uv = world_pos.xy;
	}
	if (vertical && n.y <= 0.5) {
		uv = uv.yx;
	}
	float row = floor(uv.y / plank_width);
	float shift = hash12(vec2(row, 3.7)) * plank_length;
	float col = floor((uv.x + shift) / plank_length);
	vec2 local = vec2(fract((uv.x + shift) / plank_length), fract(uv.y / plank_width));
	float id = hash12(vec2(row, col));

	vec3 base = mix(color_a, color_b, id);
	// A lo lejos las juntas y la veta se suavizan, para que no hagan dibujos raros (aliasing).
	vec2 fw = fwidth(uv);
	float far_seams = clamp(max(fw.x / plank_length, fw.y / plank_width) * 8.0, 0.0, 1.0);
	float far_rings = clamp(fw.y * 40.0 * 0.5, 0.0, 1.0);
	// Veta: ruido estirado a lo largo del tablón.
	float g = fbm(vec2(uv.x * 1.5, uv.y * 28.0) + id * 31.0);
	float rings = sin((uv.y * 40.0 + fbm(uv * vec2(0.8, 6.0) + id * 7.0) * 9.0)) * 0.5 + 0.5;
	rings = mix(rings, 0.5, far_rings);
	base *= 1.0 - grain * 0.5 + grain * (0.6 * g + 0.4 * rings);

	float edge = min(min(local.y, 1.0 - local.y) * plank_width, min(local.x, 1.0 - local.x) * plank_length);
	float seam = smoothstep(0.0, seam_width, edge);
	seam = mix(seam, 0.85, far_seams);
	base *= mix(0.3, 1.0, seam);

	if (baseboard_height > 0.0 && n.y <= 0.5 && world_pos.y < baseboard_height) {
		base *= 0.55;
	}
	ALBEDO = base;
	ROUGHNESS = mix(0.95, 0.72 + 0.15 * g, seam);
	AO = mix(0.6, 1.0, seam);
	SPECULAR = 0.35;
}
