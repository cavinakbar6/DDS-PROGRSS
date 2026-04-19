shader_type canvas_item;
render_mode blend_add;

uniform vec4 glow_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float intensity : hint_range(0.0, 5.0) = 2.0;

void fragment() {
	// Jarak dari tengah UV (0.5, 0.5)
	float d = distance(UV, vec2(0.5, 0.5));
	
	// Bikin gradasi radial super halus dari tengah ke pinggir UV
	float alpha = smoothstep(0.5, 0.0, d);
	
	// Campurkan warna glow dan kalikan intensitasnya biar over-bright (Lens Flare feel)
	COLOR = vec4(glow_color.rgb * intensity, alpha * glow_color.a);
}
