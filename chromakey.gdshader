shader_type canvas_item;

uniform vec4 chroma_key : source_color = vec4(0.0, 1.0, 0.0, 1.0); // Warna hijau murni
uniform float threshold : hint_range(0.0, 1.0) = 0.4;
uniform float smoothing : hint_range(0.0, 1.0) = 0.1;

void fragment() {
	vec4 col = texture(TEXTURE, UV);
	
	// Hitung seberapa mirip warna pixel dengan hijau yang mau dihapus
	float diff = distance(col.rgb, chroma_key.rgb);
	
	// Gunakan smoothstep biar tumpang-tindih warnanya gak kasar patah (anti-aliasing ringan)
	float alpha = smoothstep(threshold, threshold + smoothing, diff);
	
	// Campurkan alpha shader ke alpha asli gambarnya
	COLOR = vec4(col.rgb, col.a * alpha);
}
