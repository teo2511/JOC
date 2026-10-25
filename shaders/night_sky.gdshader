shader_type sky;
// Cielo nocturno: degradado, estrellas que titilan y la luna en la dirección de la luz.

#include "res://shaders/noise.gdshaderinc"

uniform vec3 top_color : source_color = vec3(0.01, 0.02, 0.08);
uniform vec3 horizon_color : source_color = vec3(0.1, 0.13, 0.28);
uniform vec3 ground_color : source_color = vec3(0.04, 0.05, 0.09);
uniform float star_density = 0.982;
uniform vec3 moon_color : source_color = vec3(1.0, 0.96, 0.85);

void sky() {
	vec3 d = EYEDIR;
	float h = d.y;
	vec3 col = mix(horizon_color, top_color, pow(clamp(h, 0.0, 1.0), 0.45));
	if (h < 0.0) {
		col = mix(horizon_color, ground_color, clamp(-h * 5.0, 0.0, 1.0));
	}
	if (AT_CUBEMAP_PASS) {
		COLOR = col; // la luz ambiente no necesita estrellas
	} else {
		vec3 p = d * 180.0;
		vec3 cell = floor(p);
		float r = hash13(cell);
		if (r > star_density && h > 0.02) {
			vec3 c = cell + 0.5 + (hash33(cell) - 0.5) * 0.5;
			float star = smoothstep(0.35, 0.0, length(p - c));
			star *= 0.55 + 0.45 * sin(TIME * (1.0 + r * 3.0) + r * 90.0);
			col += vec3(0.9, 0.93, 1.0) * star * smoothstep(0.02, 0.25, h) * (1.0 + 2.0 * fract(r * 57.0));
		}
		// Nubes muy tenues de lado a lado.
		float clouds = fbm(d.xz / max(h, 0.08) * 1.4 + TIME * 0.004);
		col = mix(col, horizon_color * 1.3, smoothstep(0.55, 0.9, clouds) * 0.35 * smoothstep(0.0, 0.3, h));
		if (LIGHT0_ENABLED) {
			float m = dot(d, LIGHT0_DIRECTION);
			float disc = smoothstep(0.99955, 0.9997, m);
			float spots = fbm(d.xy * 400.0);
			col = mix(col, moon_color * (0.85 + 0.25 * spots) * 2.5, disc);
			col += vec3(0.25, 0.3, 0.45) * pow(max(m, 0.0), 300.0) * 0.8;
			col += vec3(0.12, 0.14, 0.22) * pow(max(m, 0.0), 12.0) * 0.4;
		}
	}
	COLOR = col;
}
