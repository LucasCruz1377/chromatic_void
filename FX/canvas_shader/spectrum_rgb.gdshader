shader_type canvas_item;

uniform float velocidade : hint_range(0.05, 1.0) = 0.18;
uniform float brilho : hint_range(0.5, 2.0) = 1.25;

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	float fase = TIME * velocidade + UV.y * 1.35 + UV.x * 0.35;
	vec3 rgb = 0.58 + 0.42 * cos(6.2831853 * (fase + vec3(0.0, 0.3333, 0.6666)));
	// O contorno escuro do desenho permanece nítido; somente a área cromática
	// recebe o movimento contínuo do espectro.
	float mascara_cor = smoothstep(0.10, 0.42, max(base.r, max(base.g, base.b)));
	vec3 resultado = mix(base.rgb, rgb * brilho, mascara_cor);
	COLOR = vec4(resultado * COLOR.rgb, base.a * COLOR.a);
}
