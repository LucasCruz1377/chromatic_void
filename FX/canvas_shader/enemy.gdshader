shader_type canvas_item;

// O brilho-base mantém o neon vivo. "brightness" é animado rapidamente pelo
// InimigoBase para produzir um hitflash branco legível.
uniform float brilho_base : hint_range(0.0, 0.10, 0.01) = 0.06;
uniform float brightness : hint_range(0.0, 1.0, 0.01) = 0.0;

void fragment() {
	vec4 col = COLOR;
	float flash = clamp(brightness, 0.0, 1.0);
	col.rgb = mix(col.rgb, vec3(1.0), flash);
	col.rgb *= 1.0 + brilho_base;
	COLOR = col;
}
