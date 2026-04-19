shader_type canvas_item;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse : hint_range(-1.0, 1.0) = 0.0; // -1 = blue, +1 = red
uniform float edge_softness : hint_range(0.1, 1.0) = 0.4;

void fragment() {
	// Hitung jarak dari tengah layar (0,0 = tengah, 1 = ujung)
	vec2 center = UV - vec2(0.5);
	float dist = length(center) * 2.0;
	
	// Vignette: semakin jauh dari tengah semakin tebal
	float vignette = smoothstep(edge_softness, 1.0, dist);
	
	// Campuran warna merah dan biru berdasarkan pulse
	vec3 red = vec3(1.0, 0.0, 0.0);
	vec3 blue = vec3(0.0, 0.2, 1.0);
	float t = (pulse + 1.0) * 0.5; // Normalize -1..1 ke 0..1
	vec3 color = mix(blue, red, t);
	
	// Output: warna di pinggir, transparan di tengah
	float alpha = vignette * intensity;
	COLOR = vec4(color, alpha);
}
