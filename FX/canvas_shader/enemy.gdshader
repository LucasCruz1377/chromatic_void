shader_type canvas_item;

// Um brilho-base discreto mantém o neon vivo. O flash continua limitado para
// impactos repetidos não voltarem a gerar clarões brancos.
uniform float brilho_base : hint_range(0.0, 0.10, 0.01) = 0.06;
uniform float brightness : hint_range(0.0, 0.20, 0.01) = 0.0;

void fragment() {
	vec4 col = COLOR;
	float flash = clamp(brightness, 0.0, 0.18);
	col.rgb = mix(col.rgb, vec3(1.0), flash);
	col.rgb *= 1.0 + brilho_base;
	COLOR = col;
}
