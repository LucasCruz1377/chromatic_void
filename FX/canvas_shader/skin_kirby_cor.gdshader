shader_type canvas_item;

// Apenas o rosa original #FF96F8 participa da troca. A estrela amarela,
// os pés vermelhos e os olhos permanecem com as cores exatas do SVG enviado.
uniform vec4 cor_rosa : source_color = vec4(1.0, 0.5882353, 0.972549, 1.0);

void fragment() {
	vec4 pixel = texture(TEXTURE, UV) * COLOR;
	vec3 rosa_original = vec3(1.0, 0.5882353, 0.972549);
	float mascara = 1.0 - smoothstep(0.025, 0.105, distance(pixel.rgb, rosa_original));
	pixel.rgb = mix(pixel.rgb, cor_rosa.rgb, mascara * step(0.01, pixel.a));
	COLOR = pixel;
}
