shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 centro = vec2(0.5, 0.5);
uniform float escuridao : hint_range(0.0, 1.0) = 0.0;
uniform float onda_progresso : hint_range(0.0, 1.0) = 0.0;
uniform float onda_forca : hint_range(0.0, 1.5) = 0.0;
uniform float flash : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec2 uv = SCREEN_UV;
	vec2 delta_uv = uv - centro;
	vec2 delta_corrigido = delta_uv;
	delta_corrigido.x *= SCREEN_PIXEL_SIZE.y / SCREEN_PIXEL_SIZE.x;
	float distancia = length(delta_corrigido);

	// Anel fino com duas bordas: a primeira comprime a imagem e a segunda a
	// expande. O sinal alternado produz refração, em vez de apenas desenhar um
	// círculo transparente sobre a tela.
	float raio_onda = onda_progresso * 0.88;
	float borda_interna = 1.0 - smoothstep(0.004, 0.024, abs(distancia - raio_onda));
	float borda_externa = 1.0 - smoothstep(0.018, 0.052, abs(distancia - raio_onda));
	float refracao = borda_interna - borda_externa * 0.52;
	vec2 normal = normalize(delta_uv + vec2(0.0001));
	float envelope = smoothstep(0.0, 0.08, onda_progresso) * (1.0 - smoothstep(0.76, 1.0, onda_progresso));
	vec2 deslocamento = normal * refracao * 0.034 * onda_forca * envelope;
	vec4 tela = texture(screen_texture, uv - deslocamento);
	vec3 cor_final = mix(tela.rgb, tela.rgb * vec3(0.07, 0.075, 0.13), escuridao);
	vec3 cor_onda = mix(vec3(1.0, 0.34, 0.08), vec3(0.66, 0.40, 1.0), smoothstep(-0.03, 0.03, delta_corrigido.y));
	cor_final += cor_onda * borda_interna * onda_forca * envelope * 0.30;
	cor_final = mix(cor_final, vec3(1.0, 0.88, 1.0), flash);
	COLOR = vec4(cor_final, 1.0);
}
