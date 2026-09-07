shader_type canvas_item;

uniform vec4 cor_estrela : source_color = vec4(0.545, 1.0, 0.165, 1.0);

void fragment() {
	vec4 pixel = texture(TEXTURE, UV) * COLOR;
	if (pixel.a > 0.01) {
		float luz = max(max(pixel.r, pixel.g), pixel.b);
		pixel.rgb = cor_estrela.rgb * mix(0.72, 1.18, luz);
	}
	COLOR = pixel;
}
